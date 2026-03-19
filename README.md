# 지지저항Lab 로컬 MVP 완료판 가이드

이 저장소는 **지지저항Lab 모바일 앱의 로컬 실행/검수 가능한 MVP 완료판**입니다.

중요한 점은 아래 두 가지입니다.

1. 이 저장소의 목표는 **프로덕션 배포 완료**가 아닙니다.
2. 현재 기준 목표는 **로컬에서 백엔드 + Flutter 앱 + 관리자 웹을 실제로 실행하고 검수할 수 있는 상태**입니다.

즉, 지금은 “더 만들기”보다 **코드/문서/실행 흐름을 하나로 맞춘 마지막 마감판**으로 이해하면 됩니다.

---

## 1. 전체 저장소 구조

현재 저장소의 **실제 최종 구조**는 아래와 같습니다.

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

구성 설명:

- `docs`: 제품 개요, 화면 흐름, 상태 엔진, DB/API, 운영, 개발 체크리스트 문서
- `backend_api`: FastAPI 백엔드, SQLAlchemy 모델, Alembic 마이그레이션, 상태 엔진, 앱/관리자 API
- `admin_web`: 로컬 운영 검수용 관리자 웹 화면
- 루트 Flutter 앱:
  - `lib`: Flutter 앱 코드
  - `android`, `ios`, `macos`, `linux`, `windows`, `web`: Flutter 플랫폼 프로젝트
  - `test`: Flutter 테스트
  - `pubspec.yaml`: Flutter 패키지 설정

> 문서 초안에는 `frontend_app/` 예시가 있었지만, 현재 저장소는 **루트 Flutter 구조를 최종 구조로 확정**했습니다.

---

## 2. 로컬 MVP에서 실제로 완료된 범위

이번 마감에서 정리된 핵심은 아래입니다.

### 2-1. 관리자 인증 마무리
이제 관리자 API는 `X-Admin-Identifier` 임시 헤더에만 의존하지 않습니다.

현재 방식:
- `ADMIN_USERNAME`, `ADMIN_PASSWORD` 환경변수 기반 로그인
- 로그인 성공 시 **서명 토큰(Bearer Token)** 발급
- 관리자 전용 API는 해당 토큰을 요구
- `admin_web` 에서 로그인 화면 → 토큰 저장 → 요청 자동 적용

### 2-2. 푸시/FCM 코드 기준 완료
현재 저장소 안에는 아래가 포함됩니다.

- 디바이스 토큰 등록 API
- 사용자/디바이스 토큰 저장 구조
- `signal_events` → `notifications` 저장 연동
- FCM 전송 provider
- FCM 설정이 있으면 실제 HTTP 전송 시도
- FCM 설정이 없으면 **DB 저장 + 로그 fallback**
- Flutter 쪽 `firebase_messaging` 연동 코드 및 토큰 등록 흐름

즉, **코드는 연동 가능 상태**이고,
실제 Firebase 콘솔/앱 등록/운영 키 입력만 외부 수동 단계로 남습니다.

### 2-3. 구조 불일치 정리
- Flutter 앱은 `frontend_app/`로 옮기지 않았습니다.
- 대신 **현재 루트 구조를 최종 구조로 채택**했습니다.
- `README.md`, `TODO_MVP_GAPS.md`, `AGENTS.md`, `docs/07...`를 모두 이 기준으로 정리했습니다.

### 2-4. 로컬 MVP와 프로덕션 준비 분리
이제 문서에서 아래를 분리해서 봅니다.

- **로컬 MVP 완료 항목**: 지금 바로 실행/검수 가능한 범위
- **외부 설정/프로덕션 준비 항목**: Firebase 콘솔, 스토어 배포, HTTPS, 운영 인프라 등

---

## 3. backend_api 실행 방법

### 3-1. 권장 환경
- Python 3.10+
- PostgreSQL

### 3-2. 실행 순서

```bash
cd backend_api
python3 -m venv .venv
source .venv/bin/activate
pip install --no-build-isolation -e .
cp .env.example .env
alembic upgrade head
python scripts/seed_minimum_data.py
uvicorn app.main:app --reload
```

기본 주소:
- API: `http://127.0.0.1:8000/api/v1`
- Swagger: `http://127.0.0.1:8000/docs`

### 3-3. 주요 환경변수

`backend_api/.env.example` 기준:

```env
APP_NAME=지지저항Lab Backend API
APP_ENV=local
APP_DEBUG=true
API_V1_PREFIX=/api/v1
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/srlab

ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin1234
ADMIN_JWT_SECRET=change-me-local-admin-secret
ADMIN_TOKEN_EXPIRE_MINUTES=480

FCM_ENABLED=false
# FCM_SERVER_KEY=your-fcm-server-key
# FCM_PROJECT_ID=your-firebase-project-id
```

