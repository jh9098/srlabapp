# SRLAB Firebase `adminWatchlist` 기존 스키마 100% 호환 작업지시서

## 목적
앱 관리자 저장 시 Firebase `adminWatchlist` 컬렉션에 기록되는 문서를
**기존 지지저항랩 웹에서 사용하던 문서 구조와 최대한 동일하게 맞춘다.**

핵심 목표는 아래와 같다.

1. **기존 GitHub Actions를 수정하지 않고도** 앱에서 저장한 관심종목이 기존 크롤링 대상에 포함되게 한다.
2. 앱이 `adminWatchlist`에 쓰는 문서가 기존 웹이 쓰던 필드명/타입/기본값과 호환되게 만든다.
3. 기존 컬렉션 안에 이미 있는 랜덤 문서 ID 문서와 충돌하지 않도록 **ticker 기반 조회 후 업데이트** 방식으로 바꾼다.
4. 신규 문서 생성 시에도 기존 필수 필드가 빠지지 않게 한다.

---

## 현재 문제
현재 앱의 `services/firebase_watchlist_writer.py` 는 아래와 같은 자체 스키마로 쓰고 있다.

- `ticker`
- `name`
- `supportLines`
- `resistanceLines`
- `comment`
- `isActive`
- `isHomeFeatured`
- `marketType`
- `source`
- `updatedBy`
- `updatedAt`
- `createdAt`

하지만 기존 지지저항랩 웹의 `adminWatchlist` 문서는 아래 구조를 사용하고 있다.

- `alertCooldownHours` (int)
- `alertEnabled` (bool)
- `alertThresholdPercent` (int)
- `analysisId` (null 또는 string)
- `createdAt` (timestamp)
- `isPublic` (bool)
- `memo` (string)
- `name` (string)
- `portfolioReady` (bool)
- `resistanceLines` (array)
- `supportLines` (array)
- `ticker` (string)
- `updatedAt` (timestamp)

즉 지금 상태로는 Firebase 컬렉션 이름은 같아도,
**기존 웹 액션이 기대하는 필드가 누락되어 있을 가능성**이 있다.

---

## 작업 목표
`FirebaseWatchlistWriter` 를 수정해서 아래를 만족시킨다.

### 1. 기존 호환 필드 반드시 포함
아래 필드는 문서에 항상 존재하게 한다.

- `ticker`
- `name`
- `supportLines`
- `resistanceLines`
- `memo`
- `alertEnabled`
- `alertCooldownHours`
- `alertThresholdPercent`
- `analysisId`
- `isPublic`
- `portfolioReady`
- `createdAt`
- `updatedAt`

### 2. 앱 전용 부가 필드는 유지 가능
아래 필드는 기존 액션과 충돌하지 않는 선에서 추가 유지 가능하다.

- `isHomeFeatured`
- `marketType`
- `source`
- `updatedBy`
- `comment` (유지해도 되지만 `memo`를 반드시 함께 써야 함)

### 3. 문서 ID 호환성
기존 컬렉션에는 auto-id / 랜덤 문서 ID 문서가 이미 존재할 수 있으므로,
무조건 `document(ticker)` 를 쓰지 않는다.

반드시 아래 순서로 upsert 한다.

1. `where("ticker", "==", payload.ticker)` 로 기존 문서 조회
2. 문서가 있으면 해당 문서 업데이트
3. 없으면 새 문서 생성
4. 같은 ticker 문서가 여러 개면 경고 로그를 남기고 첫 문서를 업데이트

---

## 수정 파일
- `app/services/firebase_watchlist_writer.py`

필요 시 테스트 파일 추가/수정
- `app/tests/...` 또는 기존 백엔드 테스트 위치

---

## 구현 요구사항

### 1. payload 구조 수정
`WatchlistDocumentPayload` 를 기존 Firebase 스키마 기준으로 확장한다.

최소 포함 필드:

- `ticker: str`
- `name: str`
- `support_lines: list[int | float]`
- `resistance_lines: list[int | float]`
- `memo: str`
- `alert_enabled: bool`
- `alert_cooldown_hours: int`
- `alert_threshold_percent: int`
- `analysis_id: str | None`
- `is_public: bool`
- `portfolio_ready: bool`
- `is_home_featured: bool`
- `market_type: str`
- `updated_by: str`

기존 `comment` 필드는 내부 편의용으로 유지 가능하지만,
Firestore 문서에는 `memo`가 반드시 들어가야 한다.

---

### 2. Firestore 저장 필드명 수정
`to_firestore_dict()` 를 아래 기준으로 수정한다.

#### 반드시 저장할 필드
- `ticker`
- `name`
- `supportLines`
- `resistanceLines`
- `memo`
- `alertEnabled`
- `alertCooldownHours`
- `alertThresholdPercent`
- `analysisId`
- `isPublic`
- `portfolioReady`
- `updatedAt`

#### 최초 생성 시만 추가
- `createdAt`

#### 추가 유지 가능
- `isHomeFeatured`
- `marketType`
- `source = "app_admin"`
- `updatedBy`
- `comment` (있어도 되지만 기존 호환의 핵심은 `memo`)

---

### 3. 기존 필드 기본값
앱 관리자에서 저장한 값으로 기존 필드를 매핑할 때 기본값은 아래처럼 한다.

#### `memo`
- 우선순위
  1. `stock.operator_memo`
  2. 대표 SUPPORT 레벨의 `note`
  3. 없으면 빈 문자열 `""`

#### `alertEnabled`
- 기본값: `true`

