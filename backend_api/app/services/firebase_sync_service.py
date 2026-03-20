from __future__ import annotations

import argparse
import logging
from dataclasses import dataclass, field
from datetime import date, datetime, timezone
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from typing import Any, Iterable

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.daily_bar import DailyBar
from app.models.enums import MarketType, PriceLevelType, SupportStatus
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState

FIREBASE_LEVEL_SOURCE = "FIREBASE_ADMIN_WATCHLIST"
PCT_QUANT = Decimal("0.01")
PRICE_QUANT = Decimal("0.01")
LOGGER = logging.getLogger(__name__)


@dataclass
class SyncCounters:
    scanned_count: int = 0
    stock_upserted_count: int = 0
    level_inserted_count: int = 0
    level_deleted_count: int = 0
    daily_bar_upserted_count: int = 0
    home_featured_upserted_count: int = 0
    skipped_count: int = 0
    error_count: int = 0
    failed_tickers: list[str] = field(default_factory=list)
    skip_reasons: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "scanned_count": self.scanned_count,
            "stock_upserted_count": self.stock_upserted_count,
            "level_inserted_count": self.level_inserted_count,
            "level_deleted_count": self.level_deleted_count,
            "daily_bar_upserted_count": self.daily_bar_upserted_count,
            "home_featured_upserted_count": self.home_featured_upserted_count,
            "skipped_count": self.skipped_count,
            "error_count": self.error_count,
            "failed_tickers": self.failed_tickers,
            "skip_reasons": self.skip_reasons,
        }


