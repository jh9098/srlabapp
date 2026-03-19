from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.enums import SignalType, SupportStatus
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.services.support_state_engine import SupportStateEvaluationResult

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
        return event

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
