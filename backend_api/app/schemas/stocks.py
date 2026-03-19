from datetime import datetime
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


class StockDetailResponseData(BaseModel):
    stock: StockSummary
    price: PriceSnapshot
    status: StatusBadge
    levels: list[StockLevelItem]
    support_state: SupportStateSummary
    scenario: ScenarioSummary
    reason_lines: list[str] = Field(min_length=3, max_length=3)
    watchlist: StockWatchlistSummary
