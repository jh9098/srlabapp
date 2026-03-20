# QA_CHECKLIST

버전: v1.0  
작성일: 2026-03-20  
상태: 현재 저장소 기준 작성 완료  
대상: 앱 / 백엔드 / 관리자 / signal batch / push dispatcher 운영자

---

## 1. 문서 목적

이 문서는 `srlabapp`의 **출시 직전 최종 QA 실행 체크리스트**다.

목표는 아래 5가지다.

1. 앱 핵심 사용자 흐름이 실제로 동작하는지 확인한다.
2. backend / admin / batch / push 흐름을 end-to-end 로 검수한다.
3. blocker / major / minor 판단 전에 필요한 사실 기반 점검을 끝낸다.
4. 출시 직전 반복 가능한 수동 QA 순서를 고정한다.
5. 운영자가 복붙해서 바로 사용할 수 있는 실행 체크리스트를 제공한다.

---

## 2. 현재 기준 QA 전제

현재 저장소는 다음 상태를 전제로 점검한다.

- Flutter 루트 앱 구조 사용
- FastAPI backend + SQLAlchemy + Alembic 사용
- 정적 `admin_web` 사용
- signal batch 수동 실행 가능
- notification dispatcher 수동 실행 가능
- FCM 설정이 없으면 DB 저장 + 로그 fallback 으로 동작
- 실제 Firebase 콘솔/실기기 검증은 외부 환경 준비가 필요

즉, 이 문서는 **로컬 MVP 완료 상태 + 출시 직전 검수 준비 상태**를 기준으로 작성한다.

---

## 3. 사전 준비 체크

### 3-1. 공통 준비

- [ ] `backend_api/.env.example` 기준으로 로컬 `.env` 를 생성했고, 실제 `.env` 는 공유 산출물에 포함하지 않는다.
- [ ] DB migration 이 최신까지 반영되어 있다.
- [ ] seed 또는 검수용 데이터가 준비되어 있다.
- [ ] Flutter 앱 실행에 필요한 `--dart-define` 값이 환경에 맞게 들어간다.
- [ ] admin_web `assets/env.js` 가 현재 API 주소를 가리킨다.
- [ ] 테스트용 사용자 식별자와 관리자 계정을 알고 있다.
- [ ] 검수용 종목, 레벨, 테마, 콘텐츠 샘플 데이터가 존재한다.

### 3-2. 권장 사전 명령

아래 명령은 QA 시작 전에 한 번 실행한다.

```bash
cd backend_api && python scripts/check_release_readiness.py
cd backend_api && pytest -q
cd /workspace/srlabapp && flutter test
cd backend_api && python -m app.tasks.run_signal_monitor --dry-run
cd backend_api && python -m app.tasks.run_notification_dispatcher --limit 20 --max-retry-count 3
```

---

## 4. 앱 수동 QA 체크리스트

### 4-1. 앱 시작 / 공통

- [ ] 앱이 실행 직후 크래시 없이 열린다.
- [ ] 하단 탭 5개(홈, 관심종목, 테마, 쇼츠, 마이)가 보인다.
- [ ] API base URL 이 현재 검수 환경과 일치한다.
- [ ] Firebase 미설정 환경에서도 앱이 죽지 않는다.
- [ ] 첫 화면 무한 로딩이 발생하지 않는다.
- [ ] 앱 재실행 후 기본 상태가 안정적으로 유지된다.

### 4-2. 홈 화면

- [ ] 홈 진입 시 시장 요약이 보인다.
- [ ] 오늘의 관찰 종목 카드가 노출된다.
- [ ] 관심종목 신호 요약 수치가 표시된다.
- [ ] 테마 카드가 보인다.
- [ ] 최근 콘텐츠 카드가 보인다.
- [ ] 데이터가 비어 있을 때 empty 상태가 자연스럽다.
- [ ] API 오류 시 오류 상태와 재시도 동작이 확인된다.

### 4-3. 종목 검색

- [ ] 검색어 입력 시 관련 종목이 조회된다.
- [ ] 종목명 기준 검색이 된다.
- [ ] 결과 0건일 때 empty 상태가 보인다.
- [ ] 검색 결과를 누르면 종목 상세로 이동한다.
- [ ] 비활성/비노출 종목이 잘못 노출되지 않는다.

### 4-4. 종목 상세

- [ ] 종목명 / 종목코드 / 시장 구분이 보인다.
- [ ] 현재가 / 등락률 / 거래량이 렌더링된다.
- [ ] 차트가 비정상 값 없이 렌더링된다.
- [ ] 지지선/저항선 요약 카드가 보인다.
- [ ] 최신 신호 카드가 보인다.
- [ ] 최근 신호 이벤트 목록이 보인다.
- [ ] 관련 테마 / 관련 콘텐츠가 있으면 연결된다.
- [ ] 일부 데이터 누락 시에도 크래시가 나지 않는다.
- [ ] 관심종목 추가/해제 버튼이 정상 동작한다.

