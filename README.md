# srlabapp

지지저항Lab MVP 저장소입니다.

현재 저장소에는 기존 Flutter 앱 프로젝트와 함께, MVP 1단계 범위에 맞춘 `backend_api` FastAPI 초기 구조가 추가되어 있습니다.

## 이번 단계에서 추가된 백엔드 범위

- FastAPI 프로젝트 기본 구조 생성
- SQLAlchemy/Alembic 설정 추가
- 핵심 MVP 테이블 모델 추가
  - `stocks`
  - `price_levels`
  - `support_states`
  - `watchlists`
- 초기 Alembic 마이그레이션 추가
- 로컬 실행 가이드 추가

## 저장소 구조

```text
/docs
/backend_api
/lib
/android
/ios
...
```

- `docs`: 제품/로직/DB/API 명세 문서
- `backend_api`: FastAPI + SQLAlchemy + Alembic 백엔드
- 나머지 Flutter 관련 디렉터리는 기존 앱 프로젝트 자산입니다.

## backend_api 로컬 실행 방법

### 1) Python 가상환경 생성

```bash
cd backend_api
python3 -m venv .venv
source .venv/bin/activate
```

### 2) 의존성 설치

```bash
pip install -e .
```

### 3) 환경변수 파일 준비

```bash
cp .env.example .env
```

기본 `DATABASE_URL`은 PostgreSQL 예시입니다.

```env
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/srlab
```

### 4) PostgreSQL 준비

로컬 PostgreSQL에 `srlab` 데이터베이스를 생성합니다.

예시:

```bash
createdb srlab
```

### 5) 마이그레이션 적용

```bash
alembic upgrade head
```

### 6) 개발 서버 실행

```bash
uvicorn app.main:app --reload
```

실행 후 확인 주소:

- 앱 루트: `http://127.0.0.1:8000/`
- 헬스체크: `http://127.0.0.1:8000/api/v1/health`
- Swagger: `http://127.0.0.1:8000/docs`

## backend_api 구조 설명

```text
backend_api/
  app/
    api/
      v1/
    core/
    db/
    models/
    schemas/
    repositories/
    services/
    tasks/
    utils/
  alembic/
```

### 왜 이렇게 나눴나요?

비전공자 관점에서 쉽게 설명하면 아래와 같습니다.

- `api/`: 외부에서 호출하는 URL 입구
- `core/`: 설정값 같은 공통 환경
- `db/`: DB 연결, Base 정의
- `models/`: 실제 테이블 구조
- `schemas/`: API 응답/요청 형식
- `repositories/`: DB 조회 로직을 모아둘 자리
- `services/`: 핵심 비즈니스 로직을 모아둘 자리
- `tasks/`: 배치/비동기 작업을 모아둘 자리
- `utils/`: 공용 유틸 함수 자리

## 현재 구현 상태 메모

이번 작업은 **백엔드 초기 구조 생성 단계까지만** 포함합니다.
아직 아래는 구현하지 않았습니다.

- 종목 검색 API
- 종목 상세 API
- 관심종목 CRUD API
- 지지선 상태 계산 서비스
- 알림/푸시 기능
- 관리자 웹 기능

## Flutter

Flutter 앱 코드는 이번 작업 범위에 포함하지 않아 수정하지 않았습니다.
