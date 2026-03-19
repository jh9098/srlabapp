import base64
import hashlib
import hmac
import json
from datetime import datetime, timedelta, timezone

from fastapi import Header
from pydantic import BaseModel

from app.core.config import get_settings
from app.core.errors import AppError


class AdminTokenPayload(BaseModel):
    sub: str
    role: str = "ADMIN"
    exp: int
    iat: int


class AdminAuthService:
    def __init__(self) -> None:
        self.settings = get_settings()

    def authenticate(self, *, username: str, password: str) -> str:
        if username != self.settings.admin_username or password != self.settings.admin_password:
            raise AppError(
                message="관리자 계정 정보가 올바르지 않습니다.",
                error_code="ADMIN_LOGIN_FAILED",
                status_code=401,
            )
        return self.create_access_token(subject=username)

    def create_access_token(self, *, subject: str) -> str:
        now = datetime.now(timezone.utc)
        expire_at = now + timedelta(minutes=self.settings.admin_token_expire_minutes)
        payload = AdminTokenPayload(
            sub=subject,
            role="ADMIN",
            iat=int(now.timestamp()),
            exp=int(expire_at.timestamp()),
        )
        payload_json = json.dumps(payload.model_dump(), separators=(",", ":")).encode("utf-8")
        payload_b64 = base64.urlsafe_b64encode(payload_json).decode("utf-8").rstrip("=")
        signature = self._sign(payload_b64)
        return f"{payload_b64}.{signature}"

    def decode_token(self, token: str) -> AdminTokenPayload:
        try:
            payload_b64, signature = token.split(".", 1)
        except ValueError as exc:
            raise AppError(
                message="관리자 인증 토큰 형식이 올바르지 않습니다.",
                error_code="ADMIN_AUTH_INVALID",
                status_code=401,
            ) from exc

        expected_signature = self._sign(payload_b64)
        if not hmac.compare_digest(signature, expected_signature):
            raise AppError(
                message="관리자 인증 토큰 서명이 유효하지 않습니다.",
                error_code="ADMIN_AUTH_INVALID",
                status_code=401,
            )

        padding = "=" * (-len(payload_b64) % 4)
        payload_data = base64.urlsafe_b64decode(f"{payload_b64}{padding}".encode("utf-8"))
        payload = AdminTokenPayload.model_validate_json(payload_data)
        now_ts = int(datetime.now(timezone.utc).timestamp())
        if payload.exp < now_ts:
            raise AppError(
                message="관리자 인증 토큰이 만료되었습니다.",
                error_code="ADMIN_AUTH_EXPIRED",
                status_code=401,
            )
        return payload

    def _sign(self, payload_b64: str) -> str:
        digest = hmac.new(
            self.settings.admin_jwt_secret.encode("utf-8"),
            payload_b64.encode("utf-8"),
            hashlib.sha256,
        ).digest()
        return base64.urlsafe_b64encode(digest).decode("utf-8").rstrip("=")


def get_admin_bearer_token(authorization: str | None = Header(default=None)) -> str:
    if not authorization:
        raise AppError(
            message="관리자 인증 토큰이 필요합니다.",
            error_code="ADMIN_AUTH_REQUIRED",
            status_code=401,
        )
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise AppError(
            message="Authorization 헤더는 Bearer 토큰 형식이어야 합니다.",
            error_code="ADMIN_AUTH_INVALID",
            status_code=401,
        )
    return token
