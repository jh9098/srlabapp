from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "지지저항Lab Backend API"
    app_env: str = "local"
    app_debug: bool = True
    api_v1_prefix: str = "/api/v1"
    database_url: str = "postgresql+psycopg://postgres:postgres@localhost:5432/srlab"
    admin_username: str = "admin"
    admin_password: str = "admin1234"
    admin_jwt_secret: str = "change-me-local-admin-secret"
    admin_jwt_algorithm: str = "HS256"
    admin_token_expire_minutes: int = 480
    fcm_enabled: bool = False
    fcm_service_account_json: str | None = None
    fcm_service_account_file: str | None = None
    fcm_project_id: str | None = None
    fcm_server_key: str | None = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
