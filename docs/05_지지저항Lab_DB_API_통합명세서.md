# 05_지지저항Lab_DB_API_통합명세서
버전: v0.1  
작성일: 2026-03-19  
상태: 초안  
목적: 지지저항Lab 앱 MVP에서 사용하는 핵심 DB 구조와 API 규격을 통합 정의하여, 앱/백엔드/관리자 화면이 동일한 데이터 언어를 사용하도록 한다.

---

# 1. 문서 목적

본 문서는 지지저항Lab 앱 MVP의 데이터 구조와 API 규격을 통합 정의하기 위한 문서이다.

본 문서의 목적은 아래와 같다.

1. 앱, 백엔드, 관리자 화면이 같은 데이터 기준을 사용하도록 한다.
2. 최소 MVP 범위에서 필요한 핵심 테이블만 우선 정의한다.
3. 화면 구현에 필요한 API 목록과 요청/응답 구조를 고정한다.
4. 지지선 상태관리 로직 문서와 주가데이터 아키텍처 문서를 실제 구현 가능한 스키마로 연결한다.
5. 추후 확장 시에도 큰 수정 없이 확장 가능한 기본 구조를 만든다.

---

# 2. 문서 범위

본 문서에서 다루는 범위는 아래와 같다.

- 핵심 DB 테이블 정의
- 테이블 간 관계
- 주요 필드 정의
- 상태값 및 enum 규칙
- 핵심 API 목록
- 요청/응답 규격
- 공통 응답 포맷
- 인증/권한 기본 정책
- 에러코드 기본 정책

본 문서는 실제 SQL DDL 문서가 아니라,  
**구현 전 단계에서 기능과 데이터를 연결하는 통합 설계 문서**이다.

---

# 3. 설계 원칙

## 3-1. MVP에 필요한 테이블만 먼저 정의한다
처음부터 너무 많은 테이블을 만들지 않는다.  
초기 MVP 구현에 직접 필요한 것만 우선 정의한다.

## 3-2. 실시간 캐시와 영구 저장을 구분한다
현재가 같은 자주 변하는 값은 캐시로 처리하고,  
DB에는 이력과 정합성이 중요한 정보 위주로 저장한다.

## 3-3. 앱은 가공된 결과를 받는다
앱은 DB 원본 테이블 구조를 그대로 받지 않는다.  
API 응답은 화면에 맞춘 가공 결과 중심으로 설계한다.

## 3-4. 운영자 수동 개입을 고려한다
지지선/저항선과 상태값은 초기에는 운영자 수정 가능성이 있으므로,  
관리자 검토와 수정이 가능한 형태를 유지한다.

## 3-5. 상태와 이벤트를 분리한다
현재 상태는 상태 테이블 또는 상태 필드로 관리하고,  
상태 변화 이력은 이벤트 테이블에 별도로 남긴다.

---

# 4. 전체 엔티티 개요

MVP 기준 핵심 엔티티는 아래와 같다.

1. users
2. stocks
3. price_levels
4. daily_bars
5. minute_bars
6. support_states
7. signal_events
8. watchlists
9. themes
10. theme_stock_maps
11. content_posts
12. notifications
13. admin_audit_logs

---

# 5. 테이블 관계 개요

