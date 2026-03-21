from collections.abc import Iterable
from decimal import Decimal, ROUND_HALF_UP

from app.core.errors import AppError
from app.models.content_post import ContentPost
from app.models.daily_bar import DailyBar
from app.models.enums import ContentCategory, PriceLevelType, SignalType, SupportStatus, ThemeRoleType
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.theme import Theme
from app.repositories.stocks import StockRepository
from app.repositories.watchlists import WatchlistRepository
from app.schemas.stocks import (
    ContentListResponseData,
    ContentReference,
    DailyBarItem,
    HomeFeaturedStockItem,
    HomeMarketSummary,
    HomeResponseData,
    PriceSnapshot,
    RecentContentItem,
    ScenarioSummary,
    SignalEventItem,
    StatusBadge,
    StockChartSummary,
    StockDetailResponseData,
    StockLevelItem,
    StockSearchItem,
    StockSearchResponseData,
    StockSignalsResponseData,
    StockSummary,
    StockWatchlistSummary,
    SupportStateSummary,
    ThemeDetailResponseData,
    ThemeItem,
    ThemeReference,
    ThemeStockSummary,
    ThemesResponseData,
    WatchlistSignalSummary,
)

PCT_QUANT = Decimal("0.01")

STATUS_META = {
    SupportStatus.WAITING: ("관찰 대기", "neutral"),
    SupportStatus.TESTING_SUPPORT: ("지지선 반응 확인 중", "watch"),
    SupportStatus.DIRECT_REBOUND_SUCCESS: ("지지선 반등 성공", "positive"),
    SupportStatus.BREAK_REBOUND_SUCCESS: ("이탈 후 복원 성공", "positive"),
    SupportStatus.REUSABLE: ("재사용 가능", "neutral"),
    SupportStatus.INVALID: ("재사용 금지", "warning"),
}

SIGNAL_LABELS = {
    SignalType.SUPPORT_NEAR: "지지선 접근",
    SignalType.SUPPORT_TESTING: "지지선 반응 확인 중",
    SignalType.SUPPORT_DIRECT_REBOUND_SUCCESS: "지지선 반등 성공",
    SignalType.SUPPORT_BREAK_REBOUND_SUCCESS: "지지선 이탈 후 복원",
    SignalType.SUPPORT_REUSABLE: "지지선 재활용 가능",
    SignalType.SUPPORT_INVALIDATED: "지지선 무효화",
}

SCENARIO_TEXT = {
    SupportStatus.WAITING: (
        "핵심 지지선 도달 전 관찰 구간",
        "지지선 부근 거래량 유입 시 반등 시나리오를 확인합니다.",
        "지지선 도달 전에는 성급한 해석을 피합니다.",
    ),
    SupportStatus.TESTING_SUPPORT: (
        "지지선 방어 여부 확인 구간",
        "거래량 동반 반등 시 1차 유효성 강화",
        "종가 기준 이탈 시 보수적 접근",
    ),
    SupportStatus.DIRECT_REBOUND_SUCCESS: (
        "지지선 반등이 확인된 구간",
        "전고점 재도전 시나리오를 열어둡니다.",
        "반등 저점 재이탈 시 추세 약화를 경계합니다.",
    ),
    SupportStatus.BREAK_REBOUND_SUCCESS: (
        "이탈 후 복원으로 신뢰 회복 시도 구간",
        "복원 이후 지지선 재안착 여부가 중요합니다.",
        "복원 실패 시 변동성 확대 가능성을 경계합니다.",
    ),
    SupportStatus.REUSABLE: (
        "다시 활용 가능한 지지 구간",
        "재테스트에서 거래량과 종가 방어를 확인합니다.",
        "반복 테스트 실패 시 효력 약화를 주의합니다.",
    ),
    SupportStatus.INVALID: (
        "이전 지지선 효력이 종료된 구간",
        "새로운 지지 형성 전까지는 보수적으로 접근합니다.",
        "이전 지지선 재사용 가정은 피해야 합니다.",
    ),
}

