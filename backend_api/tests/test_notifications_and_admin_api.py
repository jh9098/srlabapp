def admin_auth_headers(client):
    login_response = client.post(
        '/api/v1/admin/auth/login',
        json={'username': 'admin', 'password': 'admin1234'},
    )
    assert login_response.status_code == 200
    token = login_response.json()['data']['access_token']
    return {'Authorization': f'Bearer {token}'}


def test_notifications_api_and_read_flow(client):
    response = client.get('/api/v1/notifications', headers={'X-User-Identifier': 'demo-user'})
    assert response.status_code == 200
    payload = response.json()
    assert payload['data']['items']
    notification_id = payload['data']['items'][0]['notification_id']

    mark_response = client.patch(
        f'/api/v1/notifications/{notification_id}/read',
        headers={'X-User-Identifier': 'demo-user'},
    )
    assert mark_response.status_code == 200
    assert mark_response.json()['data']['is_read'] is True


def test_alert_settings_api(client):
    response = client.get('/api/v1/me/alert-settings', headers={'X-User-Identifier': 'demo-user'})
    assert response.status_code == 200
    assert response.json()['data']['push_enabled'] is True

    update = client.patch(
        '/api/v1/me/alert-settings',
        headers={'X-User-Identifier': 'demo-user'},
        json={
            'price_signal_enabled': False,
            'theme_signal_enabled': True,
            'content_update_enabled': True,
            'admin_notice_enabled': True,
            'push_enabled': False,
        },
    )
    assert update.status_code == 200
    assert update.json()['data']['price_signal_enabled'] is False


def test_device_token_register_api(client):
    response = client.post(
        '/api/v1/me/device-tokens',
        headers={'X-User-Identifier': 'demo-user'},
        json={
            'device_token': 'new-fcm-token',
            'platform': 'android',
            'provider': 'fcm',
            'device_label': 'pixel-test',
        },
    )
    assert response.status_code == 200
    assert response.json()['data']['provider'] == 'fcm'


def test_admin_login_and_session(client):
    login_response = client.post(
        '/api/v1/admin/auth/login',
        json={'username': 'admin', 'password': 'admin1234'},
    )
    assert login_response.status_code == 200
    token = login_response.json()['data']['access_token']

    me_response = client.get('/api/v1/admin/auth/me', headers={'Authorization': f'Bearer {token}'})
    assert me_response.status_code == 200
    assert me_response.json()['data']['admin_username'] == 'admin'


def test_admin_force_update_and_manual_push_logs_audit(client):
    headers = admin_auth_headers(client)
    state_response = client.get('/api/v1/admin/support-states', headers=headers)
    assert state_response.status_code == 200
    state_id = state_response.json()['data'][0]['id']

    update_response = client.patch(
        f'/api/v1/admin/support-states/{state_id}/force',
        headers=headers,
        json={'status': 'INVALID', 'memo': '수동 검수', 'status_reason': '운영자 수정'},
    )
    assert update_response.status_code == 200
    assert update_response.json()['data']['status'] == 'INVALID'

    push_response = client.post(
        '/api/v1/admin/manual-push',
        headers=headers,
        json={
            'user_identifier': 'demo-user',
            'title': '운영 공지',
            'message': '수동 발송 테스트',
            'target_path': '/notifications',
            'memo': '테스트 발송',
        },
    )
    assert push_response.status_code == 200

    audit_response = client.get('/api/v1/admin/audit-logs', headers=headers)
    assert audit_response.status_code == 200
    actions = [item['action'] for item in audit_response.json()['data']['items']]
    assert 'force_update_support_state' in actions
    assert 'manual_push' in actions
