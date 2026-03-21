from __future__ import annotations

import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import AppError
from app.integrations.firebase_admin import get_firestore_server_timestamp
from app.models.enums import PriceLevelType
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.price_level import PriceLevel
from app.models.stock import Stock

LOGGER = logging.getLogger(__name__)


@dataclass(slots=True)
class WatchlistDocumentPayload:
    ticker: str
    name: str
    support_lines: list[int | float]
    resistance_lines: list[int | float]
    memo: str
    alert_enabled: bool
    alert_cooldown_hours: int
    alert_threshold_percent: int
    analysis_id: str | None
    is_public: bool
    portfolio_ready: bool
    comment: str
    is_home_featured: bool
    market_type: str
    updated_by: str

    def to_firestore_dict(self, *, server_timestamp: Any, include_created_at: bool) -> dict[str, Any]:
        payload = {
            "ticker": self.ticker,
            "name": self.name,
            "supportLines": self.support_lines,
            "resistanceLines": self.resistance_lines,
            "memo": self.memo,
            "alertEnabled": self.alert_enabled,
            "alertCooldownHours": self.alert_cooldown_hours,
            "alertThresholdPercent": self.alert_threshold_percent,
            "analysisId": self.analysis_id,
            "isPublic": self.is_public,
            "portfolioReady": self.portfolio_ready,
            "comment": self.comment,
            "isHomeFeatured": self.is_home_featured,
            "marketType": self.market_type,
            "source": "app_admin",
            "updatedBy": self.updated_by,
            "updatedAt": server_timestamp,
        }
        if include_created_at:
            payload["createdAt"] = server_timestamp
        return payload


class FirebaseWatchlistWriter:
    def __init__(self, db: Session, firestore_client: Any) -> None:
        self.db = db
        self.firestore_client = firestore_client
        self.settings = get_settings()

    def sync_stock(self, *, stock: Stock, actor_identifier: str) -> None:
        payload = self._build_payload(stock=stock, actor_identifier=actor_identifier)
        self._upsert_watchlist_document(payload)

    def sync_home_featured_flags(self, *, stock_codes: list[str], actor_identifier: str) -> None:
        for stock_code in stock_codes:
            stock = self.db.scalar(select(Stock).where(Stock.code == stock_code))
            if stock is None:
                continue
            payload = self._build_payload(stock=stock, actor_identifier=actor_identifier)
            self._upsert_watchlist_document(payload)

    def deactivate_watchlist_document(self, *, stock: Stock, actor_identifier: str) -> None:
        payload = self._build_payload(stock=stock, actor_identifier=actor_identifier)
        payload.is_public = False
        payload.portfolio_ready = False
        self._upsert_watchlist_document(payload)

    def _build_payload(self, *, stock: Stock, actor_identifier: str) -> WatchlistDocumentPayload:
        support_levels = list(
            self.db.scalars(
                select(PriceLevel)
                .where(
                    PriceLevel.stock_id == stock.id,
                    PriceLevel.level_type == PriceLevelType.SUPPORT,
                    PriceLevel.is_active.is_(True),
                    PriceLevel.source_label == "admin_home",
                )
                .order_by(PriceLevel.price.asc())
            )
        )
        support_lines = [self._serialize_price(level.price) for level in support_levels]
        memo = self._resolve_memo(stock=stock, support_levels=support_levels)
        is_home_featured = bool(
            self.db.scalar(
                select(HomeFeaturedStock.id).where(
                    HomeFeaturedStock.stock_id == stock.id,
                    HomeFeaturedStock.is_active.is_(True),
                )
            )
        )
        return WatchlistDocumentPayload(
            ticker=stock.code,
            name=stock.name,
            support_lines=support_lines,
            resistance_lines=[],
            memo=memo,
            alert_enabled=True,
            alert_cooldown_hours=1,
            alert_threshold_percent=2,
            analysis_id=None,
            is_public=stock.is_active,
            portfolio_ready=stock.is_active,
            comment=memo,
            is_home_featured=is_home_featured,
            market_type=stock.market_type.value,
            updated_by=actor_identifier,
        )

    def _upsert_watchlist_document(self, payload: WatchlistDocumentPayload) -> None:
        collection = self.firestore_client.collection(self.settings.firebase_watchlist_collection)
        server_timestamp = get_firestore_server_timestamp()
        document, include_created_at = self._resolve_document_for_upsert(collection=collection, ticker=payload.ticker)
        firestore_payload = payload.to_firestore_dict(
            server_timestamp=server_timestamp,
            include_created_at=include_created_at,
        )
        try:
            document.set(firestore_payload, merge=True)
        except Exception as exc:
            raise self._build_write_error(payload.ticker, exc) from exc

    def _resolve_document_for_upsert(self, *, collection: Any, ticker: str) -> tuple[Any, bool]:
        try:
            matches = list(collection.where("ticker", "==", ticker).limit(2).stream())
        except Exception as exc:
            raise self._build_write_error(ticker, exc) from exc

        if len(matches) >= 2:
            LOGGER.warning(
                "Duplicate adminWatchlist documents detected for ticker=%s; updating first match.",
                ticker,
            )
        if matches:
            return matches[0].reference, False
        return collection.document(), True

    def _resolve_memo(self, *, stock: Stock, support_levels: list[PriceLevel]) -> str:
        stock_comment = (stock.operator_memo or "").strip()
        if stock_comment:
            return stock_comment
        for level in support_levels:
            note = (level.note or "").strip()
            if note:
                return note
        return ""

    def _serialize_price(self, price: Decimal) -> int | float:
        normalized = price.normalize()
        if normalized == normalized.to_integral():
            return int(normalized)
        return float(normalized)

    def _build_write_error(self, ticker: str, exc: Exception) -> AppError:
        return AppError(
            message="Firebase 관심종목 원본 반영에 실패했습니다.",
            error_code="FIREBASE_WATCHLIST_WRITE_FAILED",
            status_code=503,
        )
