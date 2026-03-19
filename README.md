# srlabapp

지지저항Lab MVP 저장소입니다.

이번 단계에서는 **새 기능 추가보다 현재 구현본의 안정화/정합성 수정**에 집중했습니다.

## 1. 현재 실제 저장소 구조

```text
/docs
/backend_api
/admin_web
/lib
/android
/ios
/macos
/linux
/windows
/web
/test
/pubspec.yaml
```

- `docs`: 제품/상태로직/API/운영 명세 문서
- `backend_api`: FastAPI 백엔드, 상태 엔진, 관리자/알림 API
- `admin_web`: 운영 검수용 최소 정적 관리자 화면
- `lib` 이하: 현재 Flutter 앱 본체
- `test`: Flutter 위젯 테스트
- `pubspec.yaml`: 루트 Flutter 앱 패키지 정의 파일

> 문서 권장 구조는 `frontend_app/` 이지만, 실제 Flutter 앱은 이전 단계 구현을 이어 받아 **저장소 루트**에 있습니다. 이 차이는 `TODO_MVP_GAPS.md`에 명시했습니다.

---

## 2. 이번 안정화 작업에서 정리한 범위

### 2-1. support state engine 안정화
- `PriceLevel.proximity_threshold_pct` 또는 `rebound_threshold_pct` 가 `None`이어도 `Decimal(None)` 예외가 나지 않도록 수정했습니다.
- 값이 비어 있으면 기본 엔진 설정값(`support_near_pct=1.50`, `rebound_success_pct=5.00`)으로 fallback 되도록 정리했습니다.
- 메모리 객체(`PriceLevel(...)`) 기반 테스트도 통과하도록 보강했습니다.

### 2-2. 테스트/API 규약 정합성 수정
- Home API 테스트 헤더를 실제 규약인 `X-User-Identifier` 로 수정했습니다.
- `backend_api/tests` 가 외부 `httpx` 패키지 유무에 덜 민감하도록 경량 ASGI 테스트 클라이언트로 정리했습니다.
- support state / home / signals / themes / notifications / admin / watchlist 테스트를 전체 기준으로 다시 확인했습니다.

### 2-3. 문서/패키징 상태 점검
- 루트 `README.md`, `TODO_MVP_GAPS.md`, `pubspec.yaml`, `backend_api/.env.example` 실제 존재 여부를 확인했습니다.
- 저장소 루트 Flutter 구조와 문서 권장 구조(`frontend_app/`) 차이를 README/TODO에 명시했습니다.
- zip 산출물 기준으로 실행에 필요한 핵심 파일이 누락되지 않았는지 재점검했습니다.

---

## 3. backend_api 실행 방법

```bash
cd backend_api
python3 -m venv .venv
source .venv/bin/activate
pip install -e .[test]
cp .env.example .env
alembic upgrade head
python scripts/seed_minimum_data.py
uvicorn app.main:app --reload
```

기본 주소 예시:
- API: `http://127.0.0.1:8000/api/v1`
- Swagger: `http://127.0.0.1:8000/docs`

### backend_api 테스트 방법

`backend_api` 폴더 안에서 실행:

```bash
cd backend_api
pytest tests -q
```

저장소 루트에서 바로 실행:

```bash
pytest backend_api/tests -q
```

---

## 4. Flutter 앱 실행 방법

Flutter 앱은 현재 `frontend_app/` 폴더가 아니라 저장소 루트에 있습니다.

### 의존성 설치

```bash
flutter pub get
```

### 실행 예시

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### Android 에뮬레이터 예시

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### Chrome 예시

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### Flutter 테스트

```bash
flutter test
```

---

## 5. admin_web 실행 방법

정적 HTML 기반 관리자입니다.

```bash
cd admin_web
python3 -m http.server 4173
```

브라우저에서 `http://127.0.0.1:4173` 접속 후:
- `API Base URL`에 `http://127.0.0.1:8000/api/v1` 입력
- `Admin Identifier`는 기본값(`admin-local`) 또는 원하는 운영자 식별자 사용

---

## 6. 실제 검수 순서 권장

가장 빠른 로컬 검수 순서는 아래와 같습니다.

1. `backend_api` 의존성 설치
2. DB 마이그레이션 적용
3. 최소 seed 데이터 적재
4. 백엔드 테스트 실행
5. 백엔드 서버 실행
6. Flutter 앱 실행
7. 별도 터미널에서 `admin_web` 정적 서버 실행

예시:

```bash
cd backend_api
python3 -m venv .venv
source .venv/bin/activate
pip install -e .[test]
cp .env.example .env
alembic upgrade head
python scripts/seed_minimum_data.py
pytest tests -q
uvicorn app.main:app --reload
```

다른 터미널 예시:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

```bash
cd admin_web
python3 -m http.server 4173
```

---

## 7. 환경변수 예시

### backend_api/.env.example

```env
APP_NAME=지지저항Lab Backend API
APP_ENV=local
APP_DEBUG=true
API_V1_PREFIX=/api/v1
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/srlab
```

### Flutter 실행 시 dart-define 예시

```bash
--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
--dart-define=USER_IDENTIFIER=demo-user
```

---

## 8. 비전공자 기준으로 쉽게 설명한 구조

### 백엔드 알림 구조
1. `signal_event`가 생기면
2. 해당 종목을 관심종목으로 등록한 사용자를 찾고
3. 사용자 알림 설정을 확인한 뒤
4. `notifications` 테이블에 앱 알림 이력을 저장합니다.
5. 그 다음 `PushProvider`를 통해 실제 푸시를 보낼 수 있는 구조로 연결합니다.

즉, **알림 저장**과 **실제 푸시 발송**을 분리했습니다. 그래서 나중에 FCM을 붙여도 기존 알림함 구조를 크게 바꾸지 않아도 됩니다.

### 관리자 로그 구조
운영자가 종목/가격 레벨/상태/홈 노출/테마/수동 푸시를 건드리면 `admin_audit_logs`에 누가 무엇을 바꿨는지 남도록 했습니다.

---

## 9. 현재 남아있는 미완성/주의 항목

아래는 숨기지 않고 명확하게 남깁니다.

1. `frontend_app/` 권장 구조와 실제 루트 Flutter 구조가 다릅니다.
2. 실제 FCM 연동은 아직 하지 않았고, 현재는 교체 가능한 골격만 구현했습니다.
3. 관리자 인증은 정식 로그인 방식이 아니라 헤더 기반 최소 운영 형태입니다.
4. 관리자 UI는 고급 디자인보다 운영 기능 우선의 정적 관리자입니다.
5. 프로덕션 배포 전에는 실제 푸시 provider 연결, 관리자 인증/권한, HTTPS/CORS/배포 설정, 에러 모니터링이 추가로 필요합니다.

자세한 목록은 `TODO_MVP_GAPS.md`를 참고하세요.

---

## 10. Cloud Firestore 읽기 비용 검토

이 저장소의 이번 구현은 **Cloud Firestore를 사용하지 않습니다.**
따라서 이번 변경으로 인해 **Firestore document read 비용 증가는 0건**입니다.

다만 나중에 FCM 토큰이나 알림함을 Firestore로 옮기면, 앱 시작 시 알림함 실시간 구독 구조는 읽기 비용이 커질 수 있으므로 지금처럼 **서버 DB(PostgreSQL) 중심 구조**를 유지하는 편이 MVP 운영 비용 측면에서 유리합니다.
