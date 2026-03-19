from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class StockSearchItem(BaseModel):
    stock_code: str
    stock_name: str
    market_type: str


class StockSearchResponseData(BaseModel):
    items: list[StockSearchItem]


class StockSummary(BaseModel):
    stock_code: str
    stock_name: str
    market_type: str


class PriceSnapshot(BaseModel):
    current_price: Decimal
    change_value: Decimal
    change_pct: Decimal
    day_high: Decimal
    day_low: Decimal
    volume: int
    updated_at: datetime


class StatusBadge(BaseModel):
    code: str
    label: str
    severity: str


class StockLevelItem(BaseModel):
    level_id: int
    level_type: str
    level_order: int
    level_price: Decimal
    distance_pct: Decimal | None


class SupportStateSummary(BaseModel):
    status: str
    reaction_type: str | None
    first_touched_at: datetime | None
    rebound_pct: Decimal | None


class ScenarioSummary(BaseModel):
    base: str
    bull: str
    bear: str


class StockWatchlistSummary(BaseModel):
    is_in_watchlist: bool
    alert_enabled: bool
    watchlist_id: int | None = None


class ThemeReference(BaseModel):
    theme_id: int
    name: str


class ContentReference(BaseModel):
    content_id: int
    category: str
    title: str
    summary: str | None
    external_url: str | None


class DailyBarItem(BaseModel):
    trade_date: date
    open_price: Decimal
    high_price: Decimal
    low_price: Decimal
    close_price: Decimal
    volume: int


class StockChartSummary(BaseModel):
    daily_bars: list[DailyBarItem]


class StockDetailResponseData(BaseModel):
    stock: StockSummary
    price: PriceSnapshot
    status: StatusBadge
    levels: list[StockLevelItem]
    support_state: SupportStateSummary
    scenario: ScenarioSummary
    reason_lines: list[str] = Field(min_length=3, max_length=3)
    chart: StockChartSummary
    related_themes: list[ThemeReference]
    related_contents: list[ContentReference]
    watchlist: StockWatchlistSummary


class SignalEventItem(BaseModel):
    event_id: int
    signal_type: str
    label: str
    message: str
    event_time: datetime


class StockSignalsResponseData(BaseModel):
    items: list[SignalEventItem]


class HomeMarketSummary(BaseModel):
    headline: str


class HomeFeaturedStockItem(BaseModel):
    stock_code: str
    stock_name: str
    current_price: Decimal
    change_pct: Decimal
    status: StatusBadge
    summary: str


class WatchlistSignalSummary(BaseModel):
    support_near_count: int
    resistance_near_count: int
    warning_count: int


class ThemeStockSummary(BaseModel):
    stock_code: str
    stock_name: str


class ThemeItem(BaseModel):
    theme_id: int
    name: str
    score: Decimal | None
    summary: str | None
    leader_stock: ThemeStockSummary | None
    follower_stocks: list[ThemeStockSummary] = Field(default_factory=list)


class RecentContentItem(BaseModel):
    content_id: int
    category: str
    title: str
    summary: str | None
    external_url: str | None


class HomeResponseData(BaseModel):
    market_summary: HomeMarketSummary
    featured_stocks: list[HomeFeaturedStockItem]
    watchlist_signal_summary: WatchlistSignalSummary
    themes: list[ThemeItem]
    recent_contents: list[RecentContentItem]


class ThemesResponseData(BaseModel):
    items: list[ThemeItem]