---

## 4. backend_api 테스트 방법

`backend_api` 폴더에서 실행:

```bash
cd backend_api
pytest tests -q
```

이 테스트는 아래 핵심 흐름을 검증합니다.

- support state engine
- home / stocks / watchlist / notifications API
- 관리자 로그인 / 관리자 API
- 디바이스 토큰 등록 API

---

## 5. Flutter 실행 방법

Flutter 앱은 `frontend_app/` 폴더가 아니라 **저장소 루트**에 있습니다.

### 5-1. 의존성 설치

```bash
flutter pub get
```

### 5-2. 기본 실행

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### 5-3. Android 에뮬레이터 실행 예시

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### 5-4. Chrome 실행 예시

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### 5-5. Firebase/FCM 옵션까지 같이 넘기는 예시

아래 값은 **Firebase 콘솔에서 직접 확인한 실제 값**으로 바꿔야 합니다.

```bash
flutter run \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
  --dart-define=USER_IDENTIFIER=demo-user \
  --dart-define=FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=FIREBASE_API_KEY=your-api-key \
  --dart-define=FIREBASE_APP_ID=your-app-id \
  --dart-define=FIREBASE_ANDROID_APP_ID=your-android-app-id \
  --dart-define=FIREBASE_WEB_APP_ID=your-web-app-id \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id \
  --dart-define=FIREBASE_WEB_VAPID_KEY=your-web-vapid-key
```

설정이 비어 있으면 앱은 푸시 초기화를 **건너뛰고 계속 실행**됩니다.

---

## 6. admin_web 실행 방법

관리자 웹은 정적 HTML/JS 기반입니다.

```bash
cd admin_web
python3 -m http.server 4173
```

브라우저에서 아래 주소로 접속합니다.

```text
http://127.0.0.1:4173
```

기능:
- 관리자 로그인
- 관리자 세션 확인
- 대시보드 요약 확인
- 종목/가격레벨/지지상태/이벤트/홈노출/테마/감사로그 조회
- 수동 푸시 발송

---

## 7. 관리자 로그인 방법

### 7-1. 로그인 계정
기본 로컬 계정은 아래 환경변수 기준입니다.

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin1234
```

### 7-2. 로그인 흐름
1. `admin_web` 접속
2. `API Base URL` 입력
3. 관리자 아이디/비밀번호 입력
4. 로그인 성공 시 백엔드가 서명 토큰 발급
5. 브라우저 로컬 저장소에 토큰 저장
6. 이후 관리자 API 요청에 `Authorization: Bearer <token>` 자동 포함

### 7-3. 관리자 API 직접 확인 예시

로그인:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/admin/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin1234"}'
```

세션 확인:

```bash
curl http://127.0.0.1:8000/api/v1/admin/auth/me \
  -H 'Authorization: Bearer <발급받은토큰>'
```

---

## 8. 푸시 / FCM 로컬 검증 방법

이번 저장소는 푸시를 아래 2단계로 나눠서 생각하면 쉽습니다.

### 8-1. 저장소 코드 안에서 검증 가능한 부분
- 앱이 FCM 토큰을 받는다.
- 앱이 백엔드의 `/api/v1/me/device-tokens` 로 토큰을 등록한다.
- 백엔드가 `device_tokens` 에 저장한다.
- `signal_events` 또는 수동 푸시가 `notifications` 에 저장된다.
- FCM 설정이 없으면 fallback 로그를 남긴다.
- FCM 설정이 있으면 실제 HTTP 전송을 시도한다.

### 8-2. 가장 쉬운 로컬 검증 순서
1. 백엔드 실행
2. Flutter 앱 실행
3. Firebase 설정이 없으면 앱 상단 배너에서 “초기화 건너뜀” 메시지 확인
4. Firebase 설정이 있으면 디바이스 토큰 등록 API 호출 확인
5. 관리자 웹에서 수동 푸시 발송
6. 백엔드 DB의 `notifications` 저장 여부 확인
7. FCM 설정까지 완료했다면 실기기/브라우저 수신 확인

### 8-3. 백엔드만 기준으로 토큰 등록 API 확인 예시

```bash
curl -X POST http://127.0.0.1:8000/api/v1/me/device-tokens \
  -H 'Content-Type: application/json' \
  -H 'X-User-Identifier: demo-user' \
  -d '{
    "device_token":"test-fcm-token",
    "platform":"android",
    "provider":"fcm",
    "device_label":"local-test"
  }'
```

### 8-4. FCM fallback 동작 설명
- `FCM_ENABLED=false` 이거나
- `FCM_SERVER_KEY` 가 없으면

백엔드는 **실패로 중단하지 않고** 다음처럼 동작합니다.

