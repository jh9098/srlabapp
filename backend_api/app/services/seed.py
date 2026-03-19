from datetime import date, datetime, timezone
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.daily_bar import DailyBar
from app.models.enums import MarketType, PriceLevelType, SupportStatus
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.watchlist import Watchlist


def seed_minimum_data(db: Session) -> None:
    existing_stock = db.scalar(select(Stock.id).limit(1))
    if existing_stock:
        return

    samsung = Stock(code="005930", name="삼성전자", market_type=MarketType.KOSPI, sector="반도체", theme_tags="AI반도체,메모리")
    sk = Stock(code="000660", name="SK하이닉스", market_type=MarketType.KOSPI, sector="반도체", theme_tags="HBM,AI반도체")
    db.add_all([samsung, sk])
    db.flush()

    samsung_support = PriceLevel(stock_id=samsung.id, level_type=PriceLevelType.SUPPORT, price=Decimal("65200"), source_label="operator")
    samsung_resistance = PriceLevel(stock_id=samsung.id, level_type=PriceLevelType.RESISTANCE, price=Decimal("68500"), source_label="operator")
    sk_support = PriceLevel(stock_id=sk.id, level_type=PriceLevelType.SUPPORT, price=Decimal("198000"), source_label="operator")
    sk_resistance = PriceLevel(stock_id=sk.id, level_type=PriceLevelType.RESISTANCE, price=Decimal("214000"), source_label="operator")
    db.add_all([samsung_support, samsung_resistance, sk_support, sk_resistance])
    db.flush()

    evaluated_at = datetime(2026, 3, 19, 10, 20, tzinfo=timezone.utc)
    db.add_all(
        [
            SupportState(
                stock_id=samsung.id,
                price_level_id=samsung_support.id,
                status=SupportStatus.TESTING_SUPPORT,
                reference_price=Decimal("65200"),
                last_price=Decimal("66100"),
                last_evaluated_at=evaluated_at,
                status_reason="지지선 부근 재접근으로 반응 확인 중",
            ),
            SupportState(
                stock_id=sk.id,
                price_level_id=sk_support.id,
                status=SupportStatus.DIRECT_REBOUND_SUCCESS,
                reference_price=Decimal("198000"),
                last_price=Decimal("208500"),
                last_evaluated_at=evaluated_at,
                status_reason="지지선 반등 성공",
            ),
        ]
    )

    db.add_all(
        [
            DailyBar(
                stock_id=samsung.id,
                trade_date=date(2026, 3, 19),
                open_price=Decimal("65300"),
                high_price=Decimal("66400"),
                low_price=Decimal("65300"),
                close_price=Decimal("66100"),
                change_value=Decimal("800"),
                change_pct=Decimal("1.23"),
                volume=12345678,
            ),
            DailyBar(
                stock_id=sk.id,
                trade_date=date(2026, 3, 19),
                open_price=Decimal("201000"),
                high_price=Decimal("209000"),
                low_price=Decimal("199500"),
                close_price=Decimal("208500"),
                change_value=Decimal("6500"),
                change_pct=Decimal("3.22"),
                volume=4567890,
            ),
        ]
    )

    db.add(
        Watchlist(
            user_identifier="demo-user",
            stock_id=samsung.id,
            notification_enabled=True,
            memo="seed watchlist",
        )
    )
    db.commit()
