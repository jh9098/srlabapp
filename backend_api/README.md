# backend_api

지지저항Lab MVP용 FastAPI 백엔드입니다.

## 실행

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --no-build-isolation -e .
cp .env.example .env
alembic upgrade head
python scripts/seed_minimum_data.py
uvicorn app.main:app --reload
```

## 주요 API

### 앱 API
- `GET /api/v1/home`
- `GET /api/v1/stocks/search`
- `GET /api/v1/stocks/{stock_code}`
- `GET /api/v1/stocks/{stock_code}/signals`
- `GET /api/v1/watchlist`
- `POST /api/v1/watchlist`
- `DELETE /api/v1/watchlist/{watchlist_id}`
- `PATCH /api/v1/watchlist/{watchlist_id}/alert`
- `GET /api/v1/themes`
- `GET /api/v1/notifications`
- `PATCH /api/v1/notifications/{notification_id}/read`
- `GET /api/v1/me/alert-settings`
- `PATCH /api/v1/me/alert-settings`
- `POST /api/v1/me/device-tokens`

### 관리자 API
- `POST /api/v1/admin/auth/login`
- `GET /api/v1/admin/auth/me`
- `GET /api/v1/admin/dashboard`
- `GET/POST/PUT /api/v1/admin/stocks`
- `GET/POST/PUT /api/v1/admin/price-levels`
- `GET /api/v1/admin/support-states`
- `PATCH /api/v1/admin/support-states/{state_id}/force`
- `GET /api/v1/admin/signal-events`
- `GET/PUT /api/v1/admin/home-featured`
- `GET/POST/PUT /api/v1/admin/themes`
- `GET /api/v1/admin/audit-logs`
- `POST /api/v1/admin/manual-push`

## 관리자 인증

기본 로컬 계정은 환경변수 기반입니다.

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin1234
```

로그인 성공 시 서명 토큰을 발급하고,
이후 관리자 API는 아래 형식의 헤더를 요구합니다.

```text
Authorization: Bearer <token>
```

## FCM / 푸시

- 디바이스 토큰은 `POST /api/v1/me/device-tokens` 로 등록합니다.
- `signal_events` 가 생성되면 `notifications` 저장을 유지합니다.
- `FCM_ENABLED=true` 와 `FCM_SERVER_KEY` 가 설정되면 실제 HTTP 전송을 시도합니다.
- 설정이 없으면 DB 저장 + 로그 fallback 으로 동작합니다.

## 테스트

```bash
pytest tests -q
```