REASON_LINES = {
    SupportStatus.WAITING: [
        "아직 핵심 지지선 도달 전입니다.",
        "지지선 근접 여부를 먼저 확인해야 합니다.",
        "섣부른 반등 판단은 보류하는 구간입니다.",
    ],
    SupportStatus.TESTING_SUPPORT: [
        "지지선 부근에 재접근한 상태입니다.",
        "현재는 반응 확인이 우선입니다.",
        "종가 기준 이탈 여부를 체크해야 합니다.",
    ],
    SupportStatus.DIRECT_REBOUND_SUCCESS: [
        "지지선 부근에서 직접 반응이 나왔습니다.",
        "반등 흐름이 유지되는지 확인이 필요합니다.",
        "직전 반등 저점을 지키는지가 핵심입니다.",
    ],
    SupportStatus.BREAK_REBOUND_SUCCESS: [
        "지지선 이탈 후 재복원 흐름이 나타났습니다.",
        "복원 이후 안착 여부가 중요합니다.",
        "재이탈 시 변동성 확대를 주의해야 합니다.",
    ],
    SupportStatus.REUSABLE: [
        "이전 지지선이 다시 활용 가능한 상태입니다.",
        "재테스트에서 거래량 반응을 확인하세요.",
        "반복 실패 시 상태 재평가가 필요합니다.",
    ],
    SupportStatus.INVALID: [
        "이전 지지선은 더 이상 유효하지 않습니다.",
        "새로운 가격대 형성 전까지는 보수적 접근이 필요합니다.",
        "기존 지지선 재사용 가정은 피해야 합니다.",
    ],
}