#### `alertCooldownHours`
- 기본값: `1`

#### `alertThresholdPercent`
- 기본값: `2`

#### `analysisId`
- 기본값: `null`

#### `isPublic`
- 기본값: `stock.is_active`
- 삭제 대신 비활성 처리 시 `false` 반영 가능

#### `portfolioReady`
- 기본값: `true`

#### `resistanceLines`
- 현재 관리자 흐름상 저항선 입력이 없으면 빈 배열 `[]`

---

### 4. createdAt / updatedAt 규칙
기존 문서와 호환되게 아래처럼 처리한다.

#### 신규 문서 생성 시
- `createdAt = server timestamp`
- `updatedAt = server timestamp`

#### 기존 문서 수정 시
- `createdAt` 는 건드리지 않는다
- `updatedAt` 만 갱신한다

즉 기존 `createdAt` 이 덮어써지면 안 된다.

---

### 5. 문서 upsert 전략 변경
기존 코드:
- `collection.document(payload.ticker)` 기준 create → set

이 방식은 기존 랜덤 문서 ID와 중복될 위험이 있다.

#### 반드시 아래 방식으로 변경
1. `collection.where("ticker", "==", payload.ticker).limit(2)` 조회
2. 결과가 1개 이상이면
   - 첫 문서 reference 사용
   - `set(..., merge=True)` 로 업데이트
3. 결과가 0개면
   - 새 문서 생성
   - `collection.document()` auto-id 또는 `payload.ticker` 중 택1

권장:
- **기존 컬렉션이 이미 랜덤 ID 기반이므로 신규도 auto-id 생성 추천**
- 단, 운영상 ticker 고정 ID가 필요하면 그 정책을 명시적으로 통일해야 함

이번 단계에서는 **기존 호환성 우선**이므로 auto-id 생성이 더 안전하다.

---

### 6. 중복 ticker 방지 보완
같은 ticker 로 문서가 여러 개 있을 경우를 대비해 아래 보완을 한다.

- 조회 결과가 2개 이상이면 경고 로그 출력
- 첫 번째 문서만 업데이트
- 추후 중복 정리 작업 전까지 시스템이 멈추지 않게 한다

예시 로그:
- `Duplicate adminWatchlist documents detected for ticker=356680; updating first match.`

---

### 7. deactivate 처리 규칙
기존 `deactivate_watchlist_document()` 는 `is_active=False` 같은 앱 전용 개념을 쓰고 있다.

기존 호환 구조에 맞춰 아래처럼 반영한다.

- `isPublic = false`
- `portfolioReady = false` 는 선택
- `updatedAt` 갱신
- 문서 삭제는 하지 않는다

즉 기존 웹 액션이 `isPublic` 기준으로 필터링할 수 있으므로,
삭제보다 비활성 필드 갱신 방식으로 유지한다.

---

## 기대 결과
수정 후 앱 관리자에서 관심종목 저장하면,
Firebase `adminWatchlist` 문서는 기존 지지저항랩 웹이 생성하던 구조와 거의 동일해진다.

따라서 기존 GitHub Actions가 `adminWatchlist` 컬렉션을 그대로 읽고 있다면,
별도 수정 없이 앱에서 등록한 종목도 크롤링 대상에 포함될 가능성이 높다.

---

## 수동 확인 체크리스트
- [ ] 앱 관리자에서 종목 저장 후 `adminWatchlist` 에 문서가 생성/수정된다.
- [ ] 문서에 `memo` 필드가 들어간다.
- [ ] 문서에 `alertEnabled=true` 가 들어간다.
- [ ] 문서에 `alertCooldownHours=1` 이 들어간다.
- [ ] 문서에 `alertThresholdPercent=2` 가 들어간다.
- [ ] 문서에 `analysisId=null` 이 들어간다.
- [ ] 문서에 `isPublic=true` 가 들어간다.
- [ ] 문서에 `portfolioReady=true` 가 들어간다.
- [ ] `createdAt` 은 최초 생성 시만 생기고, 수정해도 유지된다.
- [ ] `updatedAt` 은 수정 시 갱신된다.
- [ ] 기존 랜덤 문서 ID 문서가 있으면 그 문서를 업데이트한다.
- [ ] 같은 ticker 중복 문서가 있어도 시스템이 503 없이 동작한다.

---

## 완료 기준
아래가 모두 만족되면 완료다.

1. 앱 관리자 저장 결과가 Firebase `adminWatchlist` 에 기존 지지저항랩 웹 스키마와 호환되게 저장된다.
2. `memo`, `isPublic`, `portfolioReady`, `alertEnabled`, `alertCooldownHours`, `alertThresholdPercent`, `analysisId` 필드가 빠지지 않는다.
3. 기존 컬렉션 문서 ID 체계(auto-id/random-id)와 충돌하지 않는다.
4. 기존 GitHub Actions 수정 없이도 앱 저장 데이터가 기존 watchlist 원본처럼 동작할 수 있는 상태가 된다.

---

## Codex 작업 시 주의사항
- 기존 GitHub Actions를 건드리지 않는다.
- Firebase writer 쪽만 수정해서 호환성을 맞춘다.
- `memo` 를 반드시 넣는다. `comment` 만 넣고 끝내면 안 된다.
- `createdAt` 을 기존 문서 업데이트 시 덮어쓰지 않는다.
- 문서 ID를 ticker로 강제 고정하지 말고 기존 문서 조회 후 업데이트 우선 전략을 사용한다.
