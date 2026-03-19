from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import AppError
from app.db.session import get_db
from app.models.enums import SupportStatus
from app.schemas.admin import (
    AdminAuditLogItem,
    AdminAuditLogsResponseData,
    AdminLoginRequest,
    AdminLoginResponseData,
    AdminPriceLevelUpsertRequest,
    AdminSessionResponseData,
    AdminStateForceUpdateRequest,
    AdminStockUpsertRequest,
    HomeFeaturedUpdateRequest,
    ManualPushRequest,
    ThemeUpsertRequest,
)
from app.schemas.common import ApiResponse
from app.services.admin_auth_service import AdminAuthService, get_admin_bearer_token
from app.services.admin_service import AdminService

router = APIRouter(prefix="/admin", tags=["admin"])


def get_admin_actor(token: str = Depends(get_admin_bearer_token)) -> str:
    return AdminAuthService().decode_token(token).sub


@router.post("/auth/login", response_model=ApiResponse[AdminLoginResponseData])
def admin_login(payload: AdminLoginRequest) -> ApiResponse[AdminLoginResponseData]:
    settings = get_settings()
    access_token = AdminAuthService().authenticate(username=payload.username, password=payload.password)
    return ApiResponse(
        message="관리자 로그인이 완료되었습니다.",
        data=AdminLoginResponseData(
            access_token=access_token,
            expires_in_seconds=settings.admin_token_expire_minutes * 60,
            admin_username=payload.username,
        ),
    )


@router.get("/auth/me", response_model=ApiResponse[AdminSessionResponseData])
def admin_session(actor_identifier: str = Depends(get_admin_actor)) -> ApiResponse[AdminSessionResponseData]:
    return ApiResponse(
        message="현재 관리자 세션입니다.",
        data=AdminSessionResponseData(admin_username=actor_identifier, role="ADMIN"),
    )


