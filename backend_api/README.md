# backend_api

지지저항Lab MVP용 FastAPI 백엔드입니다.

## 실행

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
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

## 테스트

```bash
pytest
```
