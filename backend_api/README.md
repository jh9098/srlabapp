# backend_api

지지저항Lab MVP용 FastAPI 백엔드입니다.

## 실행

1. DB 마이그레이션 적용
   - `alembic upgrade head`
2. 최소 seed 데이터 입력
   - `python scripts/seed_minimum_data.py`
3. 서버 실행
   - `uvicorn app.main:app --reload`

## 테스트

- `pytest`
