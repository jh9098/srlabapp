from fastapi import Header

from app.core.errors import AppError


def get_optional_user_identifier(x_user_identifier: str | None = Header(default=None)) -> str | None:
    return x_user_identifier


def get_required_user_identifier(x_user_identifier: str | None = Header(default=None)) -> str:
    if not x_user_identifier:
        raise AppError(
            message="X-User-Identifier header is required.",
            error_code="AUTH_REQUIRED",
            status_code=401,
        )
    return x_user_identifier
