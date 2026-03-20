from __future__ import annotations

from functools import lru_cache

from pydantic import Field, computed_field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "지지저항Lab Backend API"
    app_env: str = "dev"
    app_debug: bool = True
    app_version: str = "0.1.0"
    api_v1_prefix: str = "/api/v1"
    log_level: str = "INFO"

    database_url: str = "sqlite:///./srlab.db"

    secret_key: str = "local-dev-secret-key"
    admin_username: str = "admin"
    admin_password: str = "change-me"
    admin_jwt_secret: str = "change-me-local-admin-secret"
    admin_jwt_algorithm: str = "HS256"
    admin_token_expire_minutes: int = 480

    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://127.0.0.1:4173",
            "http://localhost:4173",
            "http://127.0.0.1:3000",
            "http://localhost:3000",
        ]
    )
    cors_origin_regex: str | None = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

    scheduler_enabled: bool = False
    signal_batch_enabled: bool = True
    push_enabled: bool = False

    fcm_enabled: bool = False
    fcm_service_account_json: str | None = None
    fcm_service_account_file: str | None = None
    fcm_project_id: str | None = None
    fcm_server_key: str | None = None

    firebase_project_id: str | None = None
    firebase_credentials_file: str | None = None
    firebase_watchlist_collection: str = "adminWatchlist"
    firebase_prices_collection: str = "stock_prices"
    firebase_sync_home_featured_enabled: bool = False
    firebase_sync_home_featured_limit: int = 10

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


    @field_validator('cors_origins', mode='before')
    @classmethod
    def parse_cors_origins(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, list):
            return value
        if not value:
            return []
        return [item.strip() for item in str(value).split(',') if item.strip()]

    @computed_field
    @property
    def is_production(self) -> bool:
        return self.app_env.lower() == "prod"


@lru_cache
def get_settings() -> Settings:
    return Settings()
