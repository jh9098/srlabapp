from collections.abc import Iterable
from decimal import Decimal, ROUND_HALF_UP

from app.core.errors import AppError
from app.models.daily_bar import DailyBar
from app.models.enums import PriceLevelType, SupportStatus
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.models.watchlist import Watchlist
from app.repositories.stocks import StockRepository
from app.repositories.watchlists import WatchlistRepository
from app.schemas.stocks import (
    PriceSnapshot,
    ScenarioSummary,
    StatusBadge,
    StockDetailResponseData,
    StockLevelItem,
    StockSearchItem,
    StockSearchResponseData,
    StockSummary,
    StockWatchlistSummary,
    SupportStateSummary,
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
        stock = self.stock_repository.get_by_code(stock_code)
        if not stock:
            raise AppError(message="종목을 찾을 수 없습니다.", error_code="STOCK_NOT_FOUND", status_code=404)

        latest_bar = self._get_latest_bar(stock)
        primary_state = self._select_primary_support_state(stock.support_states)
        status = self._build_status_badge(primary_state.status)
        levels = self._build_levels(stock.price_levels, latest_bar.close_price)
        watchlist = self._build_watchlist_summary(stock, user_identifier)

        scenario_base, scenario_bull, scenario_bear = SCENARIO_TEXT[primary_state.status]
        return StockDetailResponseData(
            stock=StockSummary(
                stock_code=stock.code,
                stock_name=stock.name,
                market_type=stock.market_type.value,
            ),
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
                status=primary_state.status.value,
                reaction_type=self._reaction_type(primary_state.status),
                first_touched_at=primary_state.last_evaluated_at,
                rebound_pct=self._calculate_rebound_pct(primary_state),
            ),
            scenario=ScenarioSummary(base=scenario_base, bull=scenario_bull, bear=scenario_bear),
            reason_lines=REASON_LINES[primary_state.status],
            watchlist=watchlist,
        )

    def _get_latest_bar(self, stock: Stock) -> DailyBar:
        if not stock.daily_bars:
            raise AppError(
                message="종목 가격 데이터가 아직 준비되지 않았습니다.",
                error_code="PRICE_NOT_READY",
                status_code=503,
            )
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

    def _calculate_distance_pct(self, current_price: Decimal, level_price: Decimal) -> Decimal | None:
        if level_price == 0:
            return None
        distance = ((current_price - level_price) / level_price) * Decimal("100")
        return distance.copy_abs().quantize(PCT_QUANT, rounding=ROUND_HALF_UP)

    def _calculate_rebound_pct(self, support_state: SupportState) -> Decimal | None:
        if support_state.reference_price in (None, 0) or support_state.last_price is None:
            return None
        rebound = ((support_state.last_price - support_state.reference_price) / support_state.reference_price) * Decimal("100")
        return rebound.quantize(PCT_QUANT, rounding=ROUND_HALF_UP)

    def _reaction_type(self, support_status: SupportStatus) -> str | None:
        if support_status == SupportStatus.DIRECT_REBOUND_SUCCESS:
            return "DIRECT_REBOUND"
        if support_status == SupportStatus.BREAK_REBOUND_SUCCESS:
            return "BREAK_REBOUND"
        return None

    def _state_time(self, support_state: SupportState, latest_bar: DailyBar):
        return support_state.last_evaluated_at or latest_bar.updated_at
