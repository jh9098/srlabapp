import os
import sys
from collections.abc import Generator
from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any
from urllib.parse import urlencode, urlsplit

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

os.environ["APP_ENV"] = "test"
os.environ["DATABASE_URL"] = "sqlite+pysqlite:///:memory:"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.models import (
    AdminAuditLog,
    AlertSetting,
    ContentPost,
    DeviceToken,
    HomeFeaturedStock,
    Notification,
    DailyBar,
    PriceLevel,
    SignalEvent,
    Stock,
    SupportState,
    Theme,
    ThemeStockMap,
    Watchlist,
)  # noqa: F401
from app.services.seed import seed_minimum_data


@dataclass
class SimpleResponse:
    status_code: int
    headers: dict[str, str]
    body: bytes

    def json(self) -> Any:
        if not self.body:
            return None
        return json.loads(self.body.decode("utf-8"))

    @property
    def text(self) -> str:
        return self.body.decode("utf-8")


class SimpleTestClient:
    def __init__(self, app) -> None:
        self.app = app

    def get(self, url: str, *, params: dict[str, Any] | None = None, headers: dict[str, str] | None = None) -> SimpleResponse:
        return self.request("GET", url, params=params, headers=headers)

    def post(
        self,
        url: str,
        *,
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
        json: Any = None,
    ) -> SimpleResponse:
        return self.request("POST", url, params=params, headers=headers, json=json)

    def patch(
        self,
        url: str,
        *,
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
        json: Any = None,
    ) -> SimpleResponse:
        return self.request("PATCH", url, params=params, headers=headers, json=json)

    def delete(
        self,
        url: str,
        *,
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
        json: Any = None,
    ) -> SimpleResponse:
        return self.request("DELETE", url, params=params, headers=headers, json=json)

    def request(
        self,
        method: str,
        url: str,
        *,
        params: dict[str, Any] | None = None,
        headers: dict[str, str] | None = None,
        json: Any = None,
    ) -> SimpleResponse:
        import asyncio

        return asyncio.run(
            self._request_async(method=method, url=url, params=params, headers=headers, json_body=json)
        )

    async def _request_async(
        self,
        *,
        method: str,
        url: str,
        params: dict[str, Any] | None,
        headers: dict[str, str] | None,
        json_body: Any,
    ) -> SimpleResponse:
        request_headers = {"host": "testserver", **(headers or {})}
        body = b""
        if json_body is not None:
            body = json.dumps(json_body, ensure_ascii=False).encode("utf-8")
            request_headers.setdefault("content-type", "application/json")
        request_headers.setdefault("content-length", str(len(body)))

        full_url = self._merge_url(url, params)
        split = urlsplit(full_url)
        response_status: int | None = None
        response_headers: dict[str, str] = {}
        response_body = bytearray()
        request_sent = False

        async def receive() -> dict[str, Any]:
            nonlocal request_sent
            if request_sent:
                return {"type": "http.disconnect"}
            request_sent = True
            return {"type": "http.request", "body": body, "more_body": False}

        async def send(message: dict[str, Any]) -> None:
            nonlocal response_status, response_headers
            if message["type"] == "http.response.start":
                response_status = message["status"]
                response_headers = {
                    key.decode("latin1"): value.decode("latin1")
                    for key, value in message.get("headers", [])
                }
            elif message["type"] == "http.response.body":
                response_body.extend(message.get("body", b""))

        scope = {
            "type": "http",
            "asgi": {"version": "3.0"},
            "http_version": "1.1",
            "method": method,
            "scheme": split.scheme or "http",
            "path": split.path,
            "raw_path": split.path.encode("utf-8"),
            "query_string": split.query.encode("utf-8"),
            "headers": [
                (key.lower().encode("latin1"), value.encode("latin1"))
                for key, value in request_headers.items()
            ],
            "client": ("testclient", 50000),
            "server": ("testserver", 80),
            "state": {},
        }

        await self.app(scope, receive, send)

        return SimpleResponse(
            status_code=response_status or 500,
            headers=response_headers,
            body=bytes(response_body),
        )

    def _merge_url(self, url: str, params: dict[str, Any] | None) -> str:
        if not params:
            return url
        query = urlencode(params, doseq=True)
        joiner = "&" if "?" in url else "?"
        return f"{url}{joiner}{query}"


@pytest.fixture()
def db_session() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        future=True,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False, class_=Session)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    seed_minimum_data(session)
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


@pytest.fixture()
def client(db_session: Session) -> Generator[SimpleTestClient, None, None]:
    def override_get_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    try:
        yield SimpleTestClient(app)
    finally:
        app.dependency_overrides.clear()
