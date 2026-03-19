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
