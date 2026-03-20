from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from urllib import request
from urllib.error import HTTPError, URLError

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.device_token import DeviceToken
from app.models.enums import NotificationDeliveryStatus
from app.models.notification import Notification

logger = logging.getLogger(__name__)

INVALID_TOKEN_MARKERS = (
    "UNREGISTERED",
    "registration-token-not-registered",
    "invalid-registration-token",
    "SENDER_ID_MISMATCH",
    "Requested entity was not found",
)

TRANSIENT_ERROR_MARKERS = (
    "UNAVAILABLE",
    "INTERNAL",
    "QUOTA_EXCEEDED",
    "RESOURCE_EXHAUSTED",
    "timeout",
)


@dataclass
class PushPayload:
    title: str
    message: str
    target_path: str | None
    notification_id: int
    stock_code: str | None = None
    signal_event_id: int | None = None
    event_type: str | None = None
    notification_type: str | None = None


@dataclass
class PushSendResult:
    success: bool
    response_message_id: str | None = None
    failure_reason: str | None = None
    should_deactivate_token: bool = False
    should_retry: bool = False


class PushProvider:
    def send(self, *, token: str, payload: PushPayload) -> PushSendResult:  # pragma: no cover - interface
        raise NotImplementedError


class FcmPushProvider(PushProvider):
    def __init__(self) -> None:
        self.settings = get_settings()
        if not self.settings.fcm_server_key:
            raise RuntimeError("FCM_SERVER_KEY가 설정되지 않았습니다.")

    def send(self, *, token: str, payload: PushPayload) -> PushSendResult:
        body = json.dumps(
            {
                "to": token,
                "notification": {
                    "title": payload.title,
                    "body": payload.message,
                },
                "data": _build_data_payload(payload),
            }
        ).encode("utf-8")
        http_request = request.Request(
            url="https://fcm.googleapis.com/fcm/send",
            data=body,
            headers={
                "Content-Type": "application/json",
                "Authorization": f"key={self.settings.fcm_server_key}",
            },
            method="POST",
        )
        try:
            with request.urlopen(http_request, timeout=10) as response:  # noqa: S310
                payload_json = json.loads(response.read().decode("utf-8") or "{}")
                results = payload_json.get("results") or []
                if results and results[0].get("error"):
                    error = str(results[0]["error"])
                    return _build_failure_result(error)
                message_id = None
                if results:
                    message_id = results[0].get("message_id")
                return PushSendResult(success=True, response_message_id=str(message_id) if message_id else None)
        except HTTPError as exc:  # pragma: no cover - network dependent
            reason = _read_http_error(exc)
            return _build_failure_result(reason)
        except URLError as exc:  # pragma: no cover - network dependent
            return PushSendResult(success=False, failure_reason=f"FCM 네트워크 오류: {exc.reason}", should_retry=True)


class LoggingFallbackPushProvider(PushProvider):
    def send(self, *, token: str, payload: PushPayload) -> PushSendResult:
        logger.info(
            "FCM 설정이 없어 DB 저장만 수행했습니다. token=%s notification_id=%s target_path=%s",
            token,
            payload.notification_id,
            payload.target_path,
        )
        return PushSendResult(success=True, response_message_id="log-only")


