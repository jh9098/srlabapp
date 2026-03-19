from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class AdminStockUpsertRequest(BaseModel):
    code: str
    name: str
    market_type: str
    sector: str | None = None
    theme_tags: str | None = None
    operator_memo: str | None = None
    is_active: bool = True


class AdminPriceLevelUpsertRequest(BaseModel):
    stock_id: int
    level_type: str
    price: Decimal
    proximity_threshold_pct: Decimal = Decimal("1.50")
    rebound_threshold_pct: Decimal = Decimal("5.00")
    source_label: str | None = None
    note: str | None = None
    is_active: bool = True


class AdminStateForceUpdateRequest(BaseModel):
    status: str
    memo: str = Field(min_length=1)
    status_reason: str | None = None
    invalid_reason: str | None = None


class HomeFeaturedUpdateItem(BaseModel):
    stock_id: int
    display_order: int
    is_active: bool = True


class HomeFeaturedUpdateRequest(BaseModel):
    items: list[HomeFeaturedUpdateItem]


class ThemeStockMapInput(BaseModel):
    stock_id: int
    role_type: str
    score: Decimal | None = None


class ThemeUpsertRequest(BaseModel):
    name: str
    score: Decimal | None = None
    summary: str | None = None
    is_active: bool = True
    stocks: list[ThemeStockMapInput] = Field(default_factory=list)


class ManualPushRequest(BaseModel):
    user_identifier: str
    title: str
    message: str
    target_path: str | None = None
    memo: str = Field(min_length=1)


class AdminAuditLogItem(BaseModel):
    log_id: int
    actor_identifier: str
    action: str
    entity_type: str
    entity_id: str
    memo: str | None
    detail_json: str | None
    created_at: datetime


class AdminAuditLogsResponseData(BaseModel):
    items: list[AdminAuditLogItem]
