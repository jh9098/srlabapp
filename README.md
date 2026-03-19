# srlabapp

지지저항Lab MVP 저장소입니다.

이번 단계에서는 **기존 backend_api를 기준으로 Flutter MVP 핵심 화면과 API 연동**을 추가했습니다.

## 저장소 구조

```text
/docs
/backend_api
/lib
/test
```

- `docs`: 제품/화면/API/운영 명세 문서
- `backend_api`: FastAPI 백엔드
- `lib`: Flutter 앱 본체
- `test`: Flutter 테스트

---

## 이번 작업에서 구현한 Flutter MVP 범위

### 화면
- 홈
- 관심종목
- 종목 검색
- 종목 상세
- 테마
- 쇼츠(외부 콘텐츠 링크 최소 버전)
- 마이(최소 버전)

### 하단 탭
- 홈
- 관심종목
- 테마
- 쇼츠
- 마이

### 공통 UI 컴포넌트
- stock card
- status badge
- loading state
- empty state
- error state

### API 연동
- `GET /api/v1/home`
- `GET /api/v1/stocks/search`
- `GET /api/v1/stocks/{stock_code}`
- `GET /api/v1/watchlist`
- `POST /api/v1/watchlist`
- `DELETE /api/v1/watchlist/{watchlist_id}`
- `PATCH /api/v1/watchlist/{watchlist_id}/alert`
- `GET /api/v1/themes`

---

## 앱 실행 방법

## 1) backend_api 실행

```bash
cd backend_api
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

기본 주소 예시:

- API: `http://127.0.0.1:8000/api/v1`
- Swagger: `http://127.0.0.1:8000/docs`

## 2) Flutter 의존성 설치

저장소 루트에서:

```bash
flutter pub get
```

## 3) Flutter 앱 실행

에뮬레이터/시뮬레이터 또는 웹에서 다음처럼 실행합니다.

### 모바일/데스크톱 기본 예시

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### Android 에뮬레이터 예시

Android 에뮬레이터에서는 호스트 머신의 localhost 대신 `10.0.2.2`를 사용해야 할 수 있습니다.

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

### Chrome 실행 예시

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=USER_IDENTIFIER=demo-user
```

---

## 비전공자 기준으로 쉽게 설명한 앱 구조

### `lib/core`
앱 전체에서 같이 쓰는 공용 부품입니다.

- `config`: API 주소, 사용자 식별자 같은 앱 설정
- `network`: HTTP 통신과 에러 처리
- `theme`: 앱 색상/기본 테마
- `widgets`: 공통 UI 컴포넌트
- `utils`: 숫자 포맷 같은 작은 도우미

### `lib/features`
실제 기능별로 폴더를 나눈 구조입니다.

- `home`: 홈 화면 관련 코드
- `watchlist`: 관심종목 관련 코드
- `stock`: 종목 검색/상세 관련 코드
- `theme`: 테마 관련 코드
- `shorts`: 쇼츠 탭 최소 버전
- `my`: 마이 탭 최소 버전
- `shared`: 여러 화면에서 같이 쓰는 모델/컨트롤러
- `app`: 앱 진입점, 하단 탭, 전역 의존성

이렇게 나누면 파일이 너무 길어질 때 기능별로 분리해서 유지보수하기 쉬워집니다.

---

## 현재 동작하는 핵심 사용자 흐름

1. 홈에서 오늘의 관찰 종목과 테마를 확인
2. 관심종목 탭에서 내 종목 상태를 요약 확인
3. 종목 검색에서 종목명/코드로 검색
4. 검색 결과에서 관심종목 추가/삭제
5. 종목 상세에서 가격, 상태 배지, 지지선/저항선, 시나리오, 해설 3줄 확인
6. 관심종목 알림 토글 ON/OFF 변경

---

## 이번 단계에서 아직 미완성인 부분

- 알림함 화면
- FCM 푸시 수신
- 내부 영상 플레이어
- 고급 차트 UI
- 최근 본 종목 저장
- 마이 페이지의 상세 설정 화면
- 쇼츠 전용 API 기반 목록

---

## 참고 메모

- 현재 관심종목 API는 `X-User-Identifier` 헤더가 필요합니다.
- Flutter 앱은 `USER_IDENTIFIER` 값을 헤더로 보내도록 구현되어 있습니다.
- MVP 목적에 맞춰 UI는 화려함보다 **빠른 상태 확인**에 집중했습니다.
- Cloud Firestore는 이 저장소에서 사용하지 않았습니다. 따라서 이번 작업으로 인한 Firestore 읽기 비용 증가는 없습니다.
