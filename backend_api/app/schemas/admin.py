from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator


class AdminLoginRequest(BaseModel):
    username: str
    password: str


class AdminLoginResponseData(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_seconds: int
    admin_username: str


class AdminSessionResponseData(BaseModel):
    admin_username: str
    role: str


class AdminStockUpsertRequest(BaseModel):
    code: str = Field(min_length=1)
    name: str = Field(min_length=1)
    market_type: str
    sector: str | None = None
    theme_tags: str | None = None
    operator_memo: str | None = None
    is_active: bool = True

    @field_validator('code', 'name')
    @classmethod
    def strip_required_text(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError('필수값은 비어 있을 수 없습니다.')
        return normalized


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
    display_order: int = 0
    is_active: bool = True
    summary: str | None = None


class HomeFeaturedUpdateRequest(BaseModel):
    items: list[HomeFeaturedUpdateItem]


class ThemeStockMapInput(BaseModel):
    stock_id: int
    role_type: str
    score: Decimal | None = None


class ThemeUpsertRequest(BaseModel):
    name: str = Field(min_length=1)
    score: Decimal | None = None
    summary: str | None = None
    is_active: bool = True
    stocks: list[ThemeStockMapInput] = Field(default_factory=list)

    @field_validator('name')
    @classmethod
    def strip_name(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError('테마명은 비어 있을 수 없습니다.')
        return normalized


class AdminContentUpsertRequest(BaseModel):
    category: str
    title: str = Field(min_length=1)
    summary: str | None = None
    external_url: str | None = None
    thumbnail_url: str | None = None
    stock_id: int | None = None
    theme_id: int | None = None
    published_at: datetime | None = None
    sort_order: int = 0
    is_published: bool = True

    @field_validator('title')
    @classmethod
    def strip_title(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError('제목은 비어 있을 수 없습니다.')
        return normalized


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
