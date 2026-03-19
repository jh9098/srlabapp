# admin_web

지지저항Lab 로컬 MVP용 관리자 웹입니다.

## 실행

```bash
cd admin_web
python3 -m http.server 4173
```

브라우저에서 `http://127.0.0.1:4173` 접속 후 아래 순서로 사용합니다.

1. `API Base URL` 입력
2. 관리자 아이디/비밀번호 입력
3. 로그인
4. 대시보드 / 종목 / 레벨 / 상태 / 이벤트 / 홈 노출 / 테마 / 감사 로그 확인
5. 필요 시 수동 푸시 발송

## 로그인 방식

백엔드의 관리자 로그인 API를 사용합니다.

- `POST /api/v1/admin/auth/login`
- 로그인 성공 시 Bearer 토큰 저장
- 이후 관리자 API에 자동 적용

기본 로컬 계정은 `backend_api/.env.example` 기준입니다.

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin1234
```
