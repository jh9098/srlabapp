from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.alert_setting import AlertSetting
from app.models.enums import NotificationDeliveryStatus, NotificationType
from app.models.notification import Notification
from app.models.signal_event import SignalEvent
from app.models.watchlist import Watchlist
from app.services.push_service import PushService


class NotificationService:
    def __init__(self, db: Session, push_service: PushService | None = None) -> None:
        self.db = db
        self.push_service = push_service or PushService(db)

    def list_notifications(self, *, user_identifier: str, limit: int = 50) -> list[Notification]:
        stmt = (
            select(Notification)
            .where(Notification.user_identifier == user_identifier)
            .order_by(Notification.created_at.desc(), Notification.id.desc())
            .limit(limit)
        )
        return list(self.db.scalars(stmt))

    def mark_as_read(self, *, user_identifier: str, notification_id: int) -> Notification | None:
        notification = self.db.scalar(
            select(Notification).where(
                Notification.id == notification_id,
                Notification.user_identifier == user_identifier,
            )
        )
        if not notification:
            return None
        notification.is_read = True
        notification.read_at = datetime.now(timezone.utc).isoformat()
        self.db.flush()
        return notification

    def get_or_create_alert_setting(self, *, user_identifier: str) -> AlertSetting:
        setting = self.db.scalar(
            select(AlertSetting).where(AlertSetting.user_identifier == user_identifier)
        )
        if setting:
            return setting
        setting = AlertSetting(user_identifier=user_identifier)
        self.db.add(setting)
        self.db.flush()
        return setting

    def create_from_signal_event(
        self,
        signal_event: SignalEvent,
        *,
        dispatch_push: bool = False,
    ) -> list[Notification]:
        if signal_event.stock_id is None:
            return []
        watchlist_stmt = select(Watchlist.user_identifier).where(
            Watchlist.stock_id == signal_event.stock_id,
            Watchlist.is_active.is_(True),
            Watchlist.notification_enabled.is_(True),
        )
        user_ids = {item for item in self.db.scalars(watchlist_stmt)}
        created: list[Notification] = []
        for user_id in user_ids:
            setting = self.get_or_create_alert_setting(user_identifier=user_id)
            if not (setting.push_enabled and setting.price_signal_enabled):
                continue
            notification = Notification(
                user_identifier=user_id,
                stock_id=signal_event.stock_id,
                signal_event_id=signal_event.id,
                notification_type=NotificationType.PRICE_SIGNAL,
                title=signal_event.title,
                message=signal_event.message,
                target_path=f"/stocks/{signal_event.stock.code}" if signal_event.stock else None,
                delivery_status=NotificationDeliveryStatus.PENDING,
            )
            self.db.add(notification)
            self.db.flush()
            if dispatch_push:
                self.push_service.dispatch_notification(notification)
            created.append(notification)
        return created

    def create_admin_notice(
        self,
        *,
        user_identifier: str,
        title: str,
        message: str,
        target_path: str | None = None,
        dispatch_push: bool = False,
    ) -> Notification:
        notification = Notification(
            user_identifier=user_identifier,
            notification_type=NotificationType.ADMIN_NOTICE,
            title=title,
            message=message,
            target_path=target_path,
            delivery_status=NotificationDeliveryStatus.PENDING,
        )
        self.db.add(notification)
        self.db.flush()
        if dispatch_push:
            self.push_service.dispatch_notification(notification)
        return notification

    def dispatch_pending(self, *, limit: int = 50, max_retry_count: int = 3) -> dict[str, int]:
        return self.push_service.dispatch_pending_notifications(
            limit=limit,
            max_retry_count=max_retry_count,
        )

    def get_pending_for_dispatch(self, *, limit: int = 50) -> list[Notification]:
        stmt = (
            select(Notification)
            .options(
                selectinload(Notification.stock),
                selectinload(Notification.signal_event),
            )
            .where(Notification.delivery_status == NotificationDeliveryStatus.PENDING)
            .order_by(Notification.created_at.asc(), Notification.id.asc())
            .limit(limit)
        )
        return list(self.db.scalars(stmt))
