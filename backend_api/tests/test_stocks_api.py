from decimal import Decimal

from sqlalchemy import delete, select

from app.models.enums import PriceLevelType
from app.models.price_level import PriceLevel
from app.models.stock import Stock
from app.models.support_state import SupportState


def _admin_headers(client) -> dict[str, str]:
    login_response = client.post(
        "/api/v1/admin/auth/login",
        json={"username": "admin", "password": "admin1234"},
    )
    assert login_response.status_code == 200
    token = login_response.json()["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_search_stocks_returns_matching_items(client):
    response = client.get("/api/v1/stocks/search", params={"q": "삼성"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is True
    assert payload["error_code"] is None
    assert payload["data"]["items"][0]["stock_code"] == "005930"
    assert payload["data"]["items"][0]["stock_name"] == "삼성전자"


def test_get_stock_detail_returns_screen_focused_structure(client):
    response = client.get("/api/v1/stocks/005930", headers={"X-User-Identifier": "demo-user"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is True
    assert payload["data"]["stock"]["stock_code"] == "005930"
    assert payload["data"]["status"]["code"] == "TESTING_SUPPORT"
    assert len(payload["data"]["reason_lines"]) == 3
    assert payload["data"]["watchlist"]["is_in_watchlist"] is True
    assert payload["data"]["watchlist"]["alert_enabled"] is True


def test_get_stock_detail_returns_waiting_fallback_without_support_state(client, db_session):
    stock = db_session.scalar(select(Stock).where(Stock.code == "042700"))
    assert stock is not None

    db_session.add(
        PriceLevel(
            stock_id=stock.id,
            level_type=PriceLevelType.SUPPORT,
            price=Decimal("88000"),
            source_label="operator",
        )
    )
    db_session.flush()
    db_session.execute(delete(SupportState).where(SupportState.stock_id == stock.id))
    db_session.commit()

    response = client.get("/api/v1/stocks/042700")

    assert response.status_code == 200
    payload = response.json()
    assert payload["success"] is True
    assert payload["data"]["status"]["code"] == "WAITING"
    assert payload["data"]["support_state"]["status"] == "WAITING"
    assert payload["data"]["support_state"]["reaction_type"] is None
    assert payload["data"]["support_state"]["first_touched_at"] is None
    assert payload["data"]["support_state"]["rebound_pct"] is None
    assert payload["data"]["reason_lines"] == [
        "아직 핵심 지지선 도달 전입니다.",
        "지지선 근접 여부를 먼저 확인해야 합니다.",
        "섣부른 반등 판단은 보류하는 구간입니다.",
    ]


def test_admin_support_level_creates_waiting_support_state_and_detail_stays_available(client, db_session):
    stock = db_session.scalar(select(Stock).where(Stock.code == "042700"))
    assert stock is not None

    response = client.post(
        "/api/v1/admin/price-levels",
        headers=_admin_headers(client),
        json={
            "stock_id": stock.id,
            "level_type": "SUPPORT",
            "price": "88100",
            "proximity_threshold_pct": "1.50",
            "rebound_threshold_pct": "5.00",
            "source_label": "operator",
            "note": "상세 진입 테스트용 지지선",
            "is_active": True,
        },
    )

    assert response.status_code == 200

    created_level_id = response.json()["data"]["id"]
    support_state = db_session.scalar(select(SupportState).where(SupportState.price_level_id == created_level_id))
    assert support_state is not None
    assert support_state.status.value == "WAITING"
    assert str(support_state.reference_price) == "88100.00"
    assert str(support_state.last_price) == "88100.00"
    assert support_state.status_reason == "관리자 지지선 등록으로 생성된 초기 상태"

    detail_response = client.get("/api/v1/stocks/042700")
    assert detail_response.status_code == 200
    detail_payload = detail_response.json()
    assert detail_payload["data"]["status"]["code"] == "WAITING"
    assert detail_payload["data"]["support_state"]["status"] == "WAITING"
