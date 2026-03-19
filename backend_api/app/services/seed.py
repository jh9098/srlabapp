from datetime import date, datetime, timezone
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.content_post import ContentPost
from app.models.daily_bar import DailyBar
from app.models.enums import ContentCategory, MarketType, PriceLevelType, SignalType, SupportStatus, ThemeRoleType
from app.models.price_level import PriceLevel
from app.models.signal_event import SignalEvent
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.theme import Theme
from app.models.theme_stock_map import ThemeStockMap
from app.models.watchlist import Watchlist



def seed_minimum_data(db: Session) -> None:
    existing_stock = db.scalar(select(Stock.id).limit(1))
    if existing_stock:
        return

    samsung = Stock(code="005930", name="삼성전자", market_type=MarketType.KOSPI, sector="반도체", theme_tags="AI반도체,메모리")
    sk = Stock(code="000660", name="SK하이닉스", market_type=MarketType.KOSPI, sector="반도체", theme_tags="HBM,AI반도체")
    hanmi = Stock(code="042700", name="한미반도체", market_type=MarketType.KOSDAQ, sector="반도체장비", theme_tags="AI반도체,장비")
    db.add_all([samsung, sk, hanmi])
    db.flush()

    samsung_support = PriceLevel(stock_id=samsung.id, level_type=PriceLevelType.SUPPORT, price=Decimal("65200"), source_label="operator")
    samsung_resistance = PriceLevel(stock_id=samsung.id, level_type=PriceLevelType.RESISTANCE, price=Decimal("68500"), source_label="operator")
    sk_support = PriceLevel(stock_id=sk.id, level_type=PriceLevelType.SUPPORT, price=Decimal("198000"), source_label="operator")
    sk_resistance = PriceLevel(stock_id=sk.id, level_type=PriceLevelType.RESISTANCE, price=Decimal("214000"), source_label="operator")
    db.add_all([samsung_support, samsung_resistance, sk_support, sk_resistance])
    db.flush()

    evaluated_at = datetime(2026, 3, 19, 10, 20, tzinfo=timezone.utc)
    samsung_state = SupportState(
        stock_id=samsung.id,
        price_level_id=samsung_support.id,
        status=SupportStatus.TESTING_SUPPORT,
        reference_price=Decimal("65200"),
        last_price=Decimal("66100"),
        last_evaluated_at=evaluated_at,
        first_touched_at=evaluated_at,
        last_touched_at=evaluated_at,
        testing_low_price=Decimal("65200"),
        testing_high_price=Decimal("66400"),
        rebound_high_price=Decimal("66400"),
        rebound_pct=Decimal("1.84"),
        status_reason="지지선 부근 재접근으로 반응 확인 중",
    )
    sk_state = SupportState(
        stock_id=sk.id,
        price_level_id=sk_support.id,
        status=SupportStatus.DIRECT_REBOUND_SUCCESS,
        reference_price=Decimal("198000"),
        last_price=Decimal("208500"),
        last_evaluated_at=evaluated_at,
        first_touched_at=evaluated_at,
        last_touched_at=evaluated_at,
        testing_low_price=Decimal("198000"),
        testing_high_price=Decimal("209000"),
        rebound_high_price=Decimal("209000"),
        rebound_pct=Decimal("5.56"),
        reaction_confirmed_at=evaluated_at,
        previous_major_high=Decimal("214000"),
        status_reason="지지선 반등 성공",
    )
    db.add_all([samsung_state, sk_state])
    db.flush()

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
            DailyBar(
                stock_id=hanmi.id,
                trade_date=date(2026, 3, 19),
                open_price=Decimal("87500"),
                high_price=Decimal("89500"),
                low_price=Decimal("87000"),
                close_price=Decimal("88900"),
                change_value=Decimal("1200"),
                change_pct=Decimal("1.37"),
                volume=2345678,
            ),
        ]
    )

    theme = Theme(name="AI 반도체", score=Decimal("87.00"), summary="메모리/장비 동반 강세")
    db.add(theme)
    db.flush()
    db.add_all(
        [
            ThemeStockMap(theme_id=theme.id, stock_id=sk.id, role_type=ThemeRoleType.LEADER, score=Decimal("95.00")),
            ThemeStockMap(theme_id=theme.id, stock_id=samsung.id, role_type=ThemeRoleType.FOLLOWER, score=Decimal("80.00")),
            ThemeStockMap(theme_id=theme.id, stock_id=hanmi.id, role_type=ThemeRoleType.FOLLOWER, score=Decimal("78.00")),
        ]
    )

    content = ContentPost(
        category=ContentCategory.STOCK_ANALYSIS,
        stock_id=samsung.id,
        theme_id=theme.id,
        title="삼성전자 지지선 관찰 포인트",
        summary="지지선 부근 재테스트 구간",
        external_url="https://example.com/post/101",
        published_at=evaluated_at,
    )
    db.add(content)
    db.flush()

    db.add(
        SignalEvent(
            stock_id=samsung.id,
            price_level_id=samsung_support.id,
            support_state_id=samsung_state.id,
            signal_type=SignalType.SUPPORT_NEAR,
            signal_key=f"support-state:{samsung_state.id}:signal:SUPPORT_NEAR:status:TESTING_SUPPORT",
            title="삼성전자 지지선 접근",
            message="삼성전자가 지지선 65200원 부근에 진입했습니다.",
            status_from=SupportStatus.WAITING.value,
            status_to=SupportStatus.TESTING_SUPPORT.value,
            trigger_price=Decimal("66100"),
            event_time=evaluated_at,
        )
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
