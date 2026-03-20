from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import SignalType, SupportStatus
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.services.notification_service import NotificationService
from app.services.support_state_engine import SupportStateEvaluationResult

if TYPE_CHECKING:
    from app.services.signal_batch_service import SignalCandidate

PRICE_LEVEL_SIGNAL_LABELS = {
    SignalType.SUPPORT_NEAR: "지지선 접근",
    SignalType.SUPPORT_INVALIDATED: "지지선 이탈",
    SignalType.RESISTANCE_NEAR: "저항선 접근",
    SignalType.RESISTANCE_BREAKOUT: "저항선 돌파",
}

SIGNAL_LABELS = {
    SignalType.SUPPORT_NEAR: "지지선 접근",
    SignalType.SUPPORT_TESTING: "지지선 반응 확인 중",
    SignalType.SUPPORT_DIRECT_REBOUND_SUCCESS: "지지선 반등 성공",
    SignalType.SUPPORT_BREAK_REBOUND_SUCCESS: "지지선 이탈 후 복원",
    SignalType.SUPPORT_REUSABLE: "지지선 재활용 가능",
    SignalType.SUPPORT_INVALIDATED: "지지선 무효화",
}


class SignalEventService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self.notification_service = NotificationService(db)

    def create_for_state_change(
        self,
        *,
        stock: Stock,
        price_level: PriceLevel,
        support_state: SupportState,
        evaluation: SupportStateEvaluationResult,
        event_time: datetime,
    ) -> SignalEvent | None:
        signal_type = evaluation.signal_type
        if signal_type is None:
            return None

        signal_key = self._build_signal_key(
            support_state_id=support_state.id,
            signal_type=signal_type,
            status_to=evaluation.current_status,
        )
        existing = self.db.scalar(select(SignalEvent).where(SignalEvent.signal_key == signal_key))
        if existing:
            return existing

        event = SignalEvent(
            stock_id=stock.id,
            price_level_id=price_level.id,
            support_state_id=support_state.id,
            signal_type=signal_type,
            signal_key=signal_key,
            title=f"{stock.name} {SIGNAL_LABELS[signal_type]}",
            message=self._build_message(signal_type, stock.name, price_level.price, support_state.last_price),
            status_from=evaluation.previous_status.value,
            status_to=evaluation.current_status.value,
            trigger_price=support_state.last_price,
            event_time=event_time,
        )
        self.db.add(event)
        self.db.flush()
        self.notification_service.create_from_signal_event(event)
        return event

    def create_price_level_event(self, candidate: SignalCandidate) -> SignalEvent | None:
        signal_key = self.build_price_level_signal_key(candidate)
        existing = self.db.scalar(select(SignalEvent).where(SignalEvent.signal_key == signal_key))
        if existing:
            return existing

        event_time = datetime.combine(candidate.event_date, datetime.min.time(), tzinfo=timezone.utc)
        event = SignalEvent(
            stock_id=candidate.stock.id,
            price_level_id=candidate.price_level.id,
            support_state_id=None,
            signal_type=candidate.signal_type,
            signal_key=signal_key,
            title=f"{candidate.stock.name} {PRICE_LEVEL_SIGNAL_LABELS[candidate.signal_type]}",
            message=self._build_price_level_message(candidate),
            status_from=None,
            status_to=None,
            trigger_price=candidate.trigger_price,
            event_time=event_time,
        )
        self.db.add(event)
        self.db.flush()
        return event

    def create_notifications_for_event(
        self,
        event: SignalEvent,
        *,
        dispatch_push: bool = True,
    ) -> int:
        notifications = self.notification_service.create_from_signal_event(
            event,
            dispatch_push=dispatch_push,
        )
        return len(notifications)

    def build_price_level_signal_key(self, candidate: SignalCandidate) -> str:
        return (
            f"price-level:{candidate.price_level.id}:signal:{candidate.signal_type.value}:"
            f"date:{candidate.event_date.isoformat()}"
        )

    def _build_signal_key(
        self,
        *,
        support_state_id: int,
        signal_type: SignalType,
        status_to: SupportStatus,
    ) -> str:
        return f"support-state:{support_state_id}:signal:{signal_type.value}:status:{status_to.value}"

    def _build_message(
        self,
        signal_type: SignalType,
        stock_name: str,
        support_price: Decimal,
        last_price: Decimal | None,
    ) -> str:
        if signal_type == SignalType.SUPPORT_NEAR:
            return f"{stock_name}이(가) 지지선 {support_price}원 부근에 진입했습니다."
        if signal_type == SignalType.SUPPORT_DIRECT_REBOUND_SUCCESS:
            return f"{stock_name}이(가) 지지선에서 직접 반등에 성공했습니다."
        if signal_type == SignalType.SUPPORT_BREAK_REBOUND_SUCCESS:
            return f"{stock_name}이(가) 지지선 이탈 후 가격대를 회복했습니다."
        if signal_type == SignalType.SUPPORT_REUSABLE:
            return f"{stock_name} 지지선이 상단 돌파로 다시 활용 가능한 상태가 되었습니다."
        if signal_type == SignalType.SUPPORT_INVALIDATED:
            return f"{stock_name} 지지선이 재하락으로 무효화되었습니다."
        return f"{stock_name} 신호가 발생했습니다. 현재가 {last_price}원"

    def _build_price_level_message(self, candidate: SignalCandidate) -> str:
        level_price = candidate.price_level.price
        trigger_price = candidate.trigger_price
        if candidate.signal_type == SignalType.SUPPORT_NEAR:
            return f"{candidate.stock.name}이(가) 지지선 {level_price}원 부근에 도달했습니다. 현재가 {trigger_price}원"
        if candidate.signal_type == SignalType.SUPPORT_INVALIDATED:
            return f"{candidate.stock.name}이(가) 지지선 {level_price}원을 이탈했습니다. 현재가 {trigger_price}원"
        if candidate.signal_type == SignalType.RESISTANCE_NEAR:
            return f"{candidate.stock.name}이(가) 저항선 {level_price}원 부근에 도달했습니다. 현재가 {trigger_price}원"
        if candidate.signal_type == SignalType.RESISTANCE_BREAKOUT:
            return f"{candidate.stock.name}이(가) 저항선 {level_price}원을 돌파했습니다. 현재가 {trigger_price}원"
        return f"{candidate.stock.name} 가격 레벨 신호가 발생했습니다. 현재가 {trigger_price}원"