class FirebaseSyncService:
    def __init__(self, db: Session, firestore_client: Any) -> None:
        self.db = db
        self.firestore_client = firestore_client
        self.settings = get_settings()

    def sync_watchlist_stocks_and_levels(
        self,
        *,
        tickers: list[str] | None = None,
        dry_run: bool = False,
    ) -> dict[str, Any]:
        result = SyncCounters()
        ticker_filter = {ticker.strip() for ticker in (tickers or []) if ticker.strip()}
        documents = list(self.firestore_client.collection(self.settings.firebase_watchlist_collection).stream())
        for document in documents:
            payload = document.to_dict() or {}
            ticker = str(payload.get("ticker") or "").strip()
            if not ticker:
                self._skip(result, None, "adminWatchlist 문서에 ticker가 없어 건너뜁니다.")
                continue
            if ticker_filter and ticker not in ticker_filter:
                continue
            result.scanned_count += 1
            try:
                stock = self._upsert_stock(ticker=ticker, name=payload.get("name"), dry_run=dry_run)
                result.stock_upserted_count += 1
                level_count, deleted_count = self._sync_levels_for_stock(stock, payload, dry_run=dry_run)
                result.level_inserted_count += level_count
                result.level_deleted_count += deleted_count
                self._ensure_support_states(stock, dry_run=dry_run)
            except Exception as exc:  # pragma: no cover - defensive logging path
                LOGGER.exception("watchlist sync failed for %s", ticker)
                result.error_count += 1
                result.failed_tickers.append(ticker)
                result.skip_reasons.append(f"{ticker}: {exc}")
        self._finalize(dry_run)
        return result.to_dict()

    def sync_daily_bars(
        self,
        *,
        tickers: list[str] | None = None,
        replace_existing: bool = False,
        max_bars_per_stock: int | None = None,
        dry_run: bool = False,
    ) -> dict[str, Any]:
        result = SyncCounters()
        ticker_filter = {ticker.strip() for ticker in (tickers or []) if ticker.strip()}
        if ticker_filter:
            documents = [self.firestore_client.collection(self.settings.firebase_prices_collection).document(ticker).get() for ticker in sorted(ticker_filter)]
        else:
            documents = list(self.firestore_client.collection(self.settings.firebase_prices_collection).stream())

        for document in documents:
            if not getattr(document, "exists", True):
                ticker = getattr(document, "id", "unknown")
                self._skip(result, ticker, "stock_prices 문서가 없어 건너뜁니다.")
                continue
            payload = document.to_dict() or {}
            ticker = str(getattr(document, "id", payload.get("ticker") or "")).strip()
            if not ticker:
                self._skip(result, None, "stock_prices 문서 ID가 없어 건너뜁니다.")
                continue
            result.scanned_count += 1
            try:
                stock = self._ensure_stock_for_prices(ticker=ticker, name=payload.get("name"), dry_run=dry_run)
                prices = payload.get("prices") or []
                processed = self._upsert_daily_bars(
                    stock=stock,
                    ticker=ticker,
                    prices=prices,
                    replace_existing=replace_existing,
                    max_bars_per_stock=max_bars_per_stock,
                    dry_run=dry_run,
                    result=result,
                )
                result.daily_bar_upserted_count += processed
            except Exception as exc:  # pragma: no cover - defensive logging path
                LOGGER.exception("daily bars sync failed for %s", ticker)
                result.error_count += 1
                result.failed_tickers.append(ticker)
                result.skip_reasons.append(f"{ticker}: {exc}")
        self._finalize(dry_run)
        return result.to_dict()

    def sync_home_featured(
        self,
        *,
        tickers: list[str] | None = None,
        enabled: bool = True,
        limit: int | None = None,
        dry_run: bool = False,
    ) -> dict[str, Any]:
        result = SyncCounters()
        if not enabled:
            result.skip_reasons.append("home featured 동기화가 비활성화되어 있습니다.")
            return result.to_dict()

        ticker_filter = {ticker.strip() for ticker in (tickers or []) if ticker.strip()}
        documents = list(self.firestore_client.collection(self.settings.firebase_watchlist_collection).stream())
        sortable: list[tuple[datetime, str]] = []
        for document in documents:
            payload = document.to_dict() or {}
            ticker = str(payload.get("ticker") or "").strip()
            if not ticker or (ticker_filter and ticker not in ticker_filter):
                continue
            created_at = self._coerce_datetime(payload.get("createdAt")) or datetime(1970, 1, 1, tzinfo=timezone.utc)
            sortable.append((created_at, ticker))
        sortable.sort(key=lambda item: item[0], reverse=True)
        if limit is None:
            limit = self.settings.firebase_sync_home_featured_limit
        selected = sortable[:limit]
        result.scanned_count = len(selected)

        existing_entries = {
            entry.stock.code: entry
            for entry in self.db.scalars(
                select(HomeFeaturedStock)
                .join(Stock, Stock.id == HomeFeaturedStock.stock_id)
                .where(HomeFeaturedStock.is_active.is_(True))
            )
        }
        selected_tickers = {ticker for _, ticker in selected}
        for ticker, entry in existing_entries.items():
            if ticker not in selected_tickers:
                entry.is_active = False

        for order, (_, ticker) in enumerate(selected, start=1):
            stock = self.db.scalar(select(Stock).where(Stock.code == ticker))
            if stock is None:
                self._skip(result, ticker, "home featured 대상 종목이 stocks 테이블에 없어 건너뜁니다.")
                continue
            entry = existing_entries.get(ticker)
            if entry is None:
                self.db.add(HomeFeaturedStock(stock_id=stock.id, display_order=order, is_active=True))
            else:
                entry.display_order = order
                entry.is_active = True
            result.home_featured_upserted_count += 1
        self._finalize(dry_run)
        return result.to_dict()

    def run_full_sync(
        self,
        *,
        tickers: list[str] | None = None,
        sync_home_featured: bool = False,
        home_featured_limit: int | None = None,
        replace_existing_bars: bool = False,
        max_bars_per_stock: int | None = None,
        dry_run: bool = False,
    ) -> dict[str, Any]:
        return {
            "watchlist": self.sync_watchlist_stocks_and_levels(tickers=tickers, dry_run=dry_run),
            "prices": self.sync_daily_bars(
                tickers=tickers,
                replace_existing=replace_existing_bars,
                max_bars_per_stock=max_bars_per_stock,
                dry_run=dry_run,
            ),
            "home_featured": self.sync_home_featured(
                tickers=tickers,
                enabled=sync_home_featured,
                limit=home_featured_limit,
                dry_run=dry_run,
            ),
        }

    def _upsert_stock(self, *, ticker: str, name: Any, dry_run: bool) -> Stock:
        stock = self.db.scalar(select(Stock).where(Stock.code == ticker))
        normalized_name = str(name or ticker).strip()
        if stock is None:
            stock = Stock(
                code=ticker,
                name=normalized_name,
                market_type=MarketType.OTHER,
                is_active=True,
                operator_memo="firebase:adminWatchlist",
            )
            self.db.add(stock)
            self.db.flush()
            return stock
        stock.name = normalized_name or stock.name
        stock.is_active = True
        if not stock.operator_memo:
            stock.operator_memo = "firebase:adminWatchlist"
        self.db.flush()
        return stock

    def _sync_levels_for_stock(self, stock: Stock, payload: dict[str, Any], *, dry_run: bool) -> tuple[int, int]:
        deleted_count = 0
        existing_levels = list(
            self.db.scalars(
                select(PriceLevel).where(
                    PriceLevel.stock_id == stock.id,
                    PriceLevel.source_label == FIREBASE_LEVEL_SOURCE,
                    PriceLevel.is_active.is_(True),
                )
            )
        )
        for level in existing_levels:
            level.is_active = False
            deleted_count += 1

        level_inserted_count = 0
        for level_type, source_key in (
            (PriceLevelType.SUPPORT, "supportLines"),
            (PriceLevelType.RESISTANCE, "resistanceLines"),
        ):
            for price in self._dedupe_prices(payload.get(source_key) or []):
                self.db.add(
                    PriceLevel(
                        stock_id=stock.id,
                        level_type=level_type,
                        price=price,
                        source_label=FIREBASE_LEVEL_SOURCE,
                        note="imported from adminWatchlist",
                        is_active=True,
                    )
                )
                level_inserted_count += 1
        self.db.flush()
        return level_inserted_count, deleted_count

    def _ensure_support_states(self, stock: Stock, *, dry_run: bool) -> None:
        support_levels = list(
            self.db.scalars(
                select(PriceLevel).where(
                    PriceLevel.stock_id == stock.id,
                    PriceLevel.level_type == PriceLevelType.SUPPORT,
                    PriceLevel.is_active.is_(True),
                )
            )
        )
        for level in support_levels:
            state = self.db.scalar(select(SupportState).where(SupportState.price_level_id == level.id))
            if state is None:
                self.db.add(
                    SupportState(
                        stock_id=stock.id,
                        price_level_id=level.id,
                        status=SupportStatus.WAITING,
                        reference_price=level.price,
                        last_price=level.price,
                        status_reason="Firebase 동기화로 생성된 초기 지지선 상태",
                    )
                )
        self.db.flush()

    def _ensure_stock_for_prices(self, *, ticker: str, name: Any, dry_run: bool) -> Stock:
        return self._upsert_stock(ticker=ticker, name=name, dry_run=dry_run)

    def _upsert_daily_bars(
        self,
        *,
        stock: Stock,
        ticker: str,
        prices: Iterable[dict[str, Any]],
        replace_existing: bool,
        max_bars_per_stock: int | None,
        dry_run: bool,
        result: SyncCounters,
    ) -> int:
        normalized_rows: list[dict[str, Any]] = []
        for row in prices:
            normalized = self._normalize_price_row(ticker=ticker, row=row, result=result)
            if normalized is not None:
                normalized_rows.append(normalized)
        normalized_rows.sort(key=lambda item: item["trade_date"])
        if max_bars_per_stock is not None:
            normalized_rows = normalized_rows[-max_bars_per_stock:]

        existing_by_date = {
            bar.trade_date: bar
            for bar in self.db.scalars(select(DailyBar).where(DailyBar.stock_id == stock.id))
        }
        previous_close: Decimal | None = None
        processed = 0
        for normalized in normalized_rows:
            trade_date = normalized["trade_date"]
            if replace_existing and trade_date in existing_by_date:
                self.db.delete(existing_by_date[trade_date])
                self.db.flush()
                existing_by_date.pop(trade_date, None)
            change_value = Decimal("0")
            change_pct = Decimal("0")
            if previous_close not in (None, Decimal("0")):
                change_value = (normalized["close_price"] - previous_close).quantize(PRICE_QUANT, rounding=ROUND_HALF_UP)
                change_pct = ((change_value / previous_close) * Decimal("100")).quantize(PCT_QUANT, rounding=ROUND_HALF_UP)
            bar = existing_by_date.get(trade_date)
            if bar is None:
                bar = DailyBar(stock_id=stock.id, trade_date=trade_date)
                self.db.add(bar)
                existing_by_date[trade_date] = bar
            bar.open_price = normalized["open_price"]
            bar.high_price = normalized["high_price"]
            bar.low_price = normalized["low_price"]
            bar.close_price = normalized["close_price"]
            bar.volume = normalized["volume"]
            bar.change_value = change_value
            bar.change_pct = change_pct
            previous_close = normalized["close_price"]
            processed += 1
        self.db.flush()
        return processed

    def _normalize_price_row(self, *, ticker: str, row: dict[str, Any], result: SyncCounters) -> dict[str, Any] | None:
        try:
            trade_date = date.fromisoformat(str(row.get("date") or ""))
            open_price = self._to_decimal(row.get("open"))
            high_price = self._to_decimal(row.get("high"))
            low_price = self._to_decimal(row.get("low"))
            close_price = self._to_decimal(row.get("close"))
            volume = int(row.get("volume"))
        except (TypeError, ValueError, InvalidOperation):
            self._skip(result, ticker, f"잘못된 가격 row 형식이라 건너뜁니다: {row}")
            return None
        if min(open_price, high_price, low_price, close_price) < 0 or volume < 0:
            self._skip(result, ticker, f"음수 가격/거래량 row 라 건너뜁니다: {row}")
            return None
        return {
            "trade_date": trade_date,
            "open_price": open_price,
            "high_price": high_price,
            "low_price": low_price,
            "close_price": close_price,
            "volume": volume,
        }

    def _dedupe_prices(self, raw_prices: Iterable[Any]) -> list[Decimal]:
        deduped: dict[Decimal, None] = {}
        for raw in raw_prices:
            try:
                deduped[self._to_decimal(raw)] = None
            except (InvalidOperation, TypeError, ValueError):
                LOGGER.warning("잘못된 레벨 값을 건너뜁니다: %s", raw)
        return sorted(deduped.keys())

    def _to_decimal(self, value: Any) -> Decimal:
        if value is None or value == "":
            raise InvalidOperation("empty decimal")
        return Decimal(str(value)).quantize(PRICE_QUANT, rounding=ROUND_HALF_UP)

    def _coerce_datetime(self, value: Any) -> datetime | None:
        if value is None:
            return None
        if isinstance(value, datetime):
            return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
        if hasattr(value, "to_datetime"):
            converted = value.to_datetime()
            return converted if converted.tzinfo else converted.replace(tzinfo=timezone.utc)
        if isinstance(value, str):
            parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)
        return None

    def _skip(self, result: SyncCounters, ticker: str | None, reason: str) -> None:
        LOGGER.warning(reason)
        result.skipped_count += 1
        if ticker:
            result.failed_tickers.append(ticker)
        result.skip_reasons.append(reason)

    def _finalize(self, dry_run: bool) -> None:
        if dry_run:
            self.db.rollback()
        else:
            self.db.commit()


def build_cli_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Sync Firebase Firestore adminWatchlist/stock_prices into FastAPI DB")
    parser.add_argument("--mode", choices=["full", "watchlist", "prices", "home-featured"], default="full")
    parser.add_argument("--ticker", action="append", dest="tickers")
    parser.add_argument("--sync-home-featured", action="store_true")
    parser.add_argument("--home-featured-limit", type=int)
    parser.add_argument("--replace-existing-bars", action="store_true")
    parser.add_argument("--max-bars-per-stock", type=int)
    parser.add_argument("--dry-run", action="store_true")
    return parser


def format_sync_summary(summary: dict[str, Any]) -> str:
    lines: list[str] = []
    for section, payload in summary.items():
        lines.append(f"[{section}]")
        for key, value in payload.items():
            lines.append(f"- {key}: {value}")
    return "\n".join(lines)
