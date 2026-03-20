from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.dependencies import get_required_user_identifier
from app.core.errors import AppError
from app.db.session import get_db
from app.schemas.common import ApiResponse
from app.schemas.notifications import (
    AlertSettingsData,
    AlertSettingsUpdateRequest,
    NotificationItem,
    NotificationReadResponseData,
    NotificationsResponseData,
)
from app.services.notification_service import NotificationService

router = APIRouter(tags=["notifications"])


@router.get("/notifications", response_model=ApiResponse[NotificationsResponseData])
def get_notifications(
    limit: int = Query(50, ge=1, le=100),
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[NotificationsResponseData]:
    service = NotificationService(db)
    items = service.list_notifications(user_identifier=user_identifier, limit=limit)
    return ApiResponse(
        message="알림함 목록입니다.",
        data=NotificationsResponseData(
            items=[
                NotificationItem(
                    notification_id=item.id,
                    notification_type=item.notification_type.value,
                    title=item.title,
                    message=item.message,
                    target_path=item.target_path,
                    delivery_status=item.delivery_status.value,
                    response_message_id=item.response_message_id,
                    failure_reason=item.failure_reason,
                    retry_count=item.retry_count,
                    is_read=item.is_read,
                    created_at=item.created_at,
                )
                for item in items
            ]
        ),
    )


@router.patch("/notifications/{notification_id}/read", response_model=ApiResponse[NotificationReadResponseData])
def mark_notification_read(
    notification_id: int,
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[NotificationReadResponseData]:
    service = NotificationService(db)
    notification = service.mark_as_read(user_identifier=user_identifier, notification_id=notification_id)
    if notification is None:
        raise AppError(message="알림을 찾을 수 없습니다.", error_code="NOTIFICATION_NOT_FOUND", status_code=404)
    db.commit()
    return ApiResponse(
        message="알림을 읽음 처리했습니다.",
        data=NotificationReadResponseData(notification_id=notification.id, is_read=notification.is_read),
    )


@router.get("/me/alert-settings", response_model=ApiResponse[AlertSettingsData])
def get_alert_settings(
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[AlertSettingsData]:
    setting = NotificationService(db).get_or_create_alert_setting(user_identifier=user_identifier)
    db.commit()
    return ApiResponse(
        message="알림 설정입니다.",
        data=AlertSettingsData(
            price_signal_enabled=setting.price_signal_enabled,
            theme_signal_enabled=setting.theme_signal_enabled,
            content_update_enabled=setting.content_update_enabled,
            admin_notice_enabled=setting.admin_notice_enabled,
            push_enabled=setting.push_enabled,
        ),
    )


@router.patch("/me/alert-settings", response_model=ApiResponse[AlertSettingsData])
def update_alert_settings(
    payload: AlertSettingsUpdateRequest,
    user_identifier: str = Depends(get_required_user_identifier),
    db: Session = Depends(get_db),
) -> ApiResponse[AlertSettingsData]:
    service = NotificationService(db)
    setting = service.get_or_create_alert_setting(user_identifier=user_identifier)
    setting.price_signal_enabled = payload.price_signal_enabled
    setting.theme_signal_enabled = payload.theme_signal_enabled
    setting.content_update_enabled = payload.content_update_enabled
    setting.admin_notice_enabled = payload.admin_notice_enabled
    setting.push_enabled = payload.push_enabled
    db.commit()
    return ApiResponse(message="알림 설정을 저장했습니다.", data=AlertSettingsData(**payload.model_dump()))
