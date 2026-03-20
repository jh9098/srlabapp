from __future__ import annotations

import os
from typing import Any

from app.core.config import get_settings

_FIREBASE_APP: Any | None = None


class FirebaseConfigurationError(RuntimeError):
    """Raised when Firebase Admin SDK cannot be initialized."""


def _load_firebase_admin_modules() -> tuple[Any, Any, Any]:
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError as exc:  # pragma: no cover - depends on runtime installation
        raise FirebaseConfigurationError(
            "firebase-admin 패키지가 설치되지 않았습니다. `pip install firebase-admin` 또는 프로젝트 의존성 설치가 필요합니다."
        ) from exc
    return firebase_admin, credentials, firestore


def get_firestore_client() -> Any:
    firebase_admin, credentials, firestore = _load_firebase_admin_modules()
    app = _get_or_initialize_app(firebase_admin, credentials)
    return firestore.client(app=app)


def _get_or_initialize_app(firebase_admin: Any, credentials: Any) -> Any:
    global _FIREBASE_APP
    if _FIREBASE_APP is not None:
        return _FIREBASE_APP
    existing_apps = getattr(firebase_admin, "_apps", None)
    if existing_apps:
        _FIREBASE_APP = next(iter(existing_apps.values()))
        return _FIREBASE_APP

    settings = get_settings()
    credential_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS") or settings.firebase_credentials_file
    if not credential_path:
        raise FirebaseConfigurationError(
            "Firebase 자격증명이 없습니다. GOOGLE_APPLICATION_CREDENTIALS 또는 FIREBASE_CREDENTIALS_FILE을 설정해주세요."
        )
    if not os.path.exists(credential_path):
        raise FirebaseConfigurationError(
            f"Firebase 자격증명 파일을 찾을 수 없습니다: {credential_path}"
        )

    certificate = credentials.Certificate(credential_path)
    init_kwargs: dict[str, Any] = {"credential": certificate}
    if settings.firebase_project_id:
        init_kwargs["options"] = {"projectId": settings.firebase_project_id}
    _FIREBASE_APP = firebase_admin.initialize_app(**init_kwargs)
    return _FIREBASE_APP
