# 07_지지저항Lab_Flutter_FastAPI_개발순서_체크리스트
버전: v0.2  
작성일: 2026-03-19  
상태: 로컬 MVP 완료 기준 반영  
목적: 지지저항Lab 앱 MVP를 실제로 개발/검수/마감하기 위한 Flutter / FastAPI / 관리자 / 푸시 작업 순서를 체크리스트 형태로 정의한다.

---

# 1. 문서 목적

본 문서는 지지저항Lab 앱 MVP 개발을 실제 착수 가능한 수준으로 쪼개서,
어떤 순서로 구현해야 하는지 정리한 실행 문서다.

또한 **현재 저장소의 실제 구조**와 **로컬 MVP 완료 기준**을 문서 기준으로 고정한다.

본 문서의 목적은 아래와 같다.

1. 기획 문서를 실제 개발 태스크로 변환한다.
2. Flutter / FastAPI / DB / 관리자 / 푸시 작업 순서를 고정한다.
3. 무엇부터 먼저 만들고, 무엇은 나중에 붙일지 구분한다.
4. 개발 중 우선순위가 흔들리지 않도록 한다.
5. 로컬 MVP 완료와 프로덕션 준비를 분리한다.

---

# 2. 현재 저장소 최종 구조

초기 권장 예시에는 `frontend_app/` 폴더가 있었지만,
**현재 저장소는 루트 Flutter 구조를 실제 최종 구조로 사용한다.**

