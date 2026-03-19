# 07_지지저항Lab_Flutter_FastAPI_개발순서_체크리스트
버전: v0.1  
작성일: 2026-03-19  
상태: 초안  
목적: 지지저항Lab 앱 MVP를 실제로 개발하기 위한 Flutter / FastAPI / 관리자 / 데이터 파이프라인 작업 순서를 체크리스트 형태로 정의한다.

---

# 1. 문서 목적

본 문서는 지지저항Lab 앱 MVP 개발을 실제 착수 가능한 수준으로 쪼개서,
어떤 순서로 구현해야 하는지 정리한 실행 문서다.

본 문서의 목적은 아래와 같다.

1. 기획 문서를 실제 개발 태스크로 변환한다.
2. Flutter / FastAPI / DB / 관리자 / 푸시 작업 순서를 고정한다.
3. 무엇부터 먼저 만들고, 무엇은 나중에 붙일지 구분한다.
4. 개발 중 우선순위가 흔들리지 않도록 한다.
5. AI 또는 개발자에게 그대로 작업 지시가 가능하도록 한다.

---

# 2. 전체 개발 원칙

## 2-1. MVP 본질부터 만든다
처음부터 모든 기능을 만들지 않는다.  
아래 3가지를 가장 먼저 완성한다.

1. 관심종목 등록
2. 종목 상세 상태 확인
3. 지지선/저항선 신호 표시

---

## 2-2. 화면보다 데이터 흐름을 먼저 고정한다
앱이 예쁘게 보이는 것보다,
아래 흐름이 먼저 살아야 한다.

- 종목 등록
- 가격 레벨 등록
- 가격 데이터 조회
- 상태 계산
- 앱에서 조회

---

## 2-3. 자동화보다 수동 운영 가능성을 먼저 확보한다
초기 MVP에서는 운영자가 직접 종목/지지선/테마를 관리할 수 있어야 한다.

---

## 2-4. 앱과 백엔드는 동시에 크게 만들지 않는다
먼저 백엔드 API와 더미 응답 구조를 고정하고,
그 다음 Flutter 화면을 붙이는 순서가 안전하다.

---

# 3. 전체 개발 단계 개요

전체 개발은 아래 8단계로 진행한다.

1. 개발환경 및 프로젝트 뼈대 세팅
2. DB / 백엔드 기본 구조 구축
3. 종목 / 가격 레벨 / 상태 엔진 기초 구현
4. 핵심 API 구현
5. Flutter MVP 화면 구현
6. 관리자 기능 구현
7. 푸시 / 알림 기능 구현
8. 통합 테스트 / 안정화 / 배포 준비

---

# 4. 단계별 개발 순서

---

# STEP 1. 개발환경 및 프로젝트 뼈대 세팅

## 목표
Flutter 앱, FastAPI 서버, DB, 관리자 프로젝트의 기본 골격을 만든다.

## 1-1. 저장소 구조 결정
- [ ] mono repo로 갈지 분리 repo로 갈지 결정
- [ ] 권장 구조 예시 확정

