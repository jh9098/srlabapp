from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import AppError
from app.integrations.firebase_admin import get_firestore_already_exists_exception, get_firestore_server_timestamp
from app.models.enums import PriceLevelType
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.price_level import PriceLevel
from app.models.stock import Stock


@dataclass(slots=True)
class WatchlistDocumentPayload:
    ticker: str
    name: str
    support_lines: list[int | float]
    resistance_lines: list[int | float]
    comment: str
    is_active: bool
    is_home_featured: bool
    market_type: str
    updated_by: str

    def to_firestore_dict(self, *, server_timestamp: Any, include_created_at: bool) -> dict[str, Any]:
        payload = {
            "ticker": self.ticker,
            "name": self.name,
            "supportLines": self.support_lines,
            "resistanceLines": self.resistance_lines,
            "comment": self.comment,
            "isActive": self.is_active,
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
        payload.is_active = False
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
        comment = self._resolve_comment(stock=stock, support_levels=support_levels)
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
            comment=comment,
            is_active=stock.is_active,
            is_home_featured=is_home_featured,
            market_type=stock.market_type.value,
            updated_by=actor_identifier,
        )

    def _upsert_watchlist_document(self, payload: WatchlistDocumentPayload) -> None:
        collection = self.firestore_client.collection(self.settings.firebase_watchlist_collection)
        document = collection.document(payload.ticker)
        server_timestamp = get_firestore_server_timestamp()
        create_payload = payload.to_firestore_dict(server_timestamp=server_timestamp, include_created_at=True)
        try:
            document.create(create_payload)
            return
        except Exception as exc:
            already_exists = get_firestore_already_exists_exception()
            if already_exists is None or not isinstance(exc, already_exists):
                raise self._build_write_error(payload.ticker, exc) from exc

        update_payload = payload.to_firestore_dict(server_timestamp=server_timestamp, include_created_at=False)
        try:
            document.set(update_payload, merge=True)
        except Exception as exc:
            raise self._build_write_error(payload.ticker, exc) from exc

    def _resolve_comment(self, *, stock: Stock, support_levels: list[PriceLevel]) -> str:
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
