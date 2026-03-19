from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.daily_bar import DailyBar
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.services.signal_event_service import SignalEventService
from app.services.support_state_engine import SupportStateEngine, SupportStateEvaluationResult


class SupportMonitorService:
    def __init__(self, db: Session, engine: SupportStateEngine | None = None) -> None:
        self.db = db
        self.engine = engine or SupportStateEngine()
        self.signal_event_service = SignalEventService(db)

    def evaluate_support_state(
        self,
        *,
        stock: Stock,
        support_state: SupportState,
        latest_bar: DailyBar,
        previous_major_high: Decimal | None,
    ) -> SupportStateEvaluationResult:
        price_level = support_state.price_level
        evaluation = self.engine.evaluate(support_state, price_level, latest_bar, previous_major_high)
        if evaluation.signal_type is not None:
            self.signal_event_service.create_for_state_change(
                stock=stock,
                price_level=price_level,
                support_state=support_state,
                evaluation=evaluation,
                event_time=support_state.last_evaluated_at,
            )
        self.db.flush()
        return evaluation
