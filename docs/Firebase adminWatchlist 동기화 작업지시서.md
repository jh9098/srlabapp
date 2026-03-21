# SRLAB 앱 관리자 저장 → Firebase adminWatchlist 동기화 작업지시서

## 목적
앱 관리자에서 관심종목을 등록/수정/제외할 때,
기존 로컬 DB 저장만 하지 말고 **Firebase `adminWatchlist`에도 동일하게 반영**되도록 만든다.

이 작업의 목표는 **앱을 메인 운영 입력창**으로 만들고,
기존 지지저항랩 웹의 GitHub Actions는 Firebase `adminWatchlist`를 읽어 가격 크롤링 대상 종목을 결정하게 만드는 것이다.

즉 앞으로의 공용 구조는 아래와 같다.

- 앱 관리자: 관심종목/지지선/코멘트 입력
- 앱 백엔드 DB: 앱 서비스용 즉시 반영 데이터
- Firebase `adminWatchlist`: 웹과 앱이 함께 쓰는 공용 원본 목록
- 웹 GitHub Actions: `adminWatchlist`를 읽어 가격 크롤링
- Firebase `stock_prices`: 크롤링 결과 저장
- 앱 백엔드 sync: `stock_prices`를 다시 읽어 앱 주가 데이터 최신화

---

## 핵심 원칙
겉으로는 "앱도 마스터, 웹도 마스터"처럼 보여도,
실제 원본은 하나여야 한다.

이번 작업에서는 원본을 **Firebase `adminWatchlist`** 로 통일한다.

즉:
- 앱 관리자도 `adminWatchlist`에 쓴다
- 웹 관리자도 필요하면 `adminWatchlist`에 쓸 수 있다
- 웹 크롤러는 `adminWatchlist`를 읽는다
- 앱 백엔드도 필요 시 `adminWatchlist`를 읽는다

앱 DB는 서비스 응답용 저장소이자 캐시로 유지한다.

---

## 확인된 현재 상태
현재 코드 기준으로 아래는 이미 존재한다.

- `app/services/admin_service.py`
  - 종목/지지선/홈관심종목을 로컬 DB에 저장 가능
- `app/services/firebase_sync_service.py`
  - Firebase `adminWatchlist`를 읽어서 로컬 DB로 동기화 가능
- `app/integrations/firebase_admin.py`
  - Firestore client 초기화 가능
- `scripts/sync_firebase_watchlist_prices.py`
  - watchlist/prices/home-featured/full sync 가능

하지만 현재는 **Firebase 읽기만 있고 쓰기는 없다.**
그래서 앱에서 저장한 관심종목이 웹 크롤링 대상에는 자동 반영되지 않는다.

---

## 이번 작업의 목표
아래 3가지를 구현한다.

1. 앱 관리자에서 관심종목 저장 시 Firebase `adminWatchlist/{ticker}` 문서 upsert
2. 앱 관리자에서 관심종목 홈 제외/비활성 처리 시 Firebase에도 `isActive=false` 반영
3. Firebase 쓰기 실패 시 로컬 DB 저장도 롤백하여 **앱 DB와 Firebase가 어긋나지 않게** 유지

---

## 수정 대상 파일
- `backend_api/app/services/admin_service.py`
- `backend_api/app/integrations/firebase_admin.py`
- `backend_api/app/api/v1/admin.py` (필요 시 의존성 주입만 최소 수정)
- `backend_api/tests/` 내 admin 관련 테스트 파일

필요하면 새 파일 추가 가능:
- `backend_api/app/services/firebase_watchlist_writer.py`

권장: Firebase 쓰기 로직은 `AdminService`에 직접 길게 넣지 말고 별도 writer/service로 분리할 것.

---

## 권장 구현 구조

### 1. Firebase writer 서비스 신설
새 파일 예시:
- `app/services/firebase_watchlist_writer.py`

이 서비스는 아래 기능만 담당한다.

- `upsert_watchlist_document(...)`
- `deactivate_watchlist_document(...)`
- `delete_or_soft_disable_watchlist_document(...)` 는 이번 단계에서는 soft disable만 사용

### 2. AdminService에서 저장 완료 직전 Firebase 반영
현재 관리자 저장 흐름은 로컬 DB만 저장한다.
이제는 아래 순서로 바꾼다.

#### 관심종목 저장 시
1. 종목/메모/지지선/home_featured 를 로컬 DB에 반영
2. `flush()` 로 DB PK와 최신 상태 확보
3. Firebase payload 생성
4. Firebase `adminWatchlist/{ticker}` upsert
5. Firebase 성공 시 `commit()`
6. Firebase 실패 시 `rollback()` 후 AppError 반환