class PushService:
    def __init__(self, db: Session, provider: PushProvider | None = None) -> None:
        self.db = db
        self.provider = provider or self._resolve_provider()

    def _resolve_provider(self) -> PushProvider:
        settings = get_settings()
        if settings.fcm_enabled:
            try:
                return FcmPushProvider()
            except Exception as exc:  # pragma: no cover - environment dependent
                logger.warning("FCM provider 초기화에 실패하여 fallback으로 전환합니다: %s", exc)
        return LoggingFallbackPushProvider()

    def build_payload(self, notification: Notification) -> PushPayload:
        stock_code = notification.stock.code if notification.stock else None
        event_type = notification.signal_event.signal_type.value if notification.signal_event else None
        return PushPayload(
            title=notification.title,
            message=notification.message,
            target_path=notification.target_path,
            notification_id=notification.id,
            stock_code=stock_code,
            signal_event_id=notification.signal_event_id,
            event_type=event_type,
            notification_type=notification.notification_type.value,
        )

    def dispatch_notification(self, notification: Notification, *, max_retry_count: int = 3) -> NotificationDeliveryStatus:
        active_tokens = list(
            self.db.scalars(
                select(DeviceToken).where(
                    DeviceToken.user_identifier == notification.user_identifier,
                    DeviceToken.is_active.is_(True),
                )
            )
        )
        now = datetime.now(timezone.utc)
        notification.last_attempt_at = now
        notification.retry_count += 1

        if not active_tokens:
            notification.delivery_status = NotificationDeliveryStatus.NO_TOKEN
            notification.failure_reason = "활성화된 디바이스 토큰이 없습니다."
            self.db.flush()
            return notification.delivery_status

        notification.delivery_status = NotificationDeliveryStatus.SENDING
        self.db.flush()
        payload = self.build_payload(notification)

        sent_count = 0
        last_failure_reason: str | None = None
        should_retry = False
        for token in active_tokens:
            result = self.provider.send(token=token.device_token, payload=payload)
            if result.success:
                token.last_error = None
                token.last_seen_at = now
                sent_count += 1
                if not notification.response_message_id and result.response_message_id:
                    notification.response_message_id = result.response_message_id
                continue

            token.last_error = result.failure_reason
            token.last_seen_at = now
            last_failure_reason = result.failure_reason
            should_retry = should_retry or result.should_retry
            if result.should_deactivate_token:
                token.is_active = False
                logger.info("유효하지 않은 FCM 토큰을 비활성화했습니다. token_id=%s", token.id)

        if sent_count > 0:
            notification.delivery_status = NotificationDeliveryStatus.SENT
            notification.sent_at = now
            notification.failure_reason = last_failure_reason
        else:
            notification.failure_reason = last_failure_reason or "푸시 발송에 실패했습니다."
            if should_retry and notification.retry_count < max_retry_count:
                notification.delivery_status = NotificationDeliveryStatus.PENDING
            else:
                notification.delivery_status = NotificationDeliveryStatus.FAILED
        self.db.flush()
        return notification.delivery_status

    def dispatch_pending_notifications(self, *, limit: int = 50, max_retry_count: int = 3) -> dict[str, int]:
        pending = list(
            self.db.scalars(
                select(Notification)
                .where(Notification.delivery_status == NotificationDeliveryStatus.PENDING)
                .order_by(Notification.created_at.asc(), Notification.id.asc())
                .limit(limit)
            )
        )
        summary = {
            "processed": 0,
            "sent": 0,
            "failed": 0,
            "no_token": 0,
            "pending": 0,
        }
        for notification in pending:
            status = self.dispatch_notification(notification, max_retry_count=max_retry_count)
            summary["processed"] += 1
            summary[status.value] = summary.get(status.value, 0) + 1
        self.db.flush()
        return summary


def _build_data_payload(payload: PushPayload) -> dict[str, str]:
    return {
        "notification_id": str(payload.notification_id),
        "route": payload.target_path or "/notifications",
        "type": payload.notification_type or "notification",
        "stock_code": payload.stock_code or "",
        "signal_event_id": str(payload.signal_event_id or ""),
        "event_type": payload.event_type or "",
    }


def _read_http_error(exc: HTTPError) -> str:
    try:
        return exc.read().decode("utf-8")
    except Exception:  # pragma: no cover - defensive
        return f"FCM HTTP 오류: {exc.code}"


def _build_failure_result(reason: str) -> PushSendResult:
    normalized = reason or "FCM 발송 실패"
    upper_reason = normalized.upper()
    should_deactivate = any(marker.upper() in upper_reason for marker in INVALID_TOKEN_MARKERS)
    should_retry = any(marker.upper() in upper_reason for marker in TRANSIENT_ERROR_MARKERS)
    return PushSendResult(
        success=False,
        failure_reason=normalized,
        should_deactivate_token=should_deactivate,
        should_retry=should_retry,
    )
