import json
import logging
from dataclasses import dataclass
from urllib import request
from urllib.error import HTTPError, URLError

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.device_token import DeviceToken

logger = logging.getLogger(__name__)


@dataclass
class PushPayload:
    title: str
    message: str
    target_path: str | None
    notification_id: int


class PushProvider:
    def send(self, *, token: str, payload: PushPayload) -> None:  # pragma: no cover - interface
        raise NotImplementedError


class FcmPushProvider(PushProvider):
    def __init__(self) -> None:
        self.settings = get_settings()
        if not self.settings.fcm_server_key:
            raise RuntimeError("FCM_SERVER_KEY가 설정되지 않았습니다.")

    def send(self, *, token: str, payload: PushPayload) -> None:
        body = json.dumps(
            {
                "to": token,
                "notification": {
                    "title": payload.title,
                    "body": payload.message,
                },
                "data": {
                    "target_path": payload.target_path or "",
                    "notification_id": str(payload.notification_id),
                },
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
                response.read()
        except HTTPError as exc:  # pragma: no cover - network dependent
            raise RuntimeError(f"FCM HTTP 오류: {exc.code}") from exc
        except URLError as exc:  # pragma: no cover - network dependent
            raise RuntimeError(f"FCM 네트워크 오류: {exc.reason}") from exc


class LoggingFallbackPushProvider(PushProvider):
    def send(self, *, token: str, payload: PushPayload) -> None:
        logger.info(
            "FCM 설정이 없어 DB 저장만 수행했습니다. token=%s notification_id=%s target_path=%s",
            token,
            payload.notification_id,
            payload.target_path,
        )


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

    def dispatch_to_user(self, *, user_identifier: str, payload: PushPayload) -> int:
        stmt = select(DeviceToken).where(
            DeviceToken.user_identifier == user_identifier,
            DeviceToken.is_active.is_(True),
        )
        sent = 0
        for token in self.db.scalars(stmt):
            try:
                self.provider.send(token=token.device_token, payload=payload)
                token.last_error = None
                sent += 1
            except Exception as exc:  # pragma: no cover - defensive
                token.last_error = str(exc)
                logger.warning("푸시 전송 실패 token_id=%s error=%s", token.id, exc)
        self.db.flush()
        return sent