이렇게 해야 앱 로컬 DB와 Firebase 원본이 어긋나지 않는다.

---

## Firebase 문서 스키마
문서 ID는 반드시 **종목코드(ticker)** 를 사용한다.
예:
- `adminWatchlist/005930`
- `adminWatchlist/000660`

문서 구조는 아래 기준으로 통일한다.

```json
{
  "ticker": "005930",
  "name": "삼성전자",
  "supportLines": [66100],
  "resistanceLines": [],
  "comment": "단기 지지 확인 구간",
  "isActive": true,
  "isHomeFeatured": true,
  "marketType": "KOSPI",
  "source": "app_admin",
  "updatedBy": "admin",
  "updatedAt": "Firestore server timestamp",
  "createdAt": "기존 문서 없을 때만 server timestamp"
}
```

### 필드 설명
- `ticker`: 종목코드 문자열
- `name`: 종목명
- `supportLines`: 현재 활성 SUPPORT 가격 리스트
- `resistanceLines`: 현재 활성 RESISTANCE 가격 리스트, 이번 화면에서는 비워도 됨
- `comment`: 운영자 코멘트
- `isActive`: 추적 대상 여부
- `isHomeFeatured`: 홈 노출 여부
- `marketType`: KOSPI/KOSDAQ 등
- `source`: 마지막 입력 출처, 기본값 `app_admin`
- `updatedBy`: 관리자 계정 식별자
- `updatedAt`: Firestore server timestamp
- `createdAt`: 최초 생성 시만 기록

---

## supportLines 생성 규칙
앱 관리자 화면은 현재 SUPPORT 하나를 대표 지지선으로 입력한다.
따라서 이번 단계에서는 아래 규칙으로 저장한다.

- `source_label='admin_home'`
- `level_type='SUPPORT'`
- `is_active=true`
- 같은 종목의 활성 SUPPORT 중 `admin_home` 계열만 추출
- 가격 오름차순 정렬 후 `supportLines`에 저장
- 현재 UI가 대표 지지선 1개만 쓰므로 실질적으로 리스트 길이는 1개가 기본

`resistanceLines` 는 현재 관리자 화면 메인 범위가 아니므로 빈 배열로 저장해도 된다.
향후 저항선 UI 복귀 시 확장 가능하도록 필드는 유지한다.

---

## comment 생성 규칙
아래 우선순위로 `comment`를 만든다.

1. `stock.operator_memo`
2. 없으면 대표 SUPPORT(`source_label='admin_home'`)의 `note`
3. 둘 다 없으면 빈 문자열

이번 관리자 단순화 화면에서는 저장 시 1과 2를 같은 값으로 맞추므로 실제로는 동일할 가능성이 높다.

---

## 저장 동작 상세

### A. 관심종목 저장
대상: 관리자 화면의 저장 버튼

저장 성공 시 로컬 DB뿐 아니라 Firebase에도 반영해야 한다.

#### 로컬 DB 반영 대상
- `stocks.operator_memo`
- `price_levels` (대표 SUPPORT)
- `home_featured_stocks`
- 필요 시 `support_states` 초기 생성/유지

#### Firebase 반영 대상
문서 경로:
- `collection(settings.firebase_watchlist_collection).document(stock.code)`

업서트 payload:
- `ticker`
- `name`
- `supportLines`
- `resistanceLines=[]`
- `comment`
- `isActive=true`
- `isHomeFeatured=true/false`
- `marketType`
- `source='app_admin'`
- `updatedBy=actor_identifier`
- `updatedAt=SERVER_TIMESTAMP`
- `createdAt=SERVER_TIMESTAMP` 는 최초 생성 시만

### B. 홈 제외
현재 관리자 화면의 `홈 제외`는 앱 홈 노출만 끄는 동작이다.

이번 단계에서는 아래처럼 처리한다.

#### 로컬 DB
- `home_featured_stocks.is_active = false`
- 종목 자체는 삭제하지 않음
- 지지선도 삭제하지 않음

#### Firebase
- 문서는 삭제하지 말고 soft disable
- `isHomeFeatured=false`
- `isActive=true` 유지

이유:
- 홈에서는 빼더라도 계속 가격 추적 대상일 수 있음
- 단순 홈 제외와 추적 중단은 분리해야 함

### C. 추적 중단(향후 확장)
이번 단계에서 UI에 없어도 writer 설계는 고려한다.

추후 별도 "추적 중단" 기능이 생기면:
- Firebase `isActive=false`
- 웹 크롤러는 `isActive=true` 인 종목만 수집

