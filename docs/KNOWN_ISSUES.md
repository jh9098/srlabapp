# KNOWN_ISSUES

버전: v1.0  
작성일: 2026-03-20  
상태: 현재 저장소 기준 작성 완료

---

## 1. 문서 목적

이 문서는 현재 `srlabapp` 에서 **이미 알고 있는 제약, 주의사항, 출시 전 확인 포인트**를 정리한 문서다.

원칙은 아래와 같다.

- 숨기지 않는다.
- 현재 기능 상태를 기준으로 적는다.
- 운영자가 즉시 대응 가능한 형태로 적는다.

---

## 2. 현재 확인된 known issues / 제약

### K-1. Firebase/FCM 실제 수신 검증은 외부 작업이 남아 있음

설명:
- 저장소에는 `firebase_messaging` 연결 코드와 backend FCM provider 가 있다.
- 하지만 실제 프로젝트 생성, 앱 등록, 키 주입, 실기기 수신 검증은 별도 작업이다.

영향:
- 푸시를 핵심 출시 기능으로 포함하면 프로덕션 출시 blocker 가 될 수 있다.

대응:
- staging 또는 prod-like 환경에서 실기기 검증을 먼저 완료한다.

### K-2. FCM 설정이 없으면 fallback 동작을 사용함

설명:
- 현재 코드는 FCM 자격증명이 없을 때 DB 저장 + 로그 기록 fallback 으로 동작한다.

영향:
- 알림함에는 쌓여도 실제 디바이스 푸시는 오지 않을 수 있다.

대응:
- 운영 환경에서는 `FCM_ENABLED`, `FCM_SERVER_KEY` 또는 관련 자격증명 설정 여부를 반드시 점검한다.

### K-3. 관리자 권한은 단일 관리자 계정 중심

설명:
- 현재 관리자 로그인은 환경변수 기반 계정 + Bearer 토큰 방식이다.
- 세부 role 분리와 계정별 권한 정책은 아직 단순하다.

영향:
- 운영자가 여러 명일 때 권한 구분과 책임 분리가 약하다.

대응:
- 출시 후 2순위 작업으로 role 분리를 진행한다.

### K-4. 마이 화면 일부 문구는 추후 연결 예정

설명:
- `문의 / 공지` 영역은 아직 추후 연결 예정 문구가 남아 있다.

영향:
- 사용자가 완성된 고객지원 기능으로 오해할 수 있다.

대응:
- 출시 시 공지/문의 기능을 비노출하거나 명확한 문구로 정리한다.

### K-5. 운영 인프라와 스토어 배포는 아직 별도 준비가 필요

설명:
- 운영 PostgreSQL, HTTPS, reverse proxy, 스토어 서명/배포 설정은 문서화되어 있지만 실제 외부 준비가 남아 있다.

영향:
- 코드가 있어도 바로 상용 운영으로 전환할 수는 없다.

대응:
- `docs/08_운영배포_환경분리_가이드.md` 순서대로 환경 분리와 smoke test 를 먼저 진행한다.

---

## 3. 출시 전 반드시 다시 확인할 항목

- [ ] 실제 API base URL 이 운영 환경 값인지
- [ ] 관리자 비밀번호가 기본값이 아닌지
- [ ] health endpoint 가 정상인지
- [ ] signal batch dry-run / 실제 실행이 되는지
- [ ] dispatcher 가 pending 을 소비하는지
- [ ] 실기기 푸시가 최소 1회 이상 도착하는지
- [ ] known issues 중 blocker 항목이 해소되었는지

---

## 4. 운영 중 문제 발생 시 우선 확인 순서

1. health endpoint 확인
2. 최근 배포 또는 환경변수 변경 여부 확인
3. signal batch 최근 실행 결과 확인
4. notification dispatcher 결과 확인
5. 관리자에서 수동 입력 데이터 변경 여부 확인
6. 디바이스 토큰 / FCM 자격증명 상태 확인

---

## 5. 관련 문서

- `docs/QA_CHECKLIST.md`
- `docs/RELEASE_READINESS.md`
- `docs/POST_LAUNCH_ROADMAP.md`
- `docs/08_운영배포_환경분리_가이드.md`
- `TODO_MVP_GAPS.md`

---

## 6. Cloud Firestore 읽기 비용 검토

현재 프로젝트는 Cloud Firestore를 사용하지 않는다.

따라서 이 known issues 문서에 적힌 제약들도 **Firestore read 비용과 직접 관련이 없다**.
Firestore read 절감 조치가 필요한 상태는 아니며, 대신 PostgreSQL/FCM/배치 운영 비용을 보는 것이 맞다.
