from datetime import date, datetime, timezone
from decimal import Decimal

from app.models.daily_bar import DailyBar
from app.models.enums import MarketType, PriceLevelType, SignalType, SupportStatus
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.services.signal_event_service import SignalEventService
from app.services.support_state_engine import SupportStateEngine



def make_bar(close_price: str, low_price: str, high_price: str, day: int) -> DailyBar:
    timestamp = datetime(2026, 3, day, 15, 0, tzinfo=timezone.utc)
    return DailyBar(
        stock_id=1,
        trade_date=date(2026, 3, day),
        open_price=Decimal(close_price),
        high_price=Decimal(high_price),
        low_price=Decimal(low_price),
        close_price=Decimal(close_price),
        change_value=Decimal("0"),
        change_pct=Decimal("0"),
        volume=1000,
        updated_at=timestamp,
    )



def make_state(status: SupportStatus = SupportStatus.WAITING) -> SupportState:
    return SupportState(stock_id=1, price_level_id=1, status=status)



def make_level() -> PriceLevel:
    return PriceLevel(stock_id=1, level_type=PriceLevelType.SUPPORT, price=Decimal("10000"))



def test_direct_rebound_success_transition() -> None:
    engine = SupportStateEngine()
    state = make_state()
    level = make_level()

    first = engine.evaluate(state, level, make_bar("10050", "10050", "10100", 19), Decimal("11200"))
    second = engine.evaluate(state, level, make_bar("10550", "10100", "10600", 20), Decimal("11200"))

    assert first.current_status == SupportStatus.TESTING_SUPPORT
    assert second.current_status == SupportStatus.DIRECT_REBOUND_SUCCESS
    assert second.signal_type == SignalType.SUPPORT_DIRECT_REBOUND_SUCCESS
    assert state.breakdown_occurred is False



def test_break_rebound_success_transition() -> None:
    engine = SupportStateEngine()
    state = make_state()
    level = make_level()

    engine.evaluate(state, level, make_bar("10020", "9990", "10060", 19), Decimal("10800"))
    result = engine.evaluate(state, level, make_bar("10010", "9650", "10020", 20), Decimal("10800"))

    assert result.current_status == SupportStatus.BREAK_REBOUND_SUCCESS
    assert result.signal_type == SignalType.SUPPORT_BREAK_REBOUND_SUCCESS
    assert state.breakdown_occurred is True
    assert state.breakdown_low_price == Decimal("9650")



def test_reusable_transition_after_major_high_breakout() -> None:
    engine = SupportStateEngine()
    state = make_state(SupportStatus.DIRECT_REBOUND_SUCCESS)
    state.reference_price = Decimal("10050")
    state.testing_low_price = Decimal("10050")
    state.rebound_high_price = Decimal("10600")
    level = make_level()

    result = engine.evaluate(state, level, make_bar("11250", "10900", "11250", 21), Decimal("11200"))

    assert result.current_status == SupportStatus.REUSABLE
    assert result.signal_type == SignalType.SUPPORT_REUSABLE
    assert state.reusable_confirmed_at is not None



def test_invalid_transition_after_failed_breakout_and_selloff() -> None:
    engine = SupportStateEngine()
    state = make_state(SupportStatus.BREAK_REBOUND_SUCCESS)
    state.reference_price = Decimal("9700")
    state.testing_low_price = Decimal("9850")
    state.rebound_high_price = Decimal("10020")
    level = make_level()

    result = engine.evaluate(state, level, make_bar("9800", "9750", "10750", 21), Decimal("10800"))

    assert result.current_status == SupportStatus.INVALID
    assert result.signal_type == SignalType.SUPPORT_INVALIDATED
    assert state.invalidated_at is not None



def test_signal_event_created_once_per_state_transition(db_session) -> None:
    stock = Stock(code="123456", name="테스트", market_type=MarketType.KOSPI)
    db_session.add(stock)
    db_session.flush()
    level = PriceLevel(stock_id=stock.id, level_type=PriceLevelType.SUPPORT, price=Decimal("10000"))
    db_session.add(level)
    db_session.flush()
    state = SupportState(stock_id=stock.id, price_level_id=level.id, status=SupportStatus.WAITING)
    db_session.add(state)
    db_session.flush()

    engine = SupportStateEngine()
    event_service = SignalEventService(db_session)

    first_eval = engine.evaluate(state, level, make_bar("10050", "10050", "10100", 19), Decimal("11200"))
    event_one = event_service.create_for_state_change(
        stock=stock,
        price_level=level,
        support_state=state,
        evaluation=first_eval,
        event_time=state.last_evaluated_at,
    )
    event_two = event_service.create_for_state_change(
        stock=stock,
        price_level=level,
        support_state=state,
        evaluation=first_eval,
        event_time=state.last_evaluated_at,
    )

    assert event_one is not None
    assert event_two is not None
    assert event_one.id == event_two.id
    assert len(stock.signal_events) == 1
