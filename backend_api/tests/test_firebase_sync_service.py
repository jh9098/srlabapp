from __future__ import annotations

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import select

from app.models.daily_bar import DailyBar
from app.models.enums import PriceLevelType
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState
from app.services.firebase_sync_service import FIREBASE_LEVEL_SOURCE, FirebaseSyncService


class FakeDocument:
    def __init__(self, doc_id: str, data: dict, exists: bool = True) -> None:
        self.id = doc_id
        self._data = data
        self.exists = exists

    def to_dict(self) -> dict:
        return self._data

    def get(self) -> "FakeDocument":
        return self


class FakeCollection:
    def __init__(self, documents: dict[str, dict]) -> None:
        self.documents = documents

    def stream(self):
        return [FakeDocument(doc_id, data) for doc_id, data in self.documents.items()]

    def document(self, doc_id: str) -> FakeDocument:
        data = self.documents.get(doc_id)
        if data is None:
            return FakeDocument(doc_id, {}, exists=False)
        return FakeDocument(doc_id, data)


class FakeFirestoreClient:
    def __init__(self, *, watchlist_documents: dict[str, dict], price_documents: dict[str, dict]) -> None:
        self.watchlist_documents = watchlist_documents
        self.price_documents = price_documents

    def collection(self, name: str) -> FakeCollection:
        if name == "adminWatchlist":
            return FakeCollection(self.watchlist_documents)
        if name == "stock_prices":
            return FakeCollection(self.price_documents)
        raise KeyError(name)


def make_firestore_client() -> FakeFirestoreClient:
    return FakeFirestoreClient(
        watchlist_documents={
            "watch-1": {
                "ticker": "111111",
                "name": "테스트종목",
                "supportLines": ["1000", 1000, "950.5"],
                "resistanceLines": ["1100", 1200],
                "createdAt": datetime(2026, 3, 20, 9, 0, tzinfo=timezone.utc),
            },
            "watch-2": {
                "ticker": "222222",
                "name": "홈노출종목",
                "supportLines": [2000],
                "resistanceLines": [2300],
                "createdAt": datetime(2026, 3, 20, 10, 0, tzinfo=timezone.utc),
            },
        },
        price_documents={
            "111111": {
                "name": "테스트종목",
                "prices": [
                    {"date": "2026-03-18", "open": 1000, "high": 1010, "low": 990, "close": 1005, "volume": 10000},
                    {"date": "2026-03-19", "open": 1005, "high": 1030, "low": 1000, "close": 1020, "volume": 12000},
                    {"date": "2026-03-20", "open": 1020, "high": 1040, "low": 1015, "close": 1035, "volume": 15000},
                ],
            },
            "222222": {
                "name": "홈노출종목",
                "prices": [
                    {"date": "2026-03-20", "open": 2000, "high": 2100, "low": 1990, "close": 2050, "volume": 22000},
                    {"date": "bad-date", "open": 1, "high": 1, "low": 1, "close": 1, "volume": 1},
                ],
            },
        },
    )


def test_sync_watchlist_stocks_and_levels_maps_firestore_documents(db_session) -> None:
    manual_stock = db_session.scalar(select(Stock).where(Stock.code == "111111"))
    if manual_stock is None:
        manual_stock = Stock(code="111111", name="수동종목")
        db_session.add(manual_stock)
        db_session.flush()
    db_session.add(
        PriceLevel(
            stock_id=manual_stock.id,
            level_type=PriceLevelType.SUPPORT,
            price=Decimal("888.00"),
            source_label="MANUAL",
            note="manual level",
        )
    )
    db_session.commit()

    service = FirebaseSyncService(db_session, make_firestore_client())
    summary = service.sync_watchlist_stocks_and_levels()

    assert summary["scanned_count"] == 2
    assert summary["stock_upserted_count"] == 2
    assert summary["level_inserted_count"] == 6

    stock = db_session.scalar(select(Stock).where(Stock.code == "111111"))
    assert stock is not None
    assert stock.name == "테스트종목"

    firebase_levels = list(
        db_session.scalars(
            select(PriceLevel).where(
                PriceLevel.stock_id == stock.id,
                PriceLevel.source_label == FIREBASE_LEVEL_SOURCE,
                PriceLevel.is_active.is_(True),
            )
        )
    )
    assert sorted(level.price for level in firebase_levels) == [Decimal("950.50"), Decimal("1000.00"), Decimal("1100.00"), Decimal("1200.00")]

    manual_levels = list(
        db_session.scalars(select(PriceLevel).where(PriceLevel.stock_id == stock.id, PriceLevel.source_label == "MANUAL"))
    )
    assert len(manual_levels) == 1
    assert manual_levels[0].is_active is True

    support_states = list(db_session.scalars(select(SupportState).where(SupportState.stock_id == stock.id)))
    assert support_states


def test_sync_daily_bars_calculates_change_and_is_idempotent(db_session) -> None:
    service = FirebaseSyncService(db_session, make_firestore_client())
    service.sync_watchlist_stocks_and_levels()

    first_summary = service.sync_daily_bars(tickers=["111111", "222222"])
    second_summary = service.sync_daily_bars(tickers=["111111", "222222"])

    assert first_summary["daily_bar_upserted_count"] == 4
    assert second_summary["daily_bar_upserted_count"] == 4
    assert second_summary["skipped_count"] == 1

    stock = db_session.scalar(select(Stock).where(Stock.code == "111111"))
    bars = list(db_session.scalars(select(DailyBar).where(DailyBar.stock_id == stock.id).order_by(DailyBar.trade_date.asc())))
    assert len(bars) == 3
    assert bars[0].change_value == Decimal("0.00")
    assert bars[0].change_pct == Decimal("0.00")
    assert bars[1].change_value == Decimal("15.00")
    assert bars[1].change_pct == Decimal("1.49")
    assert bars[2].change_value == Decimal("15.00")
    assert bars[2].change_pct == Decimal("1.47")


def test_sync_daily_bars_dry_run_rolls_back_changes(db_session) -> None:
    service = FirebaseSyncService(db_session, make_firestore_client())

    service.sync_watchlist_stocks_and_levels(dry_run=True)
    assert db_session.scalar(select(Stock).where(Stock.code == "111111")) is None

    service.sync_daily_bars(tickers=["111111"], dry_run=True)
    assert db_session.scalar(select(DailyBar).join(Stock).where(Stock.code == "111111")) is None


def test_full_sync_enables_home_and_stock_detail_apis(db_session, client) -> None:
    service = FirebaseSyncService(db_session, make_firestore_client())
    summary = service.run_full_sync(sync_home_featured=True, home_featured_limit=2)

    assert summary["watchlist"]["stock_upserted_count"] == 2
    assert summary["prices"]["daily_bar_upserted_count"] == 4
    assert summary["home_featured"]["home_featured_upserted_count"] == 2

    home_response = client.get("/api/v1/home")
    assert home_response.status_code == 200
    featured_codes = [item["stock_code"] for item in home_response.json()["data"]["featured_stocks"]]
    assert "222222" in featured_codes
    assert all(item["current_price"] is not None for item in home_response.json()["data"]["featured_stocks"])

    detail_response = client.get("/api/v1/stocks/111111")
    assert detail_response.status_code == 200
    detail_payload = detail_response.json()["data"]
    assert detail_payload["price"]["current_price"] == "1035.00"
    assert len(detail_payload["chart"]["daily_bars"]) == 3

    featured_entries = list(db_session.scalars(select(HomeFeaturedStock).where(HomeFeaturedStock.is_active.is_(True))))
    assert len(featured_entries) == 2
