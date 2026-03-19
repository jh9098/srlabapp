from datetime import datetime

from pydantic import BaseModel


class NotificationItem(BaseModel):
    notification_id: int
    notification_type: str
    title: str
    message: str
    target_path: str | None
    is_read: bool
    created_at: datetime


class NotificationsResponseData(BaseModel):
    items: list[NotificationItem]


class AlertSettingsData(BaseModel):
    price_signal_enabled: bool
    theme_signal_enabled: bool
    content_update_enabled: bool
    admin_notice_enabled: bool
    push_enabled: bool


class AlertSettingsUpdateRequest(BaseModel):
    price_signal_enabled: bool
    theme_signal_enabled: bool
    content_update_enabled: bool
    admin_notice_enabled: bool
    push_enabled: bool


class NotificationReadResponseData(BaseModel):
    notification_id: int
    is_read: bool