```text
users
  └─ watchlists
       └─ stocks

stocks
  ├─ price_levels
  ├─ daily_bars
  ├─ minute_bars
  ├─ support_states
  ├─ signal_events
  ├─ content_posts
  └─ theme_stock_maps ─ themes

users
  └─ notifications

admin users / operator actions
  └─ admin_audit_logs

6. 공통 필드 규칙

모든 주요 테이블은 아래 공통 원칙을 가능한 한 따른다.

6-1. 기본 시간 필드

created_at

updated_at

6-2. 논리 삭제

초기 MVP에서는 필요 최소화하되, 운영성 있는 엔티티에는 아래 필드 고려 가능

is_active

deleted_at

6-3. 기본 키

단순 증가형 bigint 또는 UUID 중 선택

종목코드처럼 자연키가 충분한 경우 자연키 사용 가능

6-4. 시간대 규칙

DB에는 timezone 포함 timestamp 저장 권장

API 응답도 ISO 8601 형식 사용 권장

7. 핵심 enum / 상태값 정의
7-1. market_type

KOSPI

KOSDAQ

ETF

ETN

OTHER

7-2. signal_type

SUPPORT_NEAR

SUPPORT_TESTING

SUPPORT_DIRECT_REBOUND_SUCCESS

SUPPORT_BREAK_REBOUND_SUCCESS

SUPPORT_REUSABLE

SUPPORT_INVALIDATED

RESISTANCE_NEAR

RESISTANCE_BREAKOUT

RESISTANCE_REJECTED

7-3. support_status

WAITING

TESTING_SUPPORT

DIRECT_REBOUND_SUCCESS

BREAK_REBOUND_SUCCESS

REUSABLE

INVALID

7-4. notification_type

PRICE_SIGNAL

THEME_SIGNAL

CONTENT_UPDATE

ADMIN_NOTICE

7-5. content_category

STOCK_ANALYSIS

THEME_BRIEF

MARKET_SUMMARY

SHORTS

NOTICE

7-6. user_role

USER

ADMIN

OPERATOR

8. 테이블 상세 정의
8-1. users
목적

앱 사용자 기본 정보 저장

주요 필드

id

email

password_hash 또는 외부 로그인 식별자

nickname

role

is_active

created_at

updated_at

권장 스키마

id: bigint or uuid, PK

email: varchar, unique, nullable 가능(소셜로그인 전략에 따라)

nickname: varchar(50)

role: enum(user_role), default USER

is_active: boolean

created_at: timestamp

updated_at: timestamp

비고

초기 MVP에서 비회원 모드가 있다면 최소화 가능
단, 관심종목 저장과 알림 개인화까지 가려면 계정 테이블이 필요하다.

8-2. stocks
목적

종목 마스터 정보 저장

주요 필드

code

name

market_type

sector

theme_tags_summary

is_active

created_at

updated_at

권장 스키마

code: varchar(20), PK

name: varchar(100), index

market_type: enum(market_type)

sector: varchar(100), nullable

theme_tags_summary: varchar(255), nullable

is_active: boolean, default true

created_at

updated_at

인덱스

idx_stocks_name

idx_stocks_market_type

비고

종목 검색 화면과 테마 연결의 기준 테이블

8-3. price_levels
목적

운영자가 등록한 종목별 지지선/저항선 저장

주요 필드

id

stock_code

level_type

level_price

level_order

memo

source_type

is_active

created_by

created_at

updated_at

권장 스키마

id: bigint, PK

stock_code: FK -> stocks.code

level_type: varchar(20)
예: SUPPORT, RESISTANCE

level_price: numeric(18,4)

level_order: int
예: 1, 2

memo: text, nullable

source_type: varchar(20)
예: MANUAL, SYSTEM

is_active: boolean

created_by: FK -> users.id nullable

created_at

updated_at

인덱스

idx_price_levels_stock_code

idx_price_levels_stock_code_type_active

비고

초기에는 support_1, support_2처럼 컬럼형보다
행(row) 기반 구조가 확장성이 좋다.

8-4. daily_bars
목적

종목별 일봉 OHLCV 저장

주요 필드

id

stock_code

trade_date

open_price

high_price

low_price

close_price

volume

source_name

created_at

권장 스키마

id: bigint, PK

stock_code: FK -> stocks.code

trade_date: date

open_price: numeric(18,4)

high_price: numeric(18,4)

low_price: numeric(18,4)

close_price: numeric(18,4)

volume: bigint

source_name: varchar(50), nullable

created_at

유니크 제약

(stock_code, trade_date) unique

인덱스

idx_daily_bars_stock_date

8-5. minute_bars
목적

종목별 분봉 OHLCV 저장

주요 필드

id

stock_code

bar_time

open_price

high_price

low_price

close_price

volume

created_at

권장 스키마

id: bigint, PK

stock_code: FK -> stocks.code

bar_time: timestamp

open_price

high_price

low_price

close_price

volume

created_at

유니크 제약

(stock_code, bar_time) unique

인덱스

idx_minute_bars_stock_time

비고

초기 MVP에서 저장 범위를 제한할 수 있음
예: 관심종목 중심 1분봉만 저장

8-6. support_states
목적

각 지지선의 현재 상태와 판정 관련 핵심 수치 저장

주요 필드

id

price_level_id

stock_code

support_price

status

reaction_type

first_touched_at

last_touched_at

testing_low_price

testing_high_price

breakdown_occurred

breakdown_at

breakdown_low_price

rebound_start_price

rebound_high_price

rebound_pct

previous_major_high

reusable_confirmed_at

invalidated_at

invalid_reason

updated_at

created_at

권장 스키마

id: bigint, PK

price_level_id: FK -> price_levels.id

stock_code: FK -> stocks.code

support_price: numeric(18,4)

status: enum(support_status)

reaction_type: varchar(20), nullable
예: DIRECT, BREAK_REBOUND

first_touched_at: timestamp, nullable

last_touched_at: timestamp, nullable

testing_low_price: numeric(18,4), nullable

testing_high_price: numeric(18,4), nullable

breakdown_occurred: boolean, default false

breakdown_at: timestamp, nullable

breakdown_low_price: numeric(18,4), nullable

rebound_start_price: numeric(18,4), nullable

rebound_high_price: numeric(18,4), nullable

rebound_pct: numeric(8,4), nullable

previous_major_high: numeric(18,4), nullable

reusable_confirmed_at: timestamp, nullable

invalidated_at: timestamp, nullable

invalid_reason: varchar(255), nullable

created_at

updated_at

유니크 제약

(price_level_id) unique
하나의 활성 지지선 row당 현재 상태 1개 유지

인덱스

idx_support_states_stock_code

idx_support_states_status

8-7. signal_events
목적

상태 변화나 신호 발생 이력 저장

주요 필드

id

stock_code

price_level_id

support_state_id

signal_type

current_price

level_price

distance_pct

message

event_time

is_notified

created_at

권장 스키마

id: bigint, PK

stock_code: FK -> stocks.code

price_level_id: FK -> price_levels.id, nullable

support_state_id: FK -> support_states.id, nullable

signal_type: enum(signal_type)

current_price: numeric(18,4), nullable

level_price: numeric(18,4), nullable

distance_pct: numeric(8,4), nullable

message: varchar(255), nullable

event_time: timestamp

is_notified: boolean, default false

created_at

인덱스

idx_signal_events_stock_time

idx_signal_events_type_time

idx_signal_events_notified

비고

현재 상태와 별개로 이벤트 이력 조회, 푸시 발송 추적, 관리자 검토에 사용

8-8. watchlists
목적

사용자 관심종목 저장

주요 필드

id

user_id

stock_code

alert_enabled

watch_group

created_at

updated_at

권장 스키마

id: bigint, PK

user_id: FK -> users.id

stock_code: FK -> stocks.code

alert_enabled: boolean, default true

watch_group: varchar(50), nullable
예: DEFAULT, SHORT_TERM, HOLDING

created_at

updated_at

유니크 제약

(user_id, stock_code) unique

인덱스

idx_watchlists_user_id

idx_watchlists_user_alert

8-9. themes
목적

테마 마스터 정보 저장

주요 필드

id

name

score

summary

is_active

updated_at

created_at

권장 스키마

id: bigint, PK

name: varchar(100), unique

score: numeric(8,2), nullable

summary: varchar(255), nullable

is_active: boolean

created_at

updated_at

인덱스

idx_themes_score

idx_themes_active

8-10. theme_stock_maps
목적

테마와 종목 연결 저장

주요 필드

id

theme_id

stock_code

role_type

score

created_at

updated_at

권장 스키마

id: bigint, PK

theme_id: FK -> themes.id

stock_code: FK -> stocks.code

role_type: varchar(20)
예: LEADER, FOLLOWER

score: numeric(8,2), nullable

created_at

updated_at

유니크 제약

(theme_id, stock_code) unique

인덱스

idx_theme_stock_maps_theme_id

idx_theme_stock_maps_stock_code

8-11. content_posts
목적

앱/웹/쇼츠와 연결되는 콘텐츠 메타데이터 저장

주요 필드

id

category

stock_code

theme_id

title

summary

external_url

thumbnail_url

published_at

created_at

updated_at

권장 스키마

id: bigint, PK

category: enum(content_category)

stock_code: FK -> stocks.code, nullable

theme_id: FK -> themes.id, nullable

title: varchar(255)

summary: text, nullable

external_url: text, nullable

thumbnail_url: text, nullable

published_at: timestamp, nullable

created_at

updated_at

인덱스

idx_content_posts_category_published

idx_content_posts_stock_code

idx_content_posts_theme_id

8-12. notifications
목적

사용자에게 발송된 알림 저장

주요 필드

id

user_id

stock_code

signal_event_id

type

title

message

sent_at

clicked_at

is_read

created_at

권장 스키마

id: bigint, PK

user_id: FK -> users.id

stock_code: FK -> stocks.code, nullable

signal_event_id: FK -> signal_events.id, nullable

type: enum(notification_type)

title: varchar(255)

message: varchar(500)

sent_at: timestamp, nullable

clicked_at: timestamp, nullable

is_read: boolean, default false

created_at

인덱스

idx_notifications_user_id

idx_notifications_user_read

idx_notifications_signal_event_id

8-13. admin_audit_logs
목적

운영자 개입 기록 저장

주요 필드

id

admin_user_id

target_type

target_id

action_type

before_data

after_data

memo

created_at

권장 스키마

id: bigint, PK

admin_user_id: FK -> users.id

target_type: varchar(50)
예: PRICE_LEVEL, SUPPORT_STATE, THEME

target_id: varchar(100)

action_type: varchar(50)
예: CREATE, UPDATE, FORCE_STATUS_CHANGE, DELETE

before_data: jsonb, nullable

after_data: jsonb, nullable

memo: text, nullable

created_at

인덱스

idx_admin_audit_logs_admin_user_id

idx_admin_audit_logs_target_type_id

9. 추천 ER 관점 요약
9-1. 종목 기준 핵심 연결

stocks 1 : N price_levels

stocks 1 : N daily_bars

stocks 1 : N minute_bars

stocks 1 : N signal_events

stocks 1 : N content_posts

9-2. 지지선 기준 핵심 연결

price_levels 1 : 1 support_states

price_levels 1 : N signal_events

9-3. 사용자 기준 핵심 연결

users 1 : N watchlists

users 1 : N notifications

10. API 설계 원칙
10-1. 화면 중심 API로 설계한다

앱은 테이블 단위가 아니라 화면 단위로 데이터를 받는다.

예:

홈 API

관심종목 API

종목 상세 API

테마 API

10-2. 앱에 불필요한 내부 필드는 숨긴다

예:

내부 운영 메모

불필요한 raw state history

백오피스 전용 필드

10-3. 공통 응답 포맷을 유지한다

모든 API는 가능하면 같은 구조를 사용한다.

10-4. 상태값은 문구와 함께 내려준다

앱은 enum만으로 처리하지 않고,
표시용 label과 severity를 함께 받는 것이 좋다.

11. 공통 API 응답 포맷

모든 API는 아래 구조를 기본으로 한다.

{
  "success": true,
  "message": "ok",
  "data": {},
  "error_code": null
}
필드 설명

success: 요청 성공 여부

message: 간단한 결과 메시지

data: 실제 응답 데이터

error_code: 실패 시 코드, 성공 시 null

12. 핵심 API 목록
12-1. 홈
GET /api/v1/home
목적

홈 화면에 필요한 데이터를 한 번에 조회

인증

선택
비로그인 허용 가능, 로그인 시 개인화 데이터 포함

응답 data 예시 구조
{
  "market_summary": {
    "headline": "코스피 약보합, 반도체 강세"
  },
  "featured_stocks": [
    {
      "stock_code": "005930",
      "stock_name": "삼성전자",
      "current_price": 66100,
      "change_pct": 1.25,
      "status": {
        "code": "TESTING_SUPPORT",
        "label": "지지선 반응 확인 중",
        "severity": "watch"
      },
      "summary": "박스 하단 재접근 구간"
    }
  ],
  "watchlist_signal_summary": {
    "support_near_count": 2,
    "resistance_near_count": 1,
    "warning_count": 1
  },
  "themes": [
    {
      "theme_id": 1,
      "name": "AI 반도체",
      "score": 87,
      "leader_stock": {
        "stock_code": "000660",
        "stock_name": "SK하이닉스"
      },
      "summary": "메모리/장비 동반 강세"
    }
  ],
  "recent_contents": [
    {
      "content_id": 101,
      "category": "STOCK_ANALYSIS",
      "title": "삼성전자 지지선 관찰 포인트",
      "summary": "지지선 부근 재테스트 구간",
      "external_url": "https://example.com/post/101"
    }
  ]
}
12-2. 종목 검색
GET /api/v1/stocks/search?q={keyword}
목적

종목 검색 화면에서 종목명 또는 코드로 검색

인증

불필요

요청 파라미터

q: string, required

응답 data 예시
{
  "items": [
    {
      "stock_code": "005930",
      "stock_name": "삼성전자",
      "market_type": "KOSPI"
    }
  ]
}
12-3. 종목 상세
GET /api/v1/stocks/{stock_code}
목적

종목 상세 화면 데이터 조회

인증

선택
로그인 시 관심종목 여부/알림 여부 포함 가능

응답 data 예시
{
  "stock": {
    "stock_code": "005930",
    "stock_name": "삼성전자",
    "market_type": "KOSPI"
  },
  "price": {
    "current_price": 66100,
    "change_value": 800,
    "change_pct": 1.23,
    "day_high": 66400,
    "day_low": 65300,
    "volume": 12345678,
    "updated_at": "2026-03-19T10:20:00+09:00"
  },
  "status": {
    "code": "TESTING_SUPPORT",
    "label": "지지선 반응 확인 중",
    "severity": "watch"
  },
  "levels": [
    {
      "level_id": 11,
      "level_type": "SUPPORT",
      "level_order": 1,
      "level_price": 65200,
      "distance_pct": 1.38
    },
    {
      "level_id": 12,
      "level_type": "RESISTANCE",
      "level_order": 1,
      "level_price": 68500,
      "distance_pct": 3.63
    }
  ],
  "support_state": {
    "status": "TESTING_SUPPORT",
    "reaction_type": null,
    "first_touched_at": "2026-03-19T10:05:00+09:00",
    "rebound_pct": null
  },
  "scenario": {
    "base": "지지선 방어 여부 확인 구간",
    "bull": "거래량 동반 반등 시 1차 유효성 강화",
    "bear": "종가 기준 이탈 시 보수적 접근"
  },
  "reason_lines": [
    "지지선 부근에 재접근한 상태입니다.",
    "현재는 반응 확인이 우선입니다.",
    "종가 기준 이탈 여부를 체크해야 합니다."
  ],
  "chart": {
    "daily_bars": []
  },
  "related_themes": [],
  "related_contents": [],
  "watchlist": {
    "is_in_watchlist": true,
    "alert_enabled": true
  }
}
12-4. 종목 신호 이벤트 조회
GET /api/v1/stocks/{stock_code}/signals
목적

특정 종목의 최근 신호 이벤트 목록 조회

인증

선택

쿼리 파라미터 예시

limit

cursor 또는 page

응답 data 예시
{
  "items": [
    {
      "event_id": 999,
      "signal_type": "SUPPORT_NEAR",
      "label": "지지선 접근",
      "message": "지지선까지 1.4% 남음",
      "event_time": "2026-03-19T10:10:00+09:00"
    }
  ]
}
12-5. 관심종목 목록 조회
GET /api/v1/watchlist
목적

사용자의 관심종목 목록과 상태 요약 조회

인증

필수

응답 data 예시
{
  "items": [
    {
      "watchlist_id": 1,
      "stock_code": "005930",
      "stock_name": "삼성전자",
      "current_price": 66100,
      "change_pct": 1.23,
      "status": {
        "code": "TESTING_SUPPORT",
        "label": "지지선 반응 확인 중",
        "severity": "watch"
      },
      "nearest_support": {
        "price": 65200,
        "distance_pct": 1.38
      },
      "nearest_resistance": {
        "price": 68500,
        "distance_pct": 3.63
      },
      "summary": "박스 하단 재접근 구간",
      "alert_enabled": true
    }
  ],
  "summary": {
    "total_count": 12,
    "support_near_count": 2,
    "resistance_near_count": 1,
    "warning_count": 1
  }
}
12-6. 관심종목 추가
POST /api/v1/watchlist
목적

사용자의 관심종목 추가

인증

필수

요청 body
{
  "stock_code": "005930",
  "alert_enabled": true,
  "watch_group": "DEFAULT"
}
응답 data 예시
{
  "watchlist_id": 10,
  "stock_code": "005930",
  "alert_enabled": true
}
12-7. 관심종목 삭제
DELETE /api/v1/watchlist/{watchlist_id}
목적

관심종목 제거

인증

필수

응답 data 예시
{
  "deleted": true
}
12-8. 관심종목 알림 설정 변경
PATCH /api/v1/watchlist/{watchlist_id}/alert
목적

관심종목 단위 알림 ON/OFF 변경

인증

필수

요청 body
{
  "alert_enabled": false
}
응답 data 예시
{
  "watchlist_id": 10,
  "alert_enabled": false
}
12-9. 테마 목록 조회
GET /api/v1/themes
목적

테마 화면 목록 조회

인증

불필요 또는 선택

응답 data 예시
{
  "items": [
    {
      "theme_id": 1,
      "name": "AI 반도체",
      "score": 87,
      "summary": "메모리/장비 동반 강세",
      "leader_stock": {
        "stock_code": "000660",
        "stock_name": "SK하이닉스"
      },
      "follower_stocks": [
        {
          "stock_code": "042700",
          "stock_name": "한미반도체"
        }
      ]
    }
  ]
}
12-10. 알림 목록 조회
GET /api/v1/notifications
목적

사용자 알림 내역 조회

인증

필수

응답 data 예시
{
  "items": [
    {
      "notification_id": 1001,
      "type": "PRICE_SIGNAL",
      "title": "삼성전자 지지선 접근",
      "message": "지지선까지 1.4% 남았습니다.",
      "stock_code": "005930",
      "sent_at": "2026-03-19T10:11:00+09:00",
      "clicked_at": null,
      "is_read": false
    }
  ]
}
12-11. 알림 읽음 처리
PATCH /api/v1/notifications/{notification_id}/read
목적

알림 읽음 처리

인증

필수

요청 body
{
  "is_read": true
}
응답 data 예시
{
  "notification_id": 1001,
  "is_read": true
}
12-12. 사용자 알림 설정 조회
GET /api/v1/me/alert-settings
목적

사용자 전체 알림 설정 조회

인증

필수

응답 data 예시
{
  "all_enabled": true,
  "price_signal_enabled": true,
  "theme_signal_enabled": true,
  "content_update_enabled": false,
  "intraday_enabled": true
}
12-13. 사용자 알림 설정 변경
PATCH /api/v1/me/alert-settings
목적

사용자 전체 알림 설정 변경

인증

필수

요청 body
{
  "all_enabled": true,
  "price_signal_enabled": true,
  "theme_signal_enabled": false,
  "content_update_enabled": false,
  "intraday_enabled": true
}
13. 관리자 API 목록
13-1. 종목 등록/수정
POST /api/v1/admin/stocks
PATCH /api/v1/admin/stocks/{stock_code}
목적

종목 마스터 관리

13-2. 가격 레벨 등록/수정
POST /api/v1/admin/price-levels
PATCH /api/v1/admin/price-levels/{level_id}
목적

지지선/저항선 수동 입력 및 수정

요청 body 예시
{
  "stock_code": "005930",
  "level_type": "SUPPORT",
  "level_order": 1,
  "level_price": 65200,
  "memo": "박스 하단 주요 지지"
}
13-3. 지지선 상태 강제 수정
PATCH /api/v1/admin/support-states/{support_state_id}
목적

운영자 수동 상태 수정

요청 body 예시
{
  "status": "INVALID",
  "memo": "신고가 실패 후 구조 무효 확정"
}
13-4. 테마 등록/수정
POST /api/v1/admin/themes
PATCH /api/v1/admin/themes/{theme_id}
13-5. 푸시 발송
POST /api/v1/admin/push/send
목적

운영자 수동 푸시 발송

13-6. 이벤트 목록 조회
GET /api/v1/admin/signal-events
목적

최근 신호 이벤트 검토

14. API 응답용 공통 객체 정의
14-1. 상태 객체
{
  "code": "TESTING_SUPPORT",
  "label": "지지선 반응 확인 중",
  "severity": "watch"
}
필드 설명

code: 내부 상태값

label: 사용자 표시 문구

severity: UI 색상/강도 기준
예: watch, positive, warning, negative

14-2. 종목 요약 객체
{
  "stock_code": "005930",
  "stock_name": "삼성전자",
  "current_price": 66100,
  "change_pct": 1.23,
  "status": {
    "code": "TESTING_SUPPORT",
    "label": "지지선 반응 확인 중",
    "severity": "watch"
  },
  "summary": "박스 하단 재접근 구간"
}
14-3. 레벨 객체
{
  "level_id": 11,
  "level_type": "SUPPORT",
  "level_order": 1,
  "level_price": 65200,
  "distance_pct": 1.38
}
14-4. 알림 객체
{
  "notification_id": 1001,
  "type": "PRICE_SIGNAL",
  "title": "삼성전자 지지선 접근",
  "message": "지지선까지 1.4% 남았습니다.",
  "stock_code": "005930",
  "sent_at": "2026-03-19T10:11:00+09:00",
  "is_read": false
}
15. 인증 정책
15-1. 비로그인 가능 API

종목 검색

홈(비개인화 버전)

종목 상세(비개인화 버전)

테마 목록

콘텐츠 일부

15-2. 로그인 필수 API

관심종목 조회/추가/삭제

알림 설정 조회/수정

알림 목록 조회

최근 본 종목

사용자별 개인화 데이터

15-3. 관리자 권한 API

종목 등록/수정

가격 레벨 등록/수정

상태 강제 수정

푸시 수동 발송

이벤트 검토

운영 로그 확인

16. 에러 코드 정책
공통 에러 코드

BAD_REQUEST

UNAUTHORIZED

FORBIDDEN

NOT_FOUND

INTERNAL_ERROR

도메인 에러 코드

STOCK_NOT_FOUND

WATCHLIST_DUPLICATED

WATCHLIST_NOT_FOUND

PRICE_LEVEL_NOT_FOUND

SUPPORT_STATE_NOT_FOUND

SIGNAL_EVENT_NOT_FOUND

NOTIFICATION_NOT_FOUND

INVALID_SIGNAL_STATE

INVALID_LEVEL_TYPE

ALERT_SETTING_INVALID

에러 응답 예시
{
  "success": false,
  "message": "관심종목에 이미 추가된 종목입니다.",
  "data": null,
  "error_code": "WATCHLIST_DUPLICATED"
}
17. 정렬 / 페이지네이션 기준
17-1. 목록 API 공통 원칙

목록 API는 기본적으로 최신순 또는 중요도순을 따른다.

17-2. 페이지네이션 방식

초기 MVP에서는 아래 중 하나를 선택한다.

offset/limit

cursor 기반

초기 구현 단순화를 위해 offset/limit를 먼저 사용할 수 있다.

17-3. 정렬 예시
관심종목

최근 신호순

지지선 접근순

등락률순

테마

점수순

최신순

알림

sent_at desc

18. DB 인덱스 우선순위

초기 MVP에서 특히 중요한 인덱스는 아래와 같다.

필수 우선 인덱스

stocks.name

daily_bars(stock_code, trade_date)

minute_bars(stock_code, bar_time)

watchlists(user_id, stock_code)

support_states(stock_code, status)

signal_events(stock_code, event_time)

notifications(user_id, is_read, sent_at)

19. 추천 API 구현 우선순위
1차 필수

GET /api/v1/home

GET /api/v1/stocks/search

GET /api/v1/stocks/{stock_code}

GET /api/v1/watchlist

POST /api/v1/watchlist

DELETE /api/v1/watchlist/{id}

PATCH /api/v1/watchlist/{id}/alert

2차 필수

GET /api/v1/themes

GET /api/v1/notifications

PATCH /api/v1/notifications/{id}/read

GET /api/v1/stocks/{stock_code}/signals

3차 운영

관리자 종목/레벨/상태 수정 API

운영자 푸시 API

운영 로그 API

20. 예시 구현용 DTO 관점 정리
20-1. HomeResponse

market_summary

featured_stocks

watchlist_signal_summary

themes

recent_contents

20-2. StockDetailResponse

stock

price

status

levels

support_state

scenario

reason_lines

chart

related_themes

related_contents

watchlist

20-3. WatchlistItemResponse

watchlist_id

stock_code

stock_name

current_price

change_pct

status

nearest_support

nearest_resistance

summary

alert_enabled

21. 운영상 주의사항
21-1. 상태값은 API에서 label까지 함께 제공한다

앱이 상태 문구 매핑을 모두 들고 있을 필요가 없다.
백엔드에서 상태 문구를 함께 주는 것이 운영 변경에 유리하다.

21-2. raw 데이터와 표시 데이터는 분리한다

예:

DB에는 TESTING_SUPPORT

API에는 label: "지지선 반응 확인 중"

21-3. 운영자 수정 이력은 반드시 로그를 남긴다

초기 MVP라도 사람이 상태를 바꾸는 순간 추적 가능해야 한다.

21-4. 이벤트와 알림은 분리한다

이벤트가 발생했다고 항상 알림을 보내는 것은 아니다.
이벤트 → 알림 발송 여부 판단 → 알림 저장 구조로 간다.

22. 개발 체크리스트
DB

 users 테이블 생성

 stocks 테이블 생성

 price_levels 테이블 생성

 daily_bars 테이블 생성

 minute_bars 테이블 생성

 support_states 테이블 생성

 signal_events 테이블 생성

 watchlists 테이블 생성

 themes / theme_stock_maps 테이블 생성

 content_posts 테이블 생성

 notifications 테이블 생성

 admin_audit_logs 테이블 생성

API

 홈 API 구현

 종목 검색 API 구현

 종목 상세 API 구현

 종목 신호 조회 API 구현

 관심종목 조회 API 구현

 관심종목 추가 API 구현

 관심종목 삭제 API 구현

 관심종목 알림 설정 변경 API 구현

 테마 목록 API 구현

 알림 목록 API 구현

 알림 읽음 처리 API 구현

 사용자 알림 설정 API 구현

운영

 관리자 종목 관리 API 구현

 관리자 레벨 관리 API 구현

 관리자 상태 강제 수정 API 구현

 관리자 푸시 발송 API 구현

 운영 로그 기록 구현

23. 최종 요약

지지저항Lab 앱 MVP의 DB/API 구조는
종목, 가격 레벨, 지지선 상태, 이벤트, 관심종목, 테마, 콘텐츠, 알림을 중심으로 구성한다.

핵심은 아래와 같다.

종목 마스터와 봉 데이터는 기반 데이터다.

가격 레벨과 지지선 상태는 핵심 엔진 데이터다.

이벤트는 상태 변화 이력과 알림 근거 데이터다.

관심종목과 알림은 사용자 반복 사용의 핵심 데이터다.

API는 테이블 중심이 아니라 화면 중심으로 설계한다.

즉, 본 문서는 지지저항Lab의 로직과 UI를 실제 백엔드 구조로 연결하는
구현 기준 문서이다.



  