class StockViewService:
    def __init__(self, stock_repository: StockRepository, watchlist_repository: WatchlistRepository | None = None) -> None:
        self.stock_repository = stock_repository
        self.watchlist_repository = watchlist_repository

    def search_stocks(self, query: str) -> StockSearchResponseData:
        normalized_query = query.strip()
        if not normalized_query:
            raise AppError(
                message="검색어 q는 비어 있을 수 없습니다.",
                error_code="INVALID_QUERY",
                status_code=400,
            )
        stocks = self.stock_repository.search(normalized_query)
        return StockSearchResponseData(
            items=[
                StockSearchItem(
                    stock_code=stock.code,
                    stock_name=stock.name,
                    market_type=stock.market_type.value,
                )
                for stock in stocks
            ]
        )

    def get_stock_detail(self, stock_code: str, user_identifier: str | None = None) -> StockDetailResponseData:
        stock = self._get_stock_or_raise(stock_code)
        latest_bar = self._get_latest_bar(stock)
        primary_state = self._select_primary_support_state_or_none(stock.support_states)
        effective_status = primary_state.status if primary_state else SupportStatus.WAITING
        status = self._build_status_badge(effective_status)
        levels = self._build_levels(stock.price_levels, latest_bar.close_price)
        watchlist = self._build_watchlist_summary(stock, user_identifier)
        scenario_base, scenario_bull, scenario_bear = SCENARIO_TEXT[effective_status]

        return StockDetailResponseData(
            stock=StockSummary(stock_code=stock.code, stock_name=stock.name, market_type=stock.market_type.value),
            price=PriceSnapshot(
                current_price=latest_bar.close_price,
                change_value=latest_bar.change_value,
                change_pct=latest_bar.change_pct,
                day_high=latest_bar.high_price,
                day_low=latest_bar.low_price,
                volume=latest_bar.volume,
                updated_at=self._state_time(primary_state, latest_bar),
            ),
            status=status,
            levels=levels,
            support_state=SupportStateSummary(
                status=effective_status.value,
                reaction_type=self._reaction_type(effective_status),
                first_touched_at=(primary_state.first_touched_at or primary_state.last_evaluated_at) if primary_state else None,
                rebound_pct=self._calculate_rebound_pct(primary_state) if primary_state else None,
            ),
            scenario=ScenarioSummary(base=scenario_base, bull=scenario_bull, bear=scenario_bear),
            reason_lines=REASON_LINES[effective_status],
            chart=StockChartSummary(
                daily_bars=[
                    DailyBarItem(
                        trade_date=bar.trade_date,
                        open_price=bar.open_price,
                        high_price=bar.high_price,
                        low_price=bar.low_price,
                        close_price=bar.close_price,
                        volume=bar.volume,
                    )
                    for bar in sorted(stock.daily_bars, key=lambda item: item.trade_date, reverse=True)[:20]
                ]
            ),
            related_themes=self._build_related_themes(stock),
            related_contents=self._build_related_contents(stock.content_posts),
            watchlist=watchlist,
        )

    def get_stock_signals(self, stock_code: str, limit: int = 20) -> StockSignalsResponseData:
        stock = self._get_stock_or_raise(stock_code)
        items = self.stock_repository.list_signal_events(stock.id, limit=limit)
        return StockSignalsResponseData(
            items=[
                SignalEventItem(
                    event_id=item.id,
                    signal_type=item.signal_type.value,
                    label=SIGNAL_LABELS.get(item.signal_type, item.signal_type.value),
                    message=item.message,
                    event_time=item.event_time,
                )
                for item in items
            ]
        )

    def get_home(self, user_identifier: str | None = None) -> HomeResponseData:
        featured_stocks = self.stock_repository.list_featured_stocks(limit=5)
        theme_items = self._build_theme_items(self.stock_repository.list_themes(limit=3))
        recent_contents = self.stock_repository.list_recent_contents(limit=4)
        summary = self.stock_repository.count_watchlist_signal_summary(user_identifier)
        return HomeResponseData(
            market_summary=HomeMarketSummary(headline=self._build_market_headline(featured_stocks)),
            featured_stocks=[self._build_home_featured_stock(stock) for stock in featured_stocks],
            watchlist_signal_summary=WatchlistSignalSummary(**summary),
            themes=theme_items,
            recent_contents=[self._build_recent_content_item(item) for item in recent_contents],
        )

    def get_themes(self) -> ThemesResponseData:
        return ThemesResponseData(items=self._build_theme_items(self.stock_repository.list_themes(limit=20)))

    def get_theme_detail(self, theme_id: int) -> ThemeDetailResponseData:
        theme = self.stock_repository.get_theme(theme_id)
        if theme is None:
            raise AppError(message="테마를 찾을 수 없습니다.", error_code="THEME_NOT_FOUND", status_code=404)
        theme_item = self._build_theme_items([theme])[0]
        stocks = []
        for stock_map in sorted(theme.stock_maps, key=lambda item: (0 if item.role_type == ThemeRoleType.LEADER else 1, -(item.score or 0))):
            if stock_map.stock and stock_map.stock.is_active:
                stocks.append(ThemeStockSummary(stock_code=stock_map.stock.code, stock_name=stock_map.stock.name))
        recent_contents = [
            self._build_content_reference(item)
            for item in sorted(
                [content for content in theme.content_posts if content.is_published],
                key=lambda entry: (entry.sort_order, entry.published_at is None, entry.published_at),
            )[:10]
        ]
        return ThemeDetailResponseData(theme=theme_item, stocks=stocks, recent_contents=recent_contents)

    def get_contents(self, *, category: str | None = None, limit: int = 20) -> ContentListResponseData:
        content_category = ContentCategory(category) if category else None
        items = self.stock_repository.list_recent_contents(limit=limit, category=content_category)
        return ContentListResponseData(items=[self._build_recent_content_item(item) for item in items])

    def _get_stock_or_raise(self, stock_code: str) -> Stock:
        stock = self.stock_repository.get_by_code(stock_code)
        if not stock:
            raise AppError(message="종목을 찾을 수 없습니다.", error_code="STOCK_NOT_FOUND", status_code=404)
        return stock

    def _get_latest_bar(self, stock: Stock) -> DailyBar:
        if not stock.daily_bars:
            raise AppError(
                message="종목 가격 데이터가 아직 준비되지 않았습니다.",
                error_code="PRICE_NOT_READY",
                status_code=503,
            )
        return sorted(stock.daily_bars, key=lambda item: item.trade_date, reverse=True)[0]


    def _get_latest_bar_or_none(self, stock: Stock) -> DailyBar | None:
        if not stock.daily_bars:
            return None
        return sorted(stock.daily_bars, key=lambda item: item.trade_date, reverse=True)[0]

    def _select_primary_support_state(self, support_states: Iterable[SupportState]) -> SupportState:
        active_states = sorted(
            support_states,
            key=lambda item: (item.last_evaluated_at is None, item.last_evaluated_at),
            reverse=True,
        )
        if not active_states:
            raise AppError(
                message="지지선 상태 데이터가 아직 준비되지 않았습니다.",
                error_code="SUPPORT_STATE_NOT_READY",
                status_code=503,
            )
        return active_states[0]


    def _select_primary_support_state_or_none(self, support_states: Iterable[SupportState]) -> SupportState | None:
        active_states = sorted(
            support_states,
            key=lambda item: (item.last_evaluated_at is None, item.last_evaluated_at),
            reverse=True,
        )
        if not active_states:
            return None
        return active_states[0]

    def _build_status_badge(self, support_status: SupportStatus) -> StatusBadge:
        label, severity = STATUS_META[support_status]
        return StatusBadge(code=support_status.value, label=label, severity=severity)

    def _build_levels(self, levels: Iterable[PriceLevel], current_price: Decimal) -> list[StockLevelItem]:
        support_levels = sorted(
            [level for level in levels if level.is_active and level.level_type == PriceLevelType.SUPPORT],
            key=lambda item: item.price,
            reverse=True,
        )
        resistance_levels = sorted(
            [level for level in levels if level.is_active and level.level_type == PriceLevelType.RESISTANCE],
            key=lambda item: item.price,
        )
        ordered_levels = support_levels + resistance_levels
        items: list[StockLevelItem] = []
        for index, level in enumerate(ordered_levels, start=1):
            items.append(
                StockLevelItem(
                    level_id=level.id,
                    level_type=level.level_type.value,
                    level_order=index if level.level_type == PriceLevelType.SUPPORT else index - len(support_levels),
                    level_price=level.price,
                    distance_pct=self._calculate_distance_pct(current_price, level.price),
                )
            )
        return items

    def _build_watchlist_summary(self, stock: Stock, user_identifier: str | None) -> StockWatchlistSummary:
        if not user_identifier:
            return StockWatchlistSummary(is_in_watchlist=False, alert_enabled=False, watchlist_id=None)
        watchlist = next(
            (item for item in stock.watchlists if item.user_identifier == user_identifier and item.is_active),
            None,
        )
        if not watchlist:
            return StockWatchlistSummary(is_in_watchlist=False, alert_enabled=False, watchlist_id=None)
        return StockWatchlistSummary(
            is_in_watchlist=True,
            alert_enabled=watchlist.notification_enabled,
            watchlist_id=watchlist.id,
        )

    def _build_related_themes(self, stock: Stock) -> list[ThemeReference]:
        references = []
        for item in stock.theme_maps:
            if item.theme and item.theme.is_active:
                references.append(ThemeReference(theme_id=item.theme.id, name=item.theme.name))
        return references

    def _build_related_contents(self, content_posts: Iterable[ContentPost]) -> list[ContentReference]:
        items = [post for post in content_posts if post.is_published]
        return [self._build_content_reference(item) for item in sorted(items, key=lambda entry: (entry.sort_order, entry.published_at is None, entry.published_at), reverse=False)[:5]]

    def _build_market_headline(self, featured_stocks: list[Stock]) -> str:
        if not featured_stocks:
            return "오늘의 관찰 종목 데이터가 아직 준비되지 않았습니다."
        positive = 0
        negative = 0
        sectors: list[str] = []
        for stock in featured_stocks:
            latest_bar = self._get_latest_bar_or_none(stock)
            if latest_bar is None:
                continue
            if latest_bar.change_pct >= 0:
                positive += 1
            else:
                negative += 1
            if stock.sector and stock.sector not in sectors:
                sectors.append(stock.sector)
        mood = "반등 시도" if positive >= negative else "변동성 경계"
        sector_text = sectors[0] if sectors else "주요 종목"
        return f"{mood}, {sector_text} 중심 관찰이 필요한 장세"

    def _build_home_featured_stock(self, stock: Stock) -> HomeFeaturedStockItem:
        latest_bar = self._get_latest_bar_or_none(stock)
        primary_state = self._select_primary_support_state_or_none(stock.support_states)
        status = self._build_status_badge(primary_state.status if primary_state else SupportStatus.WAITING)
        admin_home_support_note = next((
            level.note
            for level in stock.price_levels
            if level.is_active and level.level_type == PriceLevelType.SUPPORT and level.source_label == "admin_home" and level.note
        ), None)
        summary = (
            stock.operator_memo
            or admin_home_support_note
            or (primary_state.status_reason if primary_state and primary_state.status_reason else None)
            or ('지지선 상태 자동 계산 대기 중입니다.' if primary_state is None else SCENARIO_TEXT[primary_state.status][0])
        )
        return HomeFeaturedStockItem(
            stock_code=stock.code,
            stock_name=stock.name,
            current_price=latest_bar.close_price if latest_bar else Decimal('0'),
            change_pct=latest_bar.change_pct if latest_bar else Decimal('0'),
            status=status,
            summary=summary,
        )

    def _build_theme_items(self, themes: Iterable[Theme]) -> list[ThemeItem]:
        items: list[ThemeItem] = []
        for theme in themes:
            leader = None
            followers: list[ThemeStockSummary] = []
            stock_count = 0
            for stock_map in sorted(
                theme.stock_maps,
                key=lambda item: (0 if item.role_type == ThemeRoleType.LEADER else 1, -(item.score or 0)),
            ):
                if not stock_map.stock or not stock_map.stock.is_active:
                    continue
                stock_count += 1
                stock_summary = ThemeStockSummary(stock_code=stock_map.stock.code, stock_name=stock_map.stock.name)
                if stock_map.role_type == ThemeRoleType.LEADER and leader is None:
                    leader = stock_summary
                else:
                    followers.append(stock_summary)
            items.append(
                ThemeItem(
                    theme_id=theme.id,
                    name=theme.name,
                    score=theme.score,
                    summary=theme.summary,
                    leader_stock=leader,
                    follower_stocks=followers[:5],
                    stock_count=stock_count,
                )
            )
        return items

    def _build_content_reference(self, item: ContentPost) -> ContentReference:
        return ContentReference(
            content_id=item.id,
            category=item.category.value,
            title=item.title,
            summary=item.summary,
            external_url=item.external_url,
            thumbnail_url=item.thumbnail_url,
            published_at=item.published_at,
        )

    def _build_recent_content_item(self, item: ContentPost) -> RecentContentItem:
        return RecentContentItem(
            content_id=item.id,
            category=item.category.value,
            title=item.title,
            summary=item.summary,
            external_url=item.external_url,
            thumbnail_url=item.thumbnail_url,
            published_at=item.published_at,
        )

    def _calculate_distance_pct(self, current_price: Decimal, level_price: Decimal) -> Decimal | None:
        if level_price == 0:
            return None
        distance = ((current_price - level_price) / level_price) * Decimal("100")
        return distance.copy_abs().quantize(PCT_QUANT, rounding=ROUND_HALF_UP)

    def _calculate_rebound_pct(self, support_state: SupportState) -> Decimal | None:
        if support_state.reference_price in (None, 0) or support_state.last_price is None:
            return support_state.rebound_pct
        rebound = ((support_state.last_price - support_state.reference_price) / support_state.reference_price) * Decimal("100")
        return rebound.quantize(PCT_QUANT, rounding=ROUND_HALF_UP)

    def _reaction_type(self, support_status: SupportStatus) -> str | None:
        if support_status == SupportStatus.DIRECT_REBOUND_SUCCESS:
            return "DIRECT_REBOUND"
        if support_status == SupportStatus.BREAK_REBOUND_SUCCESS:
            return "BREAK_REBOUND"
        return None

    def _state_time(self, support_state: SupportState | None, latest_bar: DailyBar):
        if support_state is None:
            return latest_bar.updated_at
        return support_state.last_evaluated_at or latest_bar.updated_at
