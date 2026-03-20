from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
import logging

from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session, joinedload

from app.models.daily_bar import DailyBar
from app.models.enums import PriceLevelType, SignalType
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.services.signal_event_service import SignalEventService

logger = logging.getLogger(__name__)

HUNDRED = Decimal("100")
PCT_QUANT = Decimal("0.01")
DEFAULT_TOLERANCE_PCT = Decimal("1.00")


@dataclass(slots=True)
class SignalCandidate:
    stock: Stock
    price_level: PriceLevel
    latest_bar: DailyBar
    signal_type: SignalType
    event_date: date
    trigger_price: Decimal
    tolerance_pct: Decimal


@dataclass(slots=True)
class SignalBatchResult:
    scanned_stock_count: int = 0
    price_resolved_count: int = 0
    level_checked_count: int = 0
    signal_event_created_count: int = 0
    notification_created_count: int = 0
    duplicate_skip_count: int = 0
    error_count: int = 0
    dry_run_signal_count: int = 0


class SignalBatchService:
    def __init__(self, db: Session, *, default_tolerance_pct: Decimal = DEFAULT_TOLERANCE_PCT) -> None:
        self.db = db
        self.default_tolerance_pct = default_tolerance_pct
        self.signal_event_service = SignalEventService(db)

    def run(self, *, dry_run: bool = False) -> SignalBatchResult:
        result = SignalBatchResult()
        target_stocks = self._list_target_stocks()
        result.scanned_stock_count = len(target_stocks)

        for stock in target_stocks:
            try:
                latest_bar = self._latest_bar_of(stock)
                if latest_bar is None:
                    continue
                result.price_resolved_count += 1
                for level in stock.price_levels:
                    result.level_checked_count += 1
                    candidate = self._evaluate_level(stock=stock, level=level, latest_bar=latest_bar)
                    if candidate is None:
                        continue
                    if self._is_duplicate(candidate):
                        result.duplicate_skip_count += 1
                        continue
                    if dry_run:
                        result.dry_run_signal_count += 1
                        logger.info(
                            "[dry-run] stock=%s level_id=%s event=%s price=%s tolerance_pct=%s",
                            stock.code,
                            level.id,
                            candidate.signal_type.value,
                            candidate.trigger_price,
                            candidate.tolerance_pct,
                        )
                        continue
                    event = self.signal_event_service.create_price_level_event(candidate)
                    if event is None:
                        result.duplicate_skip_count += 1
                        continue
                    result.signal_event_created_count += 1
                    result.notification_created_count += self.signal_event_service.create_notifications_for_event(
                        event,
                        dispatch_push=False,
                    )
                    self.db.commit()
            except Exception as exc:  # pragma: no cover - defensive branch
                self.db.rollback()
                result.error_count += 1
                logger.exception("신호 배치 처리 실패 stock=%s error=%s", stock.code, exc)
        return result

    def _list_target_stocks(self) -> list[Stock]:
        stmt: Select[tuple[Stock]] = (
            select(Stock)
            .options(joinedload(Stock.price_levels), joinedload(Stock.daily_bars))
            .where(Stock.is_active.is_(True))
            .order_by(Stock.code.asc())
        )
        stocks = list(self.db.scalars(stmt).unique())
        return [stock for stock in stocks if any(level.is_active for level in stock.price_levels)]

    def _latest_bar_of(self, stock: Stock) -> DailyBar | None:
        active_bars = sorted(stock.daily_bars, key=lambda item: item.trade_date, reverse=True)
        return active_bars[0] if active_bars else None

    def _evaluate_level(
        self,
        *,
        stock: Stock,
        level: PriceLevel,
        latest_bar: DailyBar,
    ) -> SignalCandidate | None:
        if not level.is_active:
            return None

        signal_type = self._resolve_signal_type(level=level, latest_bar=latest_bar)
        if signal_type is None:
            return None

        return SignalCandidate(
            stock=stock,
            price_level=level,
            latest_bar=latest_bar,
            signal_type=signal_type,
            event_date=latest_bar.trade_date,
            trigger_price=Decimal(latest_bar.close_price),
            tolerance_pct=self._tolerance_pct(level),
        )

    def _resolve_signal_type(self, *, level: PriceLevel, latest_bar: DailyBar) -> SignalType | None:
        level_price = Decimal(level.price)
        current_price = Decimal(latest_bar.close_price)
        tolerance_pct = self._tolerance_pct(level)

        if level.level_type == PriceLevelType.SUPPORT:
            if self._is_within_tolerance(current_price, level_price, tolerance_pct):
                return SignalType.SUPPORT_NEAR
            if current_price < level_price:
                return SignalType.SUPPORT_INVALIDATED
            return None

        if level.level_type == PriceLevelType.RESISTANCE:
            if current_price > level_price:
                return SignalType.RESISTANCE_BREAKOUT
            if self._is_within_tolerance(current_price, level_price, tolerance_pct):
                return SignalType.RESISTANCE_NEAR
        return None

    def _tolerance_pct(self, level: PriceLevel) -> Decimal:
        if level.proximity_threshold_pct is None:
            return self.default_tolerance_pct
        return Decimal(level.proximity_threshold_pct)

    def _is_within_tolerance(
        self,
        current_price: Decimal,
        reference_price: Decimal,
        tolerance_pct: Decimal,
    ) -> bool:
        distance_pct = ((current_price - reference_price) / reference_price) * HUNDRED
        return distance_pct.copy_abs().quantize(PCT_QUANT, rounding=ROUND_HALF_UP) <= tolerance_pct

    def _is_duplicate(self, candidate: SignalCandidate) -> bool:
        signal_key = self.signal_event_service.build_price_level_signal_key(candidate)
        existing = self.db.scalar(select(SignalEvent.id).where(SignalEvent.signal_key == signal_key))
        if existing is not None:
            return True

        day_start = datetime.combine(candidate.event_date, datetime.min.time(), tzinfo=timezone.utc)
        day_end = datetime.combine(candidate.event_date, datetime.max.time(), tzinfo=timezone.utc)
        stmt = select(func.count(SignalEvent.id)).where(
            SignalEvent.stock_id == candidate.stock.id,
            SignalEvent.price_level_id == candidate.price_level.id,
            SignalEvent.signal_type == candidate.signal_type,
            SignalEvent.event_time >= day_start,
            SignalEvent.event_time <= day_end,
        )
        return bool(self.db.scalar(stmt))
