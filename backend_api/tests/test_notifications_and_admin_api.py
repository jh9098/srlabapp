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


import pytest
from sqlalchemy import select

from app.api.v1.admin import get_admin_firestore_client
from app.main import app
from app.models.admin_audit_log import AdminAuditLog
from app.models.device_token import DeviceToken
from app.models.home_featured_stock import HomeFeaturedStock
from app.models.enums import NotificationDeliveryStatus
from app.models.notification import Notification
from app.models.stock import Stock
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


class FakeAlreadyExists(Exception):
    pass


class FakeFirestoreDocument:
    def __init__(self, store: dict[str, dict], doc_id: str, should_fail_on_write: bool = False) -> None:
        self.store = store
        self.doc_id = doc_id
        self.should_fail_on_write = should_fail_on_write

    def create(self, payload):
        if self.should_fail_on_write:
            raise RuntimeError("firestore write failed")
        if self.doc_id in self.store:
            raise FakeAlreadyExists()
        self.store[self.doc_id] = dict(payload)

    def set(self, payload, merge=False):
        if self.should_fail_on_write:
            raise RuntimeError("firestore write failed")
        current = self.store.get(self.doc_id, {}) if merge else {}
        current.update(payload)
        self.store[self.doc_id] = current


class FakeFirestoreCollection:
    def __init__(self, store: dict[str, dict], should_fail_on_write: bool = False) -> None:
        self.store = store
        self.should_fail_on_write = should_fail_on_write

    def document(self, doc_id: str) -> FakeFirestoreDocument:
        return FakeFirestoreDocument(self.store, doc_id, self.should_fail_on_write)


class FakeFirestoreClient:
    def __init__(self, *, should_fail_on_write: bool = False) -> None:
        self.collections: dict[str, dict[str, dict]] = {}
        self.should_fail_on_write = should_fail_on_write

    def collection(self, name: str) -> FakeFirestoreCollection:
        store = self.collections.setdefault(name, {})
        return FakeFirestoreCollection(store, self.should_fail_on_write)


@pytest.fixture(autouse=True)
def firestore_client():
    client = FakeFirestoreClient()
    original_overrides = dict(app.dependency_overrides)
    app.dependency_overrides[get_admin_firestore_client] = lambda: client
    try:
        yield client
    finally:
        app.dependency_overrides.clear()
        app.dependency_overrides.update(original_overrides)


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


def test_admin_home_featured_summary_prefers_operator_comment(client):
    headers = admin_auth_headers(client)

    stocks_response = client.get('/api/v1/admin/stocks', headers=headers, params={'q': '삼성전자'})
    assert stocks_response.status_code == 200
    stock = stocks_response.json()['data'][0]

    stock_update_response = client.put(
        f"/api/v1/admin/stocks/{stock['id']}",
        headers=headers,
        json={
            'code': stock['code'],
            'name': stock['name'],
            'market_type': stock['market_type'],
            'sector': stock['sector'],
            'theme_tags': stock['theme_tags'],
            'operator_memo': '운영자 코멘트 우선 노출',
            'is_active': stock['is_active'],
        },
    )
    assert stock_update_response.status_code == 200

    level_response = client.get(
        '/api/v1/admin/price-levels',
        headers=headers,
        params={'stock_id': stock['id'], 'level_type': 'SUPPORT'},
    )
    assert level_response.status_code == 200
    admin_home_level = next((item for item in level_response.json()['data'] if item['source_label'] == 'admin_home'), None)

    level_payload = {
        'stock_id': stock['id'],
        'level_type': 'SUPPORT',
        'price': admin_home_level['price'] if admin_home_level else '65200',
        'proximity_threshold_pct': admin_home_level['proximity_threshold_pct'] if admin_home_level else '1.50',
        'rebound_threshold_pct': admin_home_level['rebound_threshold_pct'] if admin_home_level else '5.00',
        'source_label': 'admin_home',
        'note': '레벨 메모 fallback',
        'is_active': True,
    }
    if admin_home_level:
        upsert_level_response = client.put(
            f"/api/v1/admin/price-levels/{admin_home_level['id']}",
            headers=headers,
            json=level_payload,
        )
    else:
        upsert_level_response = client.post('/api/v1/admin/price-levels', headers=headers, json=level_payload)
    assert upsert_level_response.status_code == 200

    featured_response = client.put(
        '/api/v1/admin/home-featured',
        headers=headers,
        json={'items': [{'stock_id': stock['id'], 'display_order': 1, 'is_active': True}]},
    )
    assert featured_response.status_code == 200

    home_response = client.get('/api/v1/home')
    assert home_response.status_code == 200
    featured_items = home_response.json()['data']['featured_stocks']
    samsung = next(item for item in featured_items if item['stock_code'] == stock['code'])
    assert samsung['summary'] == '운영자 코멘트 우선 노출'


