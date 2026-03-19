def test_watchlist_crud_and_alert_update(client):
    create_response = client.post(
        "/api/v1/watchlist",
        headers={"X-User-Identifier": "test-user"},
        json={"stock_code": "000660", "alert_enabled": True},
    )
    assert create_response.status_code == 201
    create_payload = create_response.json()
    assert create_payload["success"] is True
    watchlist_id = create_payload["data"]["watchlist_id"]

    list_response = client.get("/api/v1/watchlist", headers={"X-User-Identifier": "test-user"})
    assert list_response.status_code == 200
    list_payload = list_response.json()
    assert list_payload["data"]["summary"]["total_count"] == 1
    assert list_payload["data"]["items"][0]["stock_code"] == "000660"
    assert list_payload["data"]["items"][0]["alert_enabled"] is True

    patch_response = client.patch(
        f"/api/v1/watchlist/{watchlist_id}/alert",
        headers={"X-User-Identifier": "test-user"},
        json={"alert_enabled": False},
    )
    assert patch_response.status_code == 200
    patch_payload = patch_response.json()
    assert patch_payload["data"]["alert_enabled"] is False

    delete_response = client.delete(
        f"/api/v1/watchlist/{watchlist_id}",
        headers={"X-User-Identifier": "test-user"},
    )
    assert delete_response.status_code == 200
    delete_payload = delete_response.json()
    assert delete_payload["data"]["deleted"] is True

    final_list_response = client.get("/api/v1/watchlist", headers={"X-User-Identifier": "test-user"})
    assert final_list_response.status_code == 200
    final_list_payload = final_list_response.json()
    assert final_list_payload["data"]["summary"]["total_count"] == 0
