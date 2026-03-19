def test_get_home_api(client) -> None:
    response = client.get("/api/v1/home", headers={"X-User-Identifier": "demo-user"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["data"]["market_summary"]["headline"]
    assert payload["data"]["featured_stocks"]
    assert payload["data"]["watchlist_signal_summary"]["support_near_count"] >= 1
    assert payload["data"]["themes"]
    assert payload["data"]["recent_contents"]



def test_get_stock_signals_api(client) -> None:
    response = client.get("/api/v1/stocks/005930/signals")

    assert response.status_code == 200
    payload = response.json()
    assert payload["data"]["items"][0]["signal_type"] == "SUPPORT_NEAR"



def test_get_themes_api(client) -> None:
    response = client.get("/api/v1/themes")

    assert response.status_code == 200
    payload = response.json()
    assert payload["data"]["items"][0]["leader_stock"]["stock_code"] == "000660"