@pytest.fixture(autouse=True)
def firebase_writer_monkeypatch(monkeypatch):
    monkeypatch.setattr(
        'app.services.firebase_watchlist_writer.get_firestore_server_timestamp',
        lambda: 'SERVER_TIMESTAMP',
    )
    monkeypatch.setattr(
        'app.services.firebase_watchlist_writer.get_firestore_already_exists_exception',
        lambda: FakeAlreadyExists,
    )


def test_admin_stock_and_level_save_syncs_watchlist_to_firebase(
    client,
    firestore_client,
):
    headers = admin_auth_headers(client)

    create_stock = client.post(
        '/api/v1/admin/stocks',
        headers=headers,
        json={
            'code': '123456',
            'name': '테스트종목',
            'market_type': 'KOSPI',
            'sector': '반도체',
            'theme_tags': '테스트',
            'operator_memo': '단기 지지 확인 구간',
            'is_active': True,
        },
    )
    assert create_stock.status_code == 200
    stock_id = create_stock.json()['data']['id']

    save_level = client.post(
        '/api/v1/admin/price-levels',
        headers=headers,
        json={
            'stock_id': stock_id,
            'level_type': 'SUPPORT',
            'price': '66100',
            'source_label': 'admin_home',
            'note': '대표 지지선',
            'is_active': True,
        },
    )
    assert save_level.status_code == 200

    feature_home = client.put(
        '/api/v1/admin/home-featured',
        headers=headers,
        json={'items': [{'stock_id': stock_id, 'display_order': 1, 'is_active': True}]},
    )
    assert feature_home.status_code == 200

    watchlist_doc = firestore_client.collections['adminWatchlist']['123456']
    assert watchlist_doc['ticker'] == '123456'
    assert watchlist_doc['name'] == '테스트종목'
    assert watchlist_doc['supportLines'] == [66100]
    assert watchlist_doc['comment'] == '단기 지지 확인 구간'
    assert watchlist_doc['isActive'] is True
    assert watchlist_doc['isHomeFeatured'] is True
    assert watchlist_doc['source'] == 'app_admin'


def test_admin_stock_save_rolls_back_when_firebase_write_fails(client, db_session, monkeypatch):
    failing_client = FakeFirestoreClient(should_fail_on_write=True)
    monkeypatch.setattr(
        'app.services.firebase_watchlist_writer.get_firestore_server_timestamp',
        lambda: 'SERVER_TIMESTAMP',
    )
    monkeypatch.setattr(
        'app.services.firebase_watchlist_writer.get_firestore_already_exists_exception',
        lambda: FakeAlreadyExists,
    )
    original_overrides = dict(app.dependency_overrides)
    app.dependency_overrides[get_admin_firestore_client] = lambda: failing_client
    try:
        headers = admin_auth_headers(client)
        response = client.post(
            '/api/v1/admin/stocks',
            headers=headers,
            json={
                'code': '654321',
                'name': '실패종목',
                'market_type': 'KOSDAQ',
                'operator_memo': '실패 테스트',
                'is_active': True,
            },
        )
    finally:
        app.dependency_overrides.clear()
        app.dependency_overrides.update(original_overrides)

    assert response.status_code == 503
    assert response.json()['error_code'] == 'FIREBASE_WATCHLIST_WRITE_FAILED'
    assert db_session.scalar(select(Stock).where(Stock.code == '654321')) is None
    assert not failing_client.collections.get('adminWatchlist')
    assert not list(db_session.scalars(select(AdminAuditLog).where(AdminAuditLog.action == 'upsert_stock')))


def test_home_exclusion_soft_disables_firebase_home_flag(
    client,
    db_session,
    firestore_client,
):
    headers = admin_auth_headers(client)
    stock = db_session.scalar(select(Stock).where(Stock.code == '005930'))
    assert stock is not None

    initial_feature = client.put(
        '/api/v1/admin/home-featured',
        headers=headers,
        json={'items': [{'stock_id': stock.id, 'display_order': 1, 'is_active': True}]},
    )
    assert initial_feature.status_code == 200

    remove_from_home = client.put(
        '/api/v1/admin/home-featured',
        headers=headers,
        json={'items': []},
    )
    assert remove_from_home.status_code == 200

    watchlist_doc = firestore_client.collections['adminWatchlist'][stock.code]
    assert watchlist_doc['isHomeFeatured'] is False
    assert watchlist_doc['isActive'] is True

    home_featured_row = db_session.scalar(select(HomeFeaturedStock).where(HomeFeaturedStock.stock_id == stock.id))
    assert home_featured_row is not None
    assert home_featured_row.is_active is False