---

## 예외 처리 규칙

### Firebase 자격증명/연결 실패
- Firebase 쓰기 실패 시 로컬 DB `rollback()`
- 사용자에게는 저장 실패 메시지 반환
- AppError 예시
  - `error_code="FIREBASE_WATCHLIST_WRITE_FAILED"`
  - `status_code=503`
  - `message="Firebase 관심종목 원본 반영에 실패했습니다."`

### Firestore 컬렉션/문서 쓰기 실패
- 동일하게 rollback
- audit log detail에 ticker/code를 남길 것

---

## 의존성 주입 방식
가능하면 `get_firestore_client()` 를 직접 `AdminService` 내부에서 반복 호출하지 말고,
writer/service 단위에서 lazy initialize 하거나 API layer에서 주입한다.

권장 방식:
- `AdminService(db, firestore_client=None)` 형태로 확장
- firestore client가 있으면 Firebase 동기화 수행
- 없으면 운영환경/테스트에서 명확히 실패하거나 옵션으로 비활성화

하지만 이번 목적상 **운영 저장은 Firebase 반영이 필수** 이므로,
관리자 저장 관련 API에서는 Firestore client를 주입받아 동작하도록 정리하는 것이 좋다.

---

## 웹 GitHub Actions 연동 전제
이번 작업은 앱 백엔드까지만 수정하되,
웹 쪽에서는 이후 아래 규칙을 따라야 한다.

- 관심종목 원본 파일/JSON을 따로 읽지 말 것
- Firebase `adminWatchlist`를 직접 조회할 것
- `isActive=true` 인 종목만 가격 크롤링 대상에 포함할 것
- 결과는 Firebase `stock_prices/{ticker}` 로 저장할 것

즉 웹의 역할은 **공용 원본 읽기 + 가격 수집** 이다.

---

## 테스트 요구사항

### 1. 관리자 저장 성공 시 Firebase upsert 호출
- 종목 저장
- 대표 SUPPORT 저장
- 홈 관심종목 저장
- Firebase `adminWatchlist/{ticker}` upsert 호출 확인

### 2. Firebase payload 검증
최소 아래 필드가 들어가는지 확인
- `ticker`
- `name`
- `supportLines`
- `comment`
- `isActive`
- `isHomeFeatured`
- `source='app_admin'`

### 3. Firebase 쓰기 실패 시 rollback
- Firestore mock이 예외를 던지게 설정
- Admin API 저장 요청
- 응답이 실패(503)
- DB에 종목/레벨/home_featured 변경이 commit되지 않았는지 확인

### 4. 홈 제외 시 Firebase soft update
- `isHomeFeatured=false` 로 바뀌는지 확인
- `isActive=true` 는 유지되는지 확인

---

## 완료 기준
아래가 모두 만족되면 완료다.

- 앱 관리자 저장 시 로컬 DB와 Firebase `adminWatchlist`가 함께 갱신된다
- Firebase 쓰기 실패 시 로컬 DB는 rollback된다
- 문서 ID는 ticker 기준으로 upsert된다
- 홈 제외는 Firebase 문서 삭제가 아니라 `isHomeFeatured=false` 로 처리된다
- 이후 웹 GitHub Actions가 `adminWatchlist`를 읽으면 앱에서 등록한 종목을 자동으로 가격 수집 대상으로 사용할 수 있다

---

## 체크리스트
- [ ] Firebase watchlist writer/service 추가
- [ ] AdminService에 Firebase write 연동
- [ ] 관리자 저장 시 Firebase upsert 수행
- [ ] 홈 제외 시 Firebase `isHomeFeatured=false` 반영
- [ ] Firebase 실패 시 DB rollback 처리
- [ ] 문서 ID를 ticker로 고정
- [ ] payload 스키마를 `ticker/name/supportLines/comment/isActive/isHomeFeatured` 중심으로 통일
- [ ] 테스트 mock 추가
- [ ] 저장 성공/실패 메시지 점검

---

## 구현 시 주의사항
- Firebase는 공용 원본이므로 append가 아니라 항상 upsert로 처리할 것
- 문서 삭제보다 soft flag(`isActive`, `isHomeFeatured`)를 우선할 것
- 앱 DB와 Firebase 중 하나만 성공하는 상태를 만들지 말 것
- 향후 웹 관리자도 같은 문서를 쓸 수 있게 스키마를 단순하게 유지할 것
- 이번 단계에서는 웹 GitHub Actions 수정까지 한 번에 넣지 말고, 앱 백엔드의 Firebase 쓰기까지 먼저 완료할 것
