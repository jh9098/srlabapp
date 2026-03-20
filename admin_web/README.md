# admin_web

지지저항Lab 로컬 MVP용 관리자 웹입니다.

## 실행

```bash
cd admin_web
cp assets/env.example.js assets/env.js
python3 -m http.server 4173
```

브라우저에서 `http://127.0.0.1:4173` 접속 후 아래 순서로 사용합니다.

1. `API Base URL` 확인
2. 관리자 아이디 입력
3. 비밀번호 입력
4. 로그인
5. 대시보드 / 종목 / 레벨 / 상태 / 이벤트 / 홈 노출 / 테마 / 감사 로그 확인
6. 필요 시 수동 푸시 발송

## 환경 분리 방식

정적 관리자 웹은 `assets/env.js` 로 환경별 기본값을 주입합니다.

예시:

```js
window.__SRLAB_ADMIN_CONFIG__ = {
  appEnv: 'staging',
  apiBaseUrl: 'https://staging-api.example.com/api/v1',
  adminUsername: 'admin',
};
```

주의:

- 비밀번호는 넣지 않습니다.
- 운영용 API URL 만 환경별로 분리합니다.
- 로그인 실제 인증은 backend 환경변수 계정을 사용합니다.

## 로그인 방식

백엔드의 관리자 로그인 API를 사용합니다.

- `POST /api/v1/admin/auth/login`
- 로그인 성공 시 Bearer 토큰 저장
- 이후 관리자 API에 자동 적용

기본 로컬 계정은 `backend_api/.env.example` 기준입니다.

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=replace-with-admin-password
```
