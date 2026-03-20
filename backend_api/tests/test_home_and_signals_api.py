def test_get_home_api(client) -> None:
    response = client.get("/api/v1/home", headers={"X-User-Identifier": "demo-user"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["data"]["market_summary"]["headline"]
    assert payload["data"]["featured_stocks"]
    assert payload["data"]["watchlist_signal_summary"]["support_near_count"] >= 1
    assert payload["data"]["themes"]
    assert payload["data"]["recent_contents"]
    assert all(item["title"] != "비노출 점검용 콘텐츠" for item in payload["data"]["recent_contents"])



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
    assert payload["data"]["items"][0]["stock_count"] >= 1



def test_get_theme_detail_and_contents_api(client) -> None:
    theme_response = client.get('/api/v1/themes/1')
    assert theme_response.status_code == 200
    theme_payload = theme_response.json()['data']
    assert theme_payload['theme']['theme_id'] == 1
    assert theme_payload['stocks']
    assert all(item['title'] != '비노출 점검용 콘텐츠' for item in theme_payload['recent_contents'])

    contents_response = client.get('/api/v1/contents', params={'category': 'SHORTS', 'limit': 10})
    assert contents_response.status_code == 200
    content_items = contents_response.json()['data']['items']
    assert content_items
    assert all(item['category'] == 'SHORTS' for item in content_items)
