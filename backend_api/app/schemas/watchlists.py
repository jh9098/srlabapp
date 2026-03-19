from decimal import Decimal

from pydantic import BaseModel

from app.schemas.stocks import StatusBadge


class PriceDistance(BaseModel):
    price: Decimal
    distance_pct: Decimal | None


class WatchlistItem(BaseModel):
    watchlist_id: int
    stock_code: str
    stock_name: str
    current_price: Decimal
    change_pct: Decimal
    status: StatusBadge
    nearest_support: PriceDistance | None
    nearest_resistance: PriceDistance | None
    summary: str
    alert_enabled: bool


class WatchlistSummaryCounts(BaseModel):
    total_count: int
    support_near_count: int
    resistance_near_count: int
    warning_count: int


class WatchlistListResponseData(BaseModel):
    items: list[WatchlistItem]
    summary: WatchlistSummaryCounts


class WatchlistCreateRequest(BaseModel):
    stock_code: str
    alert_enabled: bool = True
    watch_group: str | None = None


class WatchlistCreateResponseData(BaseModel):
    watchlist_id: int
    stock_code: str
    alert_enabled: bool


class WatchlistDeleteResponseData(BaseModel):
    deleted: bool


class WatchlistAlertUpdateRequest(BaseModel):
    alert_enabled: bool


class WatchlistAlertUpdateResponseData(BaseModel):
    watchlist_id: int
    alert_enabled: bool