### 4-5. 관심종목

- [ ] 종목 추가 후 목록에 즉시 반영된다.
- [ ] 중복 등록이 방지된다.
- [ ] 알림 on/off 변경이 저장된다.
- [ ] 종목 삭제가 정상 동작한다.
- [ ] 앱 재진입 후 관심종목 상태가 유지된다.
- [ ] 관심종목 요약 수치가 실제 데이터와 크게 어긋나지 않는다.

### 4-6. 테마 / 쇼츠 / 마이

- [ ] 테마 목록이 조회된다.
- [ ] 테마 상세 진입이 가능하다.
- [ ] 쇼츠/콘텐츠 카드가 비노출 데이터 없이 보인다.
- [ ] 알림 설정 화면 진입이 가능하다.
- [ ] 알림함 진입이 가능하다.
- [ ] 마이 화면에서 현재 환경 정보가 확인된다.

### 4-7. 알림함 / 푸시 라우팅

- [ ] 알림 목록이 보인다.
- [ ] 읽음 처리 후 상태가 바뀐다.
- [ ] 알림 탭 시 target path 이동이 된다.
- [ ] 잘못된 target path 또는 payload 에서 앱이 죽지 않는다.
- [ ] foreground 수신 시 사용자에게 알림 또는 안내가 보인다.
- [ ] background / terminated 수신 후 상세 진입이 동작한다.

---

## 5. Backend QA 체크리스트

### 5-1. API / health

- [ ] `GET /health` 가 `status=ok` 또는 예상 가능한 degraded 상태를 반환한다.
- [ ] `GET /api/v1/health` 가 환경/DB 상태를 반환한다.
- [ ] 공통 응답 구조(`success`, `message`, `data`, `error_code`)가 유지된다.
- [ ] validation error 가 500 이 아니라 422로 처리된다.

### 5-2. 앱용 핵심 API

- [ ] `GET /api/v1/home` 정상 응답
- [ ] `GET /api/v1/stocks/search?q=...` 정상 응답
- [ ] `GET /api/v1/stocks/{stock_code}` 정상 응답
- [ ] `GET /api/v1/stocks/{stock_code}/signals` 정상 응답
- [ ] `GET /api/v1/watchlist` 정상 응답
- [ ] `POST /api/v1/watchlist` 정상 응답
- [ ] `DELETE /api/v1/watchlist/{id}` 정상 응답
- [ ] `PATCH /api/v1/watchlist/{id}/alert` 정상 응답
- [ ] `GET /api/v1/themes` / `GET /api/v1/themes/{id}` 정상 응답
- [ ] `GET /api/v1/contents` 정상 응답
- [ ] `GET /api/v1/notifications` / 읽음 처리 정상 응답
- [ ] `GET/PATCH /api/v1/me/alert-settings` 정상 응답
- [ ] `POST /api/v1/me/device-tokens` 정상 응답

### 5-3. 지원 로직 / 상태 엔진

- [ ] WAITING → TESTING_SUPPORT 전이 확인
- [ ] TESTING_SUPPORT → DIRECT_REBOUND_SUCCESS 전이 확인
- [ ] TESTING_SUPPORT → BREAK_REBOUND_SUCCESS 전이 확인
- [ ] 성공 이후 REUSABLE 전이 확인
- [ ] 실패 이후 INVALID 전이 확인
- [ ] 동일 상태 전이에 대해 signal event 중복 저장이 방지된다.

---

## 6. 관리자(Admin) QA 체크리스트

### 6-1. 인증 / 세션

- [ ] 로그인 성공 시 Bearer 토큰이 발급된다.
- [ ] `auth/me` 조회가 정상 동작한다.
- [ ] 잘못된 비밀번호로 로그인 시 명확히 실패한다.
- [ ] 만료/오류 토큰으로 관리자 API 접근 시 차단된다.

### 6-2. 운영 입력

- [ ] 종목 조회가 된다.
- [ ] 종목 신규 등록이 된다.
- [ ] 종목 수정 및 비활성화가 된다.
- [ ] 가격 레벨 등록/수정이 된다.
- [ ] 지지선 상태 목록 조회가 된다.
- [ ] 상태 강제 수정이 된다.
- [ ] 신호 이벤트 목록 조회가 된다.
- [ ] 홈 노출 구성 저장이 된다.
- [ ] 테마 저장이 된다.
- [ ] 콘텐츠 등록/수정/비노출 처리까지 된다.
- [ ] 수동 푸시 저장이 된다.
- [ ] 감사 로그 조회가 된다.

### 6-3. 운영 반영 확인