```text
srlabapp/
  /backend_api
  /admin_web
  /docs
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

구조 역할은 아래와 같다.

- `backend_api`: FastAPI, SQLAlchemy, Alembic, 상태 엔진, 앱/관리자 API
- `admin_web`: 로컬 운영 검수용 관리자 웹 UI
- 루트 Flutter 앱: `lib`, `android`, `ios`, `web`, `test`, `pubspec.yaml`
- `docs`: 기획 / 로직 / DB/API / 운영 / 체크리스트 문서

따라서 **이번 MVP 마감에서는 폴더 대이동을 하지 않고 문서를 실제 구조에 맞춘다.**

---

# 3. 전체 개발 원칙

## 3-1. MVP 본질부터 만든다
처음부터 모든 기능을 만들지 않는다.
아래 3가지를 가장 먼저 완성한다.

1. 관심종목 등록
2. 종목 상세 상태 확인
3. 지지선/저항선 신호 표시

## 3-2. 화면보다 데이터 흐름을 먼저 고정한다
앱이 예쁘게 보이는 것보다,
아래 흐름이 먼저 살아야 한다.

- 종목 등록
- 가격 레벨 등록
- 가격 데이터 조회
- 상태 계산
- 앱에서 조회

## 3-3. 자동화보다 수동 운영 가능성을 먼저 확보한다
초기 MVP에서는 운영자가 직접 종목/지지선/테마를 관리할 수 있어야 한다.

## 3-4. 앱과 백엔드는 동시에 크게 만들지 않는다
먼저 백엔드 API와 응답 구조를 고정하고,
그 다음 Flutter 화면을 붙이는 순서가 안전하다.

## 3-5. 로컬 MVP 완료와 프로덕션 준비를 분리한다
이번 저장소 기준 마감은 **로컬 실행/검수 가능한 MVP 완료판**이다.
운영 인프라, 스토어 배포, 실서비스 자격증명은 별도 준비 항목으로 분리한다.

---

# 4. 단계별 개발 순서

## STEP 1. 개발환경 및 프로젝트 뼈대 세팅
### 목표
Flutter 앱, FastAPI 서버, DB, 관리자 프로젝트의 기본 골격을 만든다.

- [x] 저장소 구조 확정
- [x] 문서 폴더 정리
- [x] Flutter 루트 앱 생성 및 라우팅/테마 세팅
- [x] FastAPI 프로젝트 생성
- [x] DB 연결 및 Alembic 세팅
- [x] 공통 응답 구조 / 예외 처리 정리

---

## STEP 2. DB / 백엔드 기본 구조 구축
### 목표
핵심 테이블과 API 서버의 기본 동작을 먼저 만든다.

- [x] users 성격의 식별자 기반 사용자 데이터 흐름 반영
- [x] stocks
- [x] price_levels
- [x] daily_bars
- [x] support_states
- [x] signal_events
- [x] watchlists
- [x] themes / theme_stock_maps
- [x] content_posts
- [x] notifications
- [x] device_tokens
- [x] admin_audit_logs
- [x] 초기 migration 구성
- [x] 최소 seed 데이터 구성

---

## STEP 3. 종목 / 가격 레벨 / 상태 엔진 기초 구현
### 목표
지지저항Lab의 핵심 로직인 가격 레벨 + 상태 계산이 돌아가게 만든다.

- [x] 종목 검색 서비스
- [x] 종목 기본 조회 서비스
- [x] 활성 종목 목록 조회 서비스
- [x] 종목별 활성 레벨 조회
- [x] SUPPORT / RESISTANCE 분리 조회
- [x] support status 계산 유틸
- [x] 상태 전이 함수 구현
- [x] 상태 변경 시 signal_events 기록
- [x] 핵심 단위 테스트 작성

---

## STEP 4. 핵심 API 구현
### 목표
Flutter 앱이 붙을 수 있는 최소 API 세트를 완성한다.

- [x] GET /api/v1/home
- [x] GET /api/v1/stocks/search
- [x] GET /api/v1/stocks/{stock_code}
- [x] GET /api/v1/stocks/{stock_code}/signals
- [x] GET /api/v1/watchlist
- [x] POST /api/v1/watchlist
- [x] DELETE /api/v1/watchlist/{id}
- [x] PATCH /api/v1/watchlist/{id}/alert
- [x] GET /api/v1/themes
- [x] GET /api/v1/notifications
- [x] PATCH /api/v1/notifications/{id}/read
- [x] GET /api/v1/me/alert-settings
- [x] PATCH /api/v1/me/alert-settings
- [x] POST /api/v1/me/device-tokens

---

## STEP 5. Flutter MVP 화면 구현
### 목표
앱의 핵심 사용자 플로우를 실제 작동하게 만든다.

- [x] `lib/core`, `lib/features` 기반 구조 정리
- [x] 홈 화면
- [x] 관심종목 화면
- [x] 종목 검색 화면
- [x] 종목 상세 화면
- [x] 테마 화면
- [x] 쇼츠 화면(최소 버전)
- [x] 마이 화면
- [x] 알림함 / 알림 설정 화면
- [x] 모델 파싱 및 위젯 smoke test 최소 구성

---

## STEP 6. 관리자 기능 구현
### 목표
운영자가 실제로 데이터를 통제할 수 있게 만든다.

- [x] 관리자 로그인 API
- [x] 관리자 Bearer 토큰 인증
- [x] 관리자 웹 로그인 화면
- [x] 종목 관리 API
- [x] 가격 레벨 관리 API
- [x] 지지선 상태 조회 / 강제 수정 API
- [x] 신호 이벤트 조회 API
- [x] 홈 노출 조회 / 저장 API
- [x] 테마 조회 / 저장 API
- [x] 수동 푸시 API
- [x] 운영 로그 조회 API

참고:
- 현재 역할(Role) 분리까지는 하지 않고 **환경변수 기반 단일 관리자 계정 + 서명 토큰** 방식으로 로컬 MVP를 마감한다.

---

## STEP 7. 푸시 / 알림 기능 구현
### 목표
가격 신호가 사용자에게 실제로 전달되게 만든다.

- [x] 사용자 디바이스 토큰 저장 구조
- [x] 디바이스 토큰 등록 API
- [x] signal_events → notifications 저장 연동
- [x] watchlist / alert_settings 기반 발송 조건 반영
- [x] 설정이 있으면 실제 FCM HTTP 전송 시도
- [x] 설정이 없으면 DB 저장 + 로그 fallback
- [x] Flutter firebase_messaging 연결 코드 추가
- [x] Firebase 설정이 없을 때 graceful skip 처리

주의:
- Firebase 콘솔, 실제 앱 패키지 등록, 플랫폼별 설정 파일은 저장소 밖 수동 작업이 남을 수 있다.
- 하지만 저장소 코드는 **연동 가능한 상태**까지 구현한다.

---

## STEP 8. 데이터 수집 / 배치 / 상태엔진 자동화 구현
### 목표
운영용 데이터 흐름이 자동으로 돌아가게 만든다.

- [ ] 실거래 외부 시세 API 연동 고도화
- [ ] 장중 배치 스케줄러 고도화
- [ ] 장마감 자동 재계산 고도화
- [ ] 운영 장애 대시보드 고도화

이 단계는 로컬 MVP 마감의 필수 종료 조건은 아니며,
운영/프로덕션 준비 단계로 일부 이관할 수 있다.

---

## STEP 9. 통합 테스트
### 목표
핵심 시나리오가 실제로 끝까지 동작하는지 확인한다.

- [x] 백엔드 핵심 API 테스트
- [x] support state engine 테스트
- [x] notifications / admin 테스트
- [x] Flutter 모델 파싱 / 앱 shell smoke test 추가
- [ ] 실제 Firebase 콘솔이 연결된 상태에서 푸시 실기기 검증

---

## STEP 10. UI / 성능 / 안정화
### 목표
앱이 실제 사용자에게 보여줄 수준으로 정리한다.

- [x] 기본 탭/상태 배지/빈 상태/오류 상태 정리
- [x] 핵심 로컬 검수 흐름 정리
- [ ] 세부 UI 폴리시 고도화
- [ ] 성능 계측 / 에러 수집 고도화

---

## STEP 11. 배포 준비
### 목표
개발 환경에서 운영 가능한 형태로 옮긴다.

- [ ] 실제 운영 DB / 비밀정보 분리
- [ ] HTTPS / Reverse Proxy / CORS 정책 강화
- [ ] 운영 로그 수집 / 모니터링 연동
- [ ] 앱 서명 / 스토어 배포 준비
- [ ] Firebase 운영 프로젝트 자격증명 적용

이 단계는 **로컬 MVP 완료** 이후의 작업이다.

---

# 5. 로컬 MVP 완료 기준

아래 조건을 모두 만족하면 **로컬 MVP 완료**로 본다.

- [x] 사용자가 종목을 검색할 수 있다.
- [x] 사용자가 관심종목을 등록할 수 있다.
- [x] 종목 상세에서 지지선/저항선과 상태를 볼 수 있다.
- [x] 시스템이 지지선 상태를 계산할 수 있다.
- [x] 이벤트가 발생하면 기록된다.
- [x] 알림이 `notifications`에 저장된다.
- [x] 디바이스 토큰을 등록할 수 있다.
- [x] FCM 설정이 있으면 실제 전송을 시도할 수 있다.
- [x] FCM 설정이 없으면 fallback으로 동작한다.
- [x] 운영자가 로그인 후 종목/레벨/상태/이벤트/홈노출/테마/푸시를 관리할 수 있다.
- [x] 홈 화면에 오늘의 관찰 종목과 테마를 노출할 수 있다.

---

# 6. 아직 남는 항목의 분류

## 6-1. MVP 미완성 항목
현재 기준 핵심 MVP 미완성 항목은 남기지 않는 것을 목표로 한다.

## 6-2. 외부 설정 필요 항목
아래는 기능 미완성이 아니라 **외부 설정 필요** 항목이다.

- Firebase 콘솔 프로젝트 생성
- Android/iOS/Web 앱 등록
- 실제 FCM 서버 키 또는 운영 자격증명 입력
- 실제 디바이스에서 푸시 수신 검증
- 운영 DB / 서버 / HTTPS / 스토어 배포

---

# 7. 최종 요약

지지저항Lab MVP 개발은
**백엔드 상태엔진 → 핵심 API → Flutter 핵심 화면 → 관리자 운영 도구 → 푸시 → 검수 문서 정리** 순서로 마감한다.

현재 저장소 기준 핵심은 아래와 같다.

1. 실제 구조는 루트 Flutter 앱 + `backend_api` + `admin_web` + `docs` 이다.
2. 관리자 인증은 임시 헤더가 아니라 로그인 + 서명 토큰 기반으로 마감한다.
3. FCM은 외부 콘솔 설정 전에도 코드 기준 연동 가능 상태로 마감한다.
4. README 하나만 읽어도 로컬 MVP 검수가 가능해야 한다.
5. 남은 것은 기능 미완성이 아니라 주로 외부 설정/배포 준비 항목이어야 한다.