1. `notifications` 저장 유지
2. `device_tokens` 는 유지
3. 로그에 “FCM 설정이 없어 DB 저장만 수행” 메시지 기록

즉, 로컬 MVP 검수는 Firebase 콘솔이 없어도 가능합니다.

---

## 9. seed 데이터 주입 방법

최소 검수용 데이터는 아래 스크립트로 넣습니다.

```bash
cd backend_api
python scripts/seed_minimum_data.py
```

이 스크립트는 예시 종목/레벨/상태/테마/관심종목/알림/디바이스 토큰 데이터를 넣어,
처음 실행 후 바로 화면과 API를 검수할 수 있게 해줍니다.

---

## 10. 로컬 MVP 검수 순서

README 하나만 보고 따라할 수 있게 가장 추천하는 순서를 정리하면 아래와 같습니다.

### 10-1. 1단계: 백엔드 준비

```bash
cd backend_api
python3 -m venv .venv
source .venv/bin/activate
pip install --no-build-isolation -e .
cp .env.example .env
alembic upgrade head
python scripts/seed_minimum_data.py
pytest tests -q
uvicorn app.main:app --reload
```

### 10-2. 2단계: 관리자 웹 실행

다른 터미널에서:

```bash
cd admin_web
python3 -m http.server 4173
```

### 10-3. 3단계: Flutter 앱 실행

또 다른 터미널에서:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### 10-4. 4단계: 실제 검수 포인트
1. Flutter 홈 진입
2. 관심종목 목록 확인
3. 종목 검색 → 관심종목 추가
4. 종목 상세에서 지지/저항/상태 확인
5. 알림함 확인
6. 관리자 웹 로그인
7. 관리자 대시보드/종목/레벨/상태/이벤트 확인
8. 관리자 웹에서 수동 푸시 발송
9. 알림 저장 여부 확인
10. Firebase 설정을 넣었다면 토큰 등록 및 실제 수신 확인

---

## 11. 외부 수동 설정이 필요한 항목

아래는 **기능 미완성**이 아니라 **저장소 밖에서 따로 해야 하는 작업**입니다.

### 11-1. Firebase / FCM
- Firebase 프로젝트 생성
- Android / iOS / Web 앱 등록
- 앱 식별자/키/앱 ID 확인
- `FIREBASE_*` dart-define 값 입력
- 서버의 `FCM_SERVER_KEY` 입력
- 실제 디바이스 권한 허용 및 수신 테스트

### 11-2. 운영/배포
- 운영 PostgreSQL 준비
- HTTPS / reverse proxy / CORS 정책 정리
- 에러 모니터링 / 로그 수집
- 앱 릴리즈 빌드 및 스토어 배포
- 관리자 접근 정책 강화

---

## 12. 현재 TODO 문서 해석 방법

`TODO_MVP_GAPS.md`는 이제 아래 두 범주로 분리되어 있습니다.

1. **로컬 MVP 기준 이미 완료된 것**: 더 이상 TODO에 두지 않음
2. **진짜 남은 것**:
   - 외부 자격증명
   - Firebase 콘솔/실기기 연결
   - 운영 인프라
   - 스토어 배포

즉, TODO 문서를 읽었을 때 “기능이 덜 만들어졌는지”, “외부 설정만 남았는지”가 헷갈리지 않도록 정리했습니다.

---

## 13. 현재 상태 최종 판단

### 로컬 MVP 완료 여부
**예, 현재 저장소는 로컬 MVP 완료판으로 판단합니다.**

이 판단의 기준은 아래입니다.

- 핵심 백엔드 API 동작
- 상태 엔진 테스트 통과
- 관리자 로그인 및 운영 API 사용 가능
- 알림 저장 및 디바이스 토큰 등록 가능
- FCM 코드 경로 구현 완료
- Firebase 미설정 시 graceful fallback 존재
- Flutter/관리자/백엔드의 로컬 실행 흐름이 문서화됨

### 아직 남은 것은 무엇인가?
현재 남은 것은 주로 아래입니다.

- **기능 미완성**: 사실상 핵심 MVP 범위에서는 정리 완료로 봄
- **외부 설정 필요**:
  - Firebase 콘솔 연결
  - 실제 운영 자격증명 입력
  - 스토어/운영 배포

---

## 14. Cloud Firestore 읽기 비용 검토

이번 저장소와 이번 변경은 **Cloud Firestore를 사용하지 않습니다.**
따라서 이번 작업으로 인한 **Cloud Firestore document read 비용 증가는 0건**입니다.

또한 이번 푸시/알림 구조는 Firestore 실시간 구독이 아니라,
**백엔드 DB(PostgreSQL) + API 조회 방식**이라서 Firestore 읽기 소모를 유발하지 않습니다.

즉, 현재 구조는 Firestore 비용 측면에서도 안전합니다.