@router.get("/dashboard", response_model=ApiResponse[dict])
def get_dashboard(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    return ApiResponse(
        message="관리자 대시보드 요약입니다.",
        data={**AdminService(db).list_dashboard(), "admin_username": actor_identifier},
    )


@router.get("/stocks", response_model=ApiResponse[list[dict]])
def list_stocks(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    _ = actor_identifier
    items = AdminService(db).list_stocks()
    return ApiResponse(message="종목 목록입니다.", data=[{
        "id": item.id, "code": item.code, "name": item.name, "market_type": item.market_type.value,
        "sector": item.sector, "theme_tags": item.theme_tags, "operator_memo": item.operator_memo, "is_active": item.is_active
    } for item in items])


@router.post("/stocks", response_model=ApiResponse[dict])
@router.put("/stocks/{stock_id}", response_model=ApiResponse[dict])
def upsert_stock(
    payload: AdminStockUpsertRequest,
    stock_id: int | None = None,
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    stock = AdminService(db).upsert_stock(stock_id=stock_id, payload=payload, actor_identifier=actor_identifier)
    db.commit()
    return ApiResponse(message="종목을 저장했습니다.", data={"id": stock.id, "code": stock.code, "name": stock.name})


@router.get("/price-levels", response_model=ApiResponse[list[dict]])
def list_price_levels(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    _ = actor_identifier
    items = AdminService(db).list_price_levels()
    return ApiResponse(message="가격 레벨 목록입니다.", data=[{
        "id": item.id, "stock_id": item.stock_id, "stock_name": item.stock.name if item.stock else None,
        "level_type": item.level_type.value, "price": str(item.price), "is_active": item.is_active,
        "source_label": item.source_label, "note": item.note
    } for item in items])


@router.post("/price-levels", response_model=ApiResponse[dict])
@router.put("/price-levels/{level_id}", response_model=ApiResponse[dict])
def upsert_price_level(
    payload: AdminPriceLevelUpsertRequest,
    level_id: int | None = None,
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    level = AdminService(db).upsert_price_level(level_id=level_id, payload=payload, actor_identifier=actor_identifier)
    db.commit()
    return ApiResponse(message="가격 레벨을 저장했습니다.", data={"id": level.id})


@router.get("/support-states", response_model=ApiResponse[list[dict]])
def list_support_states(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    _ = actor_identifier
    items = AdminService(db).list_support_states()
    return ApiResponse(message="지지선 상태 목록입니다.", data=[{
        "id": item.id, "stock_name": item.stock.name if item.stock else None, "stock_code": item.stock.code if item.stock else None,
        "price_level_id": item.price_level_id, "level_price": str(item.price_level.price) if item.price_level else None,
        "status": item.status.value, "status_reason": item.status_reason, "updated_at": item.updated_at.isoformat() if item.updated_at else None
    } for item in items])


@router.patch("/support-states/{state_id}/force", response_model=ApiResponse[dict])
def force_update_support_state(
    state_id: int,
    payload: AdminStateForceUpdateRequest,
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    if payload.status not in {item.value for item in SupportStatus}:
        raise AppError(message="지원하지 않는 상태값입니다.", error_code="INVALID_STATUS", status_code=400)
    state = AdminService(db).force_update_support_state(state_id=state_id, payload=payload, actor_identifier=actor_identifier)
    db.commit()
    return ApiResponse(message="지지선 상태를 강제 수정했습니다.", data={"id": state.id, "status": state.status.value})


@router.get("/signal-events", response_model=ApiResponse[list[dict]])
def list_signal_events(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    _ = actor_identifier
    items = AdminService(db).list_signal_events()
    return ApiResponse(message="신호 이벤트 목록입니다.", data=[{
        "id": item.id, "stock_name": item.stock.name if item.stock else None, "signal_type": item.signal_type.value,
        "title": item.title, "message": item.message, "status_from": item.status_from, "status_to": item.status_to,
        "event_time": item.event_time.isoformat()
    } for item in items])


@router.get("/home-featured", response_model=ApiResponse[list[dict]])
def list_home_featured(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    _ = actor_identifier
    items = AdminService(db).list_home_featured()
    return ApiResponse(message="홈 노출 목록입니다.", data=[{
        "id": item.id, "stock_id": item.stock_id, "stock_name": item.stock.name if item.stock else None,
        "display_order": item.display_order, "is_active": item.is_active
    } for item in items])


@router.put("/home-featured", response_model=ApiResponse[list[dict]])
def replace_home_featured(
    payload: HomeFeaturedUpdateRequest,
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    items = AdminService(db).replace_home_featured(items=payload.items, actor_identifier=actor_identifier)
    db.commit()
    return ApiResponse(message="홈 노출 구성을 저장했습니다.", data=[{"id": item.id, "stock_id": item.stock_id} for item in items])


@router.get("/themes", response_model=ApiResponse[list[dict]])
def list_themes(
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[list[dict]]:
    _ = actor_identifier
    items = AdminService(db).list_themes()
    return ApiResponse(message="관리자 테마 목록입니다.", data=[{
        "id": item.id, "name": item.name, "score": str(item.score) if item.score is not None else None,
        "summary": item.summary, "is_active": item.is_active,
        "stocks": [{"stock_id": m.stock_id, "stock_name": m.stock.name if m.stock else None, "role_type": m.role_type.value} for m in item.stock_maps]
    } for item in items])


@router.post("/themes", response_model=ApiResponse[dict])
@router.put("/themes/{theme_id}", response_model=ApiResponse[dict])
def upsert_theme(
    payload: ThemeUpsertRequest,
    theme_id: int | None = None,
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    theme = AdminService(db).upsert_theme(theme_id=theme_id, payload=payload, actor_identifier=actor_identifier)
    db.commit()
    return ApiResponse(message="테마를 저장했습니다.", data={"id": theme.id, "name": theme.name})


@router.get("/audit-logs", response_model=ApiResponse[AdminAuditLogsResponseData])
def list_audit_logs(
    limit: int = Query(100, ge=1, le=200),
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[AdminAuditLogsResponseData]:
    _ = actor_identifier
    items = AdminService(db).list_audit_logs(limit=limit)
    return ApiResponse(
        message="운영 로그 목록입니다.",
        data=AdminAuditLogsResponseData(items=[AdminAuditLogItem(
            log_id=item.id,
            actor_identifier=item.actor_identifier,
            action=item.action,
            entity_type=item.entity_type,
            entity_id=item.entity_id,
            memo=item.memo,
            detail_json=item.detail_json,
            created_at=item.created_at,
        ) for item in items]),
    )


@router.post("/manual-push", response_model=ApiResponse[dict])
def send_manual_push(
    payload: ManualPushRequest,
    actor_identifier: str = Depends(get_admin_actor),
    db: Session = Depends(get_db),
) -> ApiResponse[dict]:
    AdminService(db).send_manual_push(payload=payload, actor_identifier=actor_identifier)
    db.commit()
    return ApiResponse(message="수동 푸시 요청을 저장했습니다.", data={"user_identifier": payload.user_identifier})
