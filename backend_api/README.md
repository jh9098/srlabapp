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
python scripts/check_release_readiness.py
uvicorn app.main:app --reload
```

## 환경변수 / 환경분리

backend 설정은 `app/core/config.py` 의 `Settings` 에서 읽습니다.

핵심 값:

- `APP_ENV=dev|staging|prod`
- `DATABASE_URL`
- `SECRET_KEY`
- `ADMIN_USERNAME`
- `ADMIN_PASSWORD`
- `ADMIN_JWT_SECRET`
- `CORS_ORIGINS`
- `CORS_ORIGIN_REGEX`
- `SCHEDULER_ENABLED`
- `SIGNAL_BATCH_ENABLED`
- `PUSH_ENABLED`
- `FCM_*`

예시는 `backend_api/.env.example` 를 참고하세요.

주의:
- `backend_api/.env` 는 로컬 전용 파일입니다. 저장소 공유 산출물에는 포함하지 않습니다.
- 협업/배포 문서 기준으로는 `.env.example` 만 유지합니다.

## Health Check

- `GET /health`
- `GET /api/v1/health`

응답에는 아래가 포함됩니다.

- `status`
- `environment`
- `version`
- `database`
- `scheduler_enabled`
- `signal_batch_enabled`
- `push_enabled`

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

관리자 계정은 환경변수 기반 bootstrap 방식입니다.

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=replace-with-admin-password
ADMIN_JWT_SECRET=replace-with-admin-jwt-secret
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

## 신호 자동 생성 배치

저장된 `daily_bars` 최신 종가와 활성 `price_levels` 를 기준으로 아래 4가지 이벤트를 자동 생성합니다.

- `support_near` (`SignalType.SUPPORT_NEAR`)
- `support_break` (`SignalType.SUPPORT_INVALIDATED` 로 저장)
- `resistance_near` (`SignalType.RESISTANCE_NEAR`)
- `resistance_breakout` (`SignalType.RESISTANCE_BREAKOUT`)

실행 예시:

```bash
python -m app.tasks.run_signal_monitor --dry-run
python -m app.tasks.run_signal_monitor
python -m app.tasks.run_notification_dispatcher --limit 50 --max-retry-count 3
```

동작 요약:

- 종목별 최신 `daily_bars` 1건과 활성 레벨만 검사
- 레벨별 `proximity_threshold_pct` 가 있으면 우선 사용, 없으면 기본 허용오차 `1.00%` 사용
- 동일 종목 + 동일 레벨 + 동일 이벤트 타입 + 동일 날짜는 `signal_key` 및 날짜 조건으로 중복 생성 방지
- `signal_event` 생성 후 관심종목 + 알림 허용 사용자 기준으로 `notifications` 후보 레코드를 생성
- 배치에서는 `dispatch_push=False` 로 동작하므로 실제 푸시는 보내지 않고 DB 후보만 적재
- 일부 종목에서 오류가 나더라도 rollback 후 다음 종목 처리를 계속 진행

## 테스트

```bash
pytest -q
python scripts/check_release_readiness.py
```
