from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from fastapi import APIRouter

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.schemas.common import ApiResponse

router = APIRouter(tags=["health"])


def build_health_payload() -> dict[str, object]:
    settings = get_settings()
    database_status = "ok"
    try:
        with SessionLocal() as session:
            session.execute(text("SELECT 1"))
    except SQLAlchemyError:
        database_status = "error"

    return {
        "status": "ok" if database_status == "ok" else "degraded",
        "environment": settings.app_env,
        "version": settings.app_version,
        "database": database_status,
        "scheduler_enabled": settings.scheduler_enabled,
        "signal_batch_enabled": settings.signal_batch_enabled,
        "push_enabled": settings.push_enabled,
    }


@router.get("/health", response_model=ApiResponse[dict[str, object]])
def health_check() -> ApiResponse[dict[str, object]]:
    payload = build_health_payload()
    return ApiResponse(message="서비스 상태를 조회했습니다.", data=payload)
