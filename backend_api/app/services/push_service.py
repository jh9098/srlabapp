from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.device_token import DeviceToken


@dataclass
class PushPayload:
    title: str
    message: str
    target_path: str | None
    notification_id: int


class PushProvider:
    def send(self, *, token: str, payload: PushPayload) -> None:  # pragma: no cover - interface
        raise NotImplementedError


class StubPushProvider(PushProvider):
    def send(self, *, token: str, payload: PushPayload) -> None:
        return None


class PushService:
    def __init__(self, db: Session, provider: PushProvider | None = None) -> None:
        self.db = db
        self.provider = provider or StubPushProvider()

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
        self.db.flush()
        return sent
