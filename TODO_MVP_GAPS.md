# MVP 코드-문서 정렬 TODO

## 현재 확인된 불일치

1. 문서 권장 구조에는 `frontend_app/`가 있지만, 현재 Flutter 앱은 저장소 루트(`lib/`, `android/`, `ios/`)에 있습니다.
2. 관리자 UI는 문서상 별도 앱(`admin_web/`) 구조를 권장하지만, 이번 단계에서는 빠른 운영 가능성을 위해 **정적 HTML 관리자**를 `admin_web/`에 추가했습니다.
3. 실제 푸시 provider(예: FCM)는 아직 실연동하지 않았고, provider 교체 가능한 `StubPushProvider` 기반 구조만 연결되어 있습니다.

## 후속 작업 권장

- Flutter 앱을 정말 `frontend_app/`로 분리할지 유지할지 결정하고 README/문서를 통일합니다.
- FCM 또는 다른 실제 push provider 연동 시 `PushProvider` 구현체를 추가하고 비동기 작업 큐를 연결합니다.
- 관리자 인증/권한을 헤더 기반 임시 방식에서 실제 인증 체계로 교체합니다.
- 수동 푸시 대상자를 단건이 아니라 세그먼트/다건 선택으로 확장합니다.
