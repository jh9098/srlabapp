from datetime import date
from decimal import Decimal

from sqlalchemy import select

from app.models.alert_setting import AlertSetting
from app.models.daily_bar import DailyBar
from app.models.enums import MarketType, NotificationType, PriceLevelType, SignalType
from app.models.notification import Notification
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.watchlist import Watchlist
from app.services.signal_batch_service import SignalBatchService


def test_signal_batch_creates_events_and_pending_notifications(db_session) -> None:
    stock = Stock(code="111111", name="배치테스트", market_type=MarketType.KOSPI)
    db_session.add(stock)
    db_session.flush()

    support_level = PriceLevel(
        stock_id=stock.id,
        level_type=PriceLevelType.SUPPORT,
        price=Decimal("10000"),
        proximity_threshold_pct=Decimal("1.00"),
    )
    resistance_level = PriceLevel(
        stock_id=stock.id,
        level_type=PriceLevelType.RESISTANCE,
        price=Decimal("10500"),
        proximity_threshold_pct=Decimal("1.00"),
    )
    db_session.add_all([support_level, resistance_level])
    db_session.flush()

    bar = DailyBar(
        stock_id=stock.id,
        trade_date=date(2026, 3, 20),
        open_price=Decimal("10100"),
        high_price=Decimal("10100"),
        low_price=Decimal("9900"),
        close_price=Decimal("9950"),
        change_value=Decimal("-50"),
        change_pct=Decimal("-0.50"),
        volume=1000,
    )
    db_session.add(bar)
    db_session.add(Watchlist(user_identifier="batch-user", stock_id=stock.id, notification_enabled=True))
    db_session.add(AlertSetting(user_identifier="batch-user", push_enabled=True, price_signal_enabled=True))
    db_session.commit()

    result = SignalBatchService(db_session).run(dry_run=False)

    events = list(
        db_session.scalars(
            select(SignalEvent).where(SignalEvent.stock_id == stock.id).order_by(SignalEvent.id.asc())
        )
    )
    notifications = list(
        db_session.scalars(select(Notification).where(Notification.user_identifier == "batch-user"))
    )

    assert result.signal_event_created_count >= 1
    assert any(event.signal_type == SignalType.SUPPORT_NEAR for event in events)
    assert notifications[-1].notification_type == NotificationType.PRICE_SIGNAL


def test_signal_batch_prevents_same_day_duplicates(db_session) -> None:
    stock = Stock(code="333333", name="중복방지", market_type=MarketType.KOSPI)
    db_session.add(stock)
    db_session.flush()
    db_session.add(
        PriceLevel(
            stock_id=stock.id,
            level_type=PriceLevelType.RESISTANCE,
            price=Decimal("5000"),
            proximity_threshold_pct=Decimal("1.00"),
        )
    )
    db_session.add(
        DailyBar(
            stock_id=stock.id,
            trade_date=date(2026, 3, 20),
            open_price=Decimal("5100"),
            high_price=Decimal("5200"),
            low_price=Decimal("5050"),
            close_price=Decimal("5150"),
            change_value=Decimal("150"),
            change_pct=Decimal("3.00"),
            volume=5000,
        )
    )
    db_session.commit()

    service = SignalBatchService(db_session)
    first = service.run(dry_run=False)
    second = service.run(dry_run=False)

    created_for_stock = list(
        db_session.scalars(select(SignalEvent).where(SignalEvent.stock_id == stock.id))
    )

    assert first.signal_event_created_count >= 1
    assert len(created_for_stock) == 1
    assert second.signal_event_created_count == 0
    assert second.duplicate_skip_count >= 1


def test_signal_batch_dry_run_does_not_persist(db_session) -> None:
    stock = Stock(code="222222", name="드라이런", market_type=MarketType.KOSDAQ)
    db_session.add(stock)
    db_session.flush()
    db_session.add(
        PriceLevel(
            stock_id=stock.id,
            level_type=PriceLevelType.RESISTANCE,
            price=Decimal("20000"),
            proximity_threshold_pct=Decimal("1.00"),
        )
    )
    db_session.add(
        DailyBar(
            stock_id=stock.id,
            trade_date=date(2026, 3, 20),
            open_price=Decimal("19950"),
            high_price=Decimal("19980"),
            low_price=Decimal("19800"),
            close_price=Decimal("19990"),
            change_value=Decimal("10"),
            change_pct=Decimal("0.05"),
            volume=2000,
        )
    )
    db_session.commit()

    result = SignalBatchService(db_session).run(dry_run=True)

    event = db_session.scalar(select(SignalEvent).where(SignalEvent.stock_id == stock.id))
    assert result.dry_run_signal_count >= 1
    assert event is None