```text
jijiresistance-lab/
  /frontend_app
  /backend_api
  /admin_web
  /docs
1-2. 문서 폴더 정리

 /docs 폴더 생성

 01~06 명세서 저장

 07 개발 체크리스트 문서 저장

1-3. Flutter 프로젝트 생성

 Flutter 앱 프로젝트 생성

 기본 라우팅 구조 세팅

 공통 테마 파일 생성

 환경설정 분리 구조 준비

1-4. FastAPI 프로젝트 생성

 FastAPI 프로젝트 생성

 requirements 또는 pyproject 설정

 app 폴더 구조 생성

 api / models / schemas / services / repositories 폴더 분리

1-5. DB 연결 기본 설정

 PostgreSQL 연결 준비

 SQLAlchemy 또는 ORM 구조 선택

 Alembic 마이그레이션 세팅

1-6. 공통 개발 규칙 정리

 env 파일 구조 정의

 dev / prod 환경 구분

 공통 응답 포맷 유틸 정의

 예외 처리 미들웨어 틀 생성

STEP 2. DB / 백엔드 기본 구조 구축
목표

핵심 테이블과 API 서버의 기본 동작을 먼저 만든다.

2-1. DB 모델 생성

 users

 stocks

 price_levels

 daily_bars

 minute_bars

 support_states

 signal_events

 watchlists

 themes

 theme_stock_maps

 content_posts

 notifications

 admin_audit_logs

2-2. 마이그레이션 생성

 초기 migration 파일 생성

 로컬 DB에 반영

 테스트 데이터 삽입 확인

2-3. 공통 코드 작성

 Base model

 timestamp mixin

 pagination 유틸

 response schema

 error code enum

 auth 기본 구조

2-4. 더미 데이터 입력

 대표 종목 5~20개 삽입

 대표 지지선/저항선 삽입

 대표 테마 삽입

 종목별 content_posts 샘플 삽입

STEP 3. 종목 / 가격 레벨 / 상태 엔진 기초 구현
목표

지지저항Lab의 핵심 로직인 가격 레벨 + 상태 계산이 돌아가게 만든다.

3-1. 종목 서비스 구현

 종목 검색 서비스

 종목 기본 조회 서비스

 활성 종목 목록 조회 서비스

3-2. 가격 레벨 서비스 구현

 종목별 활성 레벨 조회

 SUPPORT / RESISTANCE 분리 조회

 level_order 기준 정렬

 레벨 등록/수정/비활성 로직

3-3. support status 계산 유틸 구현

 support_near_pct 파라미터 처리

 rebound_success_pct 처리

 support break 기준 처리

 reusable 판정 처리

 invalid 판정 처리

3-4. 상태 전이 함수 구현

 WAITING → TESTING_SUPPORT

 TESTING_SUPPORT → DIRECT_REBOUND_SUCCESS

 TESTING_SUPPORT → BREAK_REBOUND_SUCCESS

 DIRECT_REBOUND_SUCCESS → REUSABLE

 BREAK_REBOUND_SUCCESS → REUSABLE

 DIRECT_REBOUND_SUCCESS → INVALID

 BREAK_REBOUND_SUCCESS → INVALID

3-5. 상태 이벤트 생성 로직 구현

 상태 변경 시 signal_events 기록

 동일 상태 중복 이벤트 방지

 message 자동 생성 유틸 작성

3-6. 단위 테스트 작성

 직접 반등 성공 테스트

 이탈 후 반등 성공 테스트

 재활용 가능 테스트

 재사용 금지 테스트

 예외 케이스 테스트

STEP 4. 핵심 API 구현
목표

Flutter 앱이 붙을 수 있는 최소 API 세트를 완성한다.

4-1. 홈 API

 GET /api/v1/home

 market_summary 반환

 featured_stocks 반환

 watchlist_signal_summary 반환

 themes 반환

 recent_contents 반환

4-2. 종목 검색 API

 GET /api/v1/stocks/search?q=

 종목명 검색

 코드 검색

 빈 결과 처리

4-3. 종목 상세 API

 GET /api/v1/stocks/{stock_code}

 가격 정보 반환

 상태 객체 반환

 레벨 정보 반환

 support_state 반환

 scenario / reason_lines 반환

 차트 데이터 반환

4-4. 종목 신호 API

 GET /api/v1/stocks/{stock_code}/signals

 최신 이벤트 조회

 페이지네이션 또는 limit 지원

4-5. 관심종목 API

 GET /api/v1/watchlist

 POST /api/v1/watchlist

 DELETE /api/v1/watchlist/{id}

 PATCH /api/v1/watchlist/{id}/alert

4-6. 테마 API

 GET /api/v1/themes

 leader / follower 종목 포함 반환

4-7. 알림 API

 GET /api/v1/notifications

 PATCH /api/v1/notifications/{id}/read

 GET /api/v1/me/alert-settings

 PATCH /api/v1/me/alert-settings

4-8. Swagger/OpenAPI 정리

 태그 분리

 request/response 예시 추가

 에러 응답 예시 추가

STEP 5. Flutter MVP 화면 구현
목표

앱의 핵심 사용자 플로우를 실제 작동하게 만든다.

5-1. Flutter 폴더 구조 생성

 features/home

 features/watchlist

 features/stock

 features/theme

 features/shorts

 features/my

 core/network

 core/theme

 core/widgets

5-2. 공통 요소 구현

 API client

 error handling

 loading widget

 empty state widget

 common card widget

 status badge widget

5-3. 홈 화면 구현

 market summary section

 featured stocks section

 watchlist summary section

 themes section

 recent contents section

 pull to refresh

5-4. 관심종목 화면 구현

 관심종목 리스트

 상태 배지 표시

 알림 ON/OFF 토글

 삭제 버튼

 빈 상태 화면

 정렬/필터 최소 버전

5-5. 종목 검색 화면 구현

 검색창

 검색 결과 리스트

 관심종목 추가 버튼

 최근 검색(선택)

5-6. 종목 상세 화면 구현

 상단 가격 정보

 상태 배지

 레벨 카드

 간단 차트

 시나리오 카드

 해설 3줄

 관련 테마 / 콘텐츠

5-7. 테마 화면 구현

 테마 목록

 대장주 / 후속주 표시

 종목 상세 이동 연결

5-8. 쇼츠 화면 구현

 콘텐츠 카드 목록

 외부 링크 연결

 종목 상세 딥링크 연결

5-9. 마이 화면 구현

 알림 설정 진입

 최근 본 종목(최소 버전)

 공지 / 문의 링크

 버전 표시

STEP 6. 관리자 기능 구현
목표

운영자가 실제로 데이터를 통제할 수 있게 만든다.

6-1. 관리자 로그인 / 권한 체크

 관리자 인증 구조

 role 기반 접근 제어

 ADMIN / OPERATOR / VIEWER 분기

6-2. 종목 관리 화면

 종목 검색

 종목 등록

 종목 수정

 활성/비활성 처리

 메모 입력

6-3. 가격 레벨 관리 화면

 종목별 레벨 목록 조회

 지지선 추가

 저항선 추가

 가격 수정

 활성/비활성 변경

 메모 수정

6-4. 지지선 상태 관리 화면

 상태 목록 조회

 종목별 필터

 status 필터

 강제 수정 기능

 invalid reason 입력

 최근 상태 전이 이력 표시

6-5. 신호 이벤트 관리 화면

 최신 이벤트 목록

 이벤트 타입 필터

 notified 여부 필터

 ignored 처리

 수동 푸시 전환 기능

6-6. 홈 노출 관리 화면

 오늘의 시장 한 줄 입력

 오늘의 관찰 종목 선택

 홈 카드 순서 조정

 강제 고정 카드 설정

6-7. 테마 관리 화면

 테마 등록/수정

 점수 수정

 대장주 연결

 후속주 연결

 노출 여부 설정

6-8. 콘텐츠 / 쇼츠 관리 화면

 콘텐츠 등록/수정

 외부 링크 연결

 종목/테마 연결

 썸네일 URL 입력

 홈 노출 여부 설정

6-9. 운영 로그 화면

 admin_audit_logs 조회

 target_type 필터

 작업자 필터

 before/after JSON 보기

STEP 7. 푸시 / 알림 기능 구현
목표

가격 신호가 사용자에게 실제로 전달되게 만든다.

7-1. 푸시 토큰 저장 구조

 사용자 디바이스 토큰 저장 테이블 또는 컬럼 설계

 로그인 시 토큰 등록

 토큰 갱신 처리

 로그아웃 시 정리 정책

7-2. Firebase Cloud Messaging 연동

 FCM 프로젝트 연결

 Android 우선 연동

 foreground / background 처리

 딥링크 연결

7-3. 자동 푸시 로직 구현

 signal_events 생성 시 푸시 후보 선정

 사용자 알림 설정 확인

 watchlist 보유 여부 확인

 중복 발송 방지

 notifications 저장

7-4. 수동 푸시 기능 구현

 관리자 푸시 작성 화면

 대상 필터 처리

 딥링크 선택

 테스트 발송 기능

7-5. 앱 내 알림함 구현

 notifications 목록 조회

 읽음 처리

 종목 상세 딥링크 이동

 빈 상태 처리

STEP 8. 데이터 수집 / 배치 / 상태엔진 자동화 구현
목표

운영용 데이터 흐름이 자동으로 돌아가게 만든다.

8-1. 종목 시세 수집기 구현

 현재가 수집

 일봉 수집

 분봉 수집 또는 생성

 종목별 수집 우선순위 설정

8-2. 장중 배치

 관심종목 현재가 갱신

 상태 계산 트리거

 signal_events 생성

 푸시 후보 등록

8-3. 장마감 배치

 일봉 확정 저장

 상태 재계산

 홈 데이터 재생성

 테마 점수 재계산

 콘텐츠 요약 데이터 갱신

8-4. 장애 대응

 외부 API 실패 재시도

 로그 적재

 실패 종목 목록 저장

 관리자 대시보드 경고 표시

STEP 9. 통합 테스트
목표

핵심 시나리오가 실제로 끝까지 동작하는지 확인한다.

9-1. 핵심 사용자 시나리오 테스트

 앱 설치 후 홈 진입

 종목 검색

 관심종목 추가

 종목 상세 진입

 상태 배지 확인

 알림 ON 설정

 푸시 수신

 푸시 클릭 후 상세 진입

9-2. 운영 시나리오 테스트

 관리자 종목 등록

 관리자 지지선 등록

 상태 계산 반영 확인

 이벤트 생성 확인

 수동 푸시 발송 확인

 운영 로그 기록 확인

9-3. 예외 시나리오 테스트

 종목 없음

 관심종목 없음

 네트워크 오류

 시세 수집 실패

 중복 이벤트 생성

 잘못된 상태 강제 수정 후 로그 확인

STEP 10. UI / 성능 / 안정화
목표

앱이 실제 사용자에게 보여줄 수준으로 정리한다.

10-1. UI 정리

 색상 / 배지 severity 통일

 폰트 크기 정리

 카드 spacing 정리

 빈 상태 문구 정리

 로딩 상태 정리

10-2. 성능 정리

 홈 API 응답 속도 점검

 관심종목 리스트 렌더링 최적화

 차트 렌더링 최적화

 과도한 rebuild 방지

10-3. 안정성 정리

 에러 로그 수집

 API timeout 처리

 retry 정책

 null 안전성 점검

 잘못된 응답 포맷 대응

STEP 11. 배포 준비
목표

개발 환경에서 운영 가능한 형태로 옮긴다.

11-1. 백엔드 배포 준비

 환경변수 정리

 DB 연결 정보 분리

 CORS 설정

 로그 레벨 분리

 health check endpoint 추가

11-2. 앱 배포 준비

 앱 아이콘

 앱 이름 확정

 Android 권한 점검

 FCM 설정 점검

 릴리즈 빌드 테스트

11-3. 관리자 배포 준비

 admin 접근 제한

 HTTPS

 로그인 보호

 운영 로그 저장 확인

5. 추천 구현 순서 요약

가장 추천하는 실제 구현 순서는 아래와 같다.

1차

DB 모델

종목/레벨 CRUD

support status 계산 유틸

종목 상세 API

관심종목 API

2차

Flutter 홈 / 관심종목 / 종목 검색 / 종목 상세

테마 API / 테마 화면

관리자 종목 / 레벨 관리

3차

signal_events 생성

notifications 저장

FCM 연동

알림함 구현

4차

홈 노출 관리

테마 관리

콘텐츠/쇼츠 연결

운영 로그 / 감사 기능

6. 지금 당장 시작할 최소 작업 세트

아래 10개만 먼저 만들면 MVP가 실제로 굴러가기 시작한다.

 stocks 테이블

 price_levels 테이블

 support_states 테이블

 watchlists 테이블

 GET /stocks/search

 GET /stocks/{stock_code}

 GET /watchlist

 POST /watchlist

 Flutter 종목 검색 화면

 Flutter 종목 상세 화면

7. 백엔드 우선 체크리스트
필수

 모델 정의

 마이그레이션 완료

 기본 CRUD 완료

 상태 계산 서비스 완료

 홈/관심종목/상세 API 완료

그 다음

 이벤트 생성 완료

 알림 저장 완료

 관리자 API 완료

 배치 작업 완료

8. Flutter 우선 체크리스트
필수

 하단 탭 구조 완성

 홈 페이지 완성

 관심종목 페이지 완성

 종목 검색 페이지 완성

 종목 상세 페이지 완성

그 다음

 테마 페이지

 쇼츠 페이지

 마이 페이지

 알림함

 푸시 딥링크 처리

9. 관리자 우선 체크리스트
필수

 종목 관리

 가격 레벨 관리

 상태 조회

 이벤트 조회

 수동 상태 수정

 운영 로그 저장

그 다음

 홈 노출 관리

 테마 관리

 콘텐츠 연결

 수동 푸시 발송

10. 작업 분리 기준

개발을 나눌 때는 아래처럼 자르면 좋다.

백엔드 파트

DB

API

상태 엔진

수집기

이벤트/알림 로직

앱 파트

화면

상태관리

API 연동

알림 수신

딥링크 처리

관리자 파트

백오피스 UI

운영 CRUD

푸시 발송

로그 조회

11. 단계 종료 기준
STEP 1 종료 기준

Flutter / FastAPI / DB 프로젝트가 모두 실행된다.

STEP 2 종료 기준

핵심 테이블 생성 및 더미 데이터 조회가 가능하다.

STEP 3 종료 기준

지지선 상태 계산 함수가 테스트를 통과한다.

STEP 4 종료 기준

홈 / 종목검색 / 종목상세 / 관심종목 API가 정상 응답한다.

STEP 5 종료 기준

앱에서 관심종목 추가 후 종목 상세 상태 확인이 가능하다.

STEP 6 종료 기준

운영자가 종목과 레벨을 수정할 수 있다.

STEP 7 종료 기준

이벤트 발생 시 푸시가 도착하고 앱에서 클릭 이동이 된다.

STEP 8 종료 기준

장중/장마감 데이터 흐름이 자동으로 돈다.

12. 최종 MVP 완료 기준

아래 조건을 모두 만족하면 MVP 1차 완료로 본다.

 사용자가 종목을 검색할 수 있다.

 사용자가 관심종목을 등록할 수 있다.

 종목 상세에서 지지선/저항선과 상태를 볼 수 있다.

 시스템이 지지선 상태를 계산할 수 있다.

 이벤트가 발생하면 기록된다.

 푸시 알림이 발송된다.

 운영자가 종목/레벨/상태를 수정할 수 있다.

 홈 화면에 오늘의 관찰 종목과 테마를 노출할 수 있다.

13. 최종 요약

지지저항Lab MVP 개발은
“백엔드 상태엔진 → 핵심 API → Flutter 핵심 화면 → 관리자 운영 도구 → 푸시 → 자동화”
순서로 진행하는 것이 가장 안전하다.

핵심은 아래와 같다.

먼저 데이터와 상태엔진을 만든다.

그 다음 앱 핵심 화면을 붙인다.

동시에 운영자가 통제할 수 있는 관리자 기능을 만든다.

마지막에 푸시와 자동화를 연결한다.

즉, 이 문서는 지지저항Lab 앱 MVP를 실제로 만들기 위한
실행용 개발 로드맵 겸 체크리스트 문서이다.
