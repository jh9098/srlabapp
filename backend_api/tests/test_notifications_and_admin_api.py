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



def test_admin_content_crud_and_public_visibility(client):
    headers = admin_auth_headers(client)
    create_response = client.post(
        '/api/v1/admin/contents',
        headers=headers,
        json={
            'category': 'SHORTS',
            'title': '새 쇼츠 카드',
            'summary': '운영자가 등록한 최신 콘텐츠',
            'external_url': 'https://example.com/shorts/new',
            'sort_order': 0,
            'is_published': True,
        },
    )
    assert create_response.status_code == 200
    content_id = create_response.json()['data']['id']

    list_response = client.get('/api/v1/admin/contents', headers=headers)
    assert list_response.status_code == 200
    assert any(item['id'] == content_id for item in list_response.json()['data'])

    public_response = client.get('/api/v1/contents', params={'category': 'SHORTS'})
    assert public_response.status_code == 200
    assert any(item['content_id'] == content_id for item in public_response.json()['data']['items'])

    hide_response = client.put(
        f'/api/v1/admin/contents/{content_id}',
        headers=headers,
        json={
            'category': 'SHORTS',
            'title': '새 쇼츠 카드',
            'summary': '숨김 처리 테스트',
            'external_url': 'https://example.com/shorts/new',
            'sort_order': 0,
            'is_published': False,
        },
    )
    assert hide_response.status_code == 200

    public_hidden = client.get('/api/v1/contents', params={'category': 'SHORTS'})
    public_ids = [item['content_id'] for item in public_hidden.json()['data']['items']]
    assert content_id not in public_ids


from sqlalchemy import select

from app.models.device_token import DeviceToken
from app.models.enums import NotificationDeliveryStatus
from app.models.notification import Notification
from app.services.notification_service import NotificationService
from app.services.push_service import PushProvider, PushSendResult


class FakeSuccessPushProvider(PushProvider):
    def send(self, *, token: str, payload):
        return PushSendResult(success=True, response_message_id=f"msg-{token}")


class FakeInvalidPushProvider(PushProvider):
    def send(self, *, token: str, payload):
        return PushSendResult(
            success=False,
            failure_reason='UNREGISTERED',
            should_deactivate_token=True,
        )


def test_device_token_deactivate_api(client, db_session):
    register_response = client.post(
        '/api/v1/me/device-tokens',
        headers={'X-User-Identifier': 'demo-user'},
        json={
            'device_token': 'deactivate-token',
            'platform': 'android',
            'provider': 'fcm',
        },
    )
    assert register_response.status_code == 200

    deactivate_response = client.post(
        '/api/v1/me/device-tokens/deactivate',
        headers={'X-User-Identifier': 'demo-user'},
        json={'device_token': 'deactivate-token'},
    )
    assert deactivate_response.status_code == 200
    token = db_session.scalar(select(DeviceToken).where(DeviceToken.device_token == 'deactivate-token'))
    assert token is not None
    assert token.is_active is False


def test_pending_notification_dispatch_marks_sent(db_session):
    notification = db_session.scalar(select(Notification).where(Notification.user_identifier == 'demo-user'))
    assert notification is not None
    notification.delivery_status = NotificationDeliveryStatus.PENDING

    service = NotificationService(
        db_session,
        push_service=None,
    )
    service.push_service.provider = FakeSuccessPushProvider()

    summary = service.dispatch_pending(limit=10)

    assert summary['processed'] >= 1
    assert notification.delivery_status == NotificationDeliveryStatus.SENT
    assert notification.response_message_id is not None


def test_invalid_token_is_deactivated_when_dispatch_fails(db_session):
    notification = db_session.scalar(select(Notification).where(Notification.user_identifier == 'demo-user'))
    assert notification is not None
    notification.delivery_status = NotificationDeliveryStatus.PENDING

    service = NotificationService(db_session)
    service.push_service.provider = FakeInvalidPushProvider()

    service.dispatch_pending(limit=10, max_retry_count=1)

    token = db_session.scalar(select(DeviceToken).where(DeviceToken.user_identifier == 'demo-user'))
    assert token is not None
    assert token.is_active is False
    assert notification.delivery_status == NotificationDeliveryStatus.FAILED


def test_admin_filters_for_stocks_levels_and_states(client):
    headers = admin_auth_headers(client)

    stocks_response = client.get('/api/v1/admin/stocks', headers=headers, params={'q': '삼성'})
    assert stocks_response.status_code == 200
    stock_items = stocks_response.json()['data']
    assert stock_items
    assert all('삼성' in item['name'] or '삼성' in item['code'] for item in stock_items)

    stock_id = stock_items[0]['id']
    levels_response = client.get('/api/v1/admin/price-levels', headers=headers, params={'stock_id': stock_id, 'level_type': 'SUPPORT'})
    assert levels_response.status_code == 200
    level_items = levels_response.json()['data']
    assert level_items
    assert all(item['stock_id'] == stock_id for item in level_items)
    assert all(item['level_type'] == 'SUPPORT' for item in level_items)

    states_response = client.get('/api/v1/admin/support-states', headers=headers, params={'status': 'TESTING_SUPPORT', 'q': '삼성'})
    assert states_response.status_code == 200
    state_items = states_response.json()['data']
    assert state_items
    assert all(item['status'] == 'TESTING_SUPPORT' for item in state_items)
    assert all('삼성' in item['stock_name'] or '삼성' in item['stock_code'] for item in state_items)