- [ ] 관리자에서 수정한 종목 정보가 앱/공개 API에 반영된다.
- [ ] 홈 노출 변경이 앱 홈에 반영된다.
- [ ] 비노출 콘텐츠가 공개 API에서 사라진다.
- [ ] 상태 강제 수정 후 관련 데이터 조회 시 변경 내용이 확인된다.

---

## 7. Signal Batch QA 체크리스트

### 7-1. 수동 실행

- [ ] `--dry-run` 실행이 성공한다.
- [ ] dry-run 에서 생성 예정 수치가 로그에 남는다.
- [ ] 실제 실행 시 signal event 생성 건수가 출력된다.
- [ ] duplicate skip 수치가 출력된다.
- [ ] 일부 종목 오류가 전체 프로세스를 즉시 죽이지 않는지 확인한다.

### 7-2. 데이터 검증

- [ ] 레벨이 있는 종목만 계산 대상이 된다.
- [ ] 동일 일자 중복 이벤트가 무분별하게 쌓이지 않는다.
- [ ] watchlist / alert_settings 조건에 맞는 사용자에게만 notification 이 생성된다.

---

## 8. Push Dispatcher QA 체크리스트

### 8-1. dispatcher 실행

- [ ] pending notification 조회가 된다.
- [ ] token 없는 사용자는 `NO_TOKEN` 처리된다.
- [ ] 정상 토큰은 `SENT` 처리된다.
- [ ] 잘못된 토큰은 실패 또는 비활성화 처리된다.
- [ ] retry 가능한 오류는 pending 으로 남는다.
- [ ] 최대 재시도 초과 시 failed 처리된다.

### 8-2. 실기기 검증

- [ ] Android 실기기 1대 이상에서 수신 검증
- [ ] 가능하면 iOS 실기기 1대 이상에서 수신 검증
- [ ] foreground / background / terminated 동작 확인
- [ ] 알림 클릭 시 상세 화면 이동 확인

> 주의: 이 단계는 Firebase 프로젝트, 실제 앱 등록, 실제 토큰이 준비되어야 완료 가능하다.

---

## 9. End-to-End QA 시나리오

### 시나리오 A. 관리자 입력 → 앱 반영

- [ ] 관리자에서 종목/레벨 수정
- [ ] 앱 홈 또는 상세 재조회
- [ ] 수정 내용 반영 확인

### 시나리오 B. 상태 변화 → 이벤트 → 알림 저장

- [ ] 배치 실행 전 테스트 종목과 레벨 준비
- [ ] signal monitor 실행
- [ ] `signal_events` 생성 확인
- [ ] `notifications` pending 생성 확인
- [ ] 앱 알림함에서 해당 항목 조회 확인

### 시나리오 C. 알림 발송 → 상세 진입

- [ ] device token 등록
- [ ] dispatcher 실행
- [ ] 푸시 수신 또는 fallback 로그 확인
- [ ] 알림 터치 후 앱 target path 이동 확인

### 시나리오 D. 운영 공지 푸시

- [ ] 관리자 수동 푸시 등록
- [ ] 알림함 생성 확인
- [ ] 감사 로그에 manual push 기록 확인

---

## 10. 출시 직전 최종 판정 체크

아래 항목이 모두 충족되면 QA 기준 통과로 본다.

- [ ] 앱 핵심 흐름(홈/검색/상세/관심종목/알림함) 수동 검수 완료
- [ ] backend 자동 테스트 통과
- [ ] Flutter 테스트 통과
- [ ] 관리자 로그인 및 핵심 CRUD 확인 완료
- [ ] signal batch dry-run / 실제 실행 검수 완료
- [ ] push dispatcher 검수 완료
- [ ] blocker 0건
- [ ] major 이슈는 출시 책임자가 승인 가능한 수준으로 통제됨
- [ ] known issues 문서 최신화 완료

---

## 11. QA 기록 템플릿

아래 양식으로 검수 결과를 남긴다.

```text
검수 일시:
검수 환경: local / staging / prod-like
검수자:
앱 빌드 정보:
backend 커밋:

[앱]
- 홈:
- 검색:
- 상세:
- 관심종목:
- 알림함:

[관리자]
- 로그인:
- 종목/레벨:
- 홈 노출:
- 테마/콘텐츠:
- 감사 로그:

[배치/푸시]
- signal monitor:
- dispatcher:
- 실기기 푸시:

[이슈]
- blocker:
- major:
- minor:

최종 판정: 출시 가능 / 조건부 가능 / 출시 보류
```

---

## 12. Cloud Firestore 읽기 비용 검토

현재 프로젝트는 Cloud Firestore를 사용하지 않는다.

따라서 이 QA 체크리스트를 수행해도 **Firestore read 비용 증가는 없다**.
대신 현재 구조는 FastAPI + PostgreSQL + FCM 기준이므로, 검수 시에는 DB 조회량과 push 재시도 횟수를 중심으로 보면 된다.
