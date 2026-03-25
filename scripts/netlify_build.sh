#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
# 1. Flutter 설치 (Netlify에는 Flutter가 없으므로 직접 설치)
# ──────────────────────────────────────────────
FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.0}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_HOME="$HOME/.flutter-sdk"
export PATH="$FLUTTER_HOME/bin:$PATH"

if ! command -v flutter &>/dev/null; then
  echo "[netlify-build] Flutter ${FLUTTER_VERSION} 설치 중..."
  git clone --depth 1 \
    --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git \
    "$FLUTTER_HOME"
  echo "[netlify-build] Flutter 설치 완료"
else
  echo "[netlify-build] Flutter 이미 설치됨: $(flutter --version --machine | head -1)"
fi

# Flutter 웹 엔진 및 툴 프리워밍
flutter precache --web --no-android --no-ios
flutter config --enable-web

# ──────────────────────────────────────────────
# 2. 필수 환경변수 체크
# ──────────────────────────────────────────────
required_vars=(
  FIREBASE_API_KEY
  FIREBASE_PROJECT_ID
  FIREBASE_MESSAGING_SENDER_ID
  FIREBASE_WEB_APP_ID
)

missing=()
for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    missing+=("${var_name}")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "[netlify-build] 필수 환경변수가 비어 있습니다: ${missing[*]}" >&2
  echo "[netlify-build] Netlify Site settings > Environment variables 에 값을 입력해 주세요." >&2
  exit 1
fi

# ──────────────────────────────────────────────
# 3. 빌드
# ──────────────────────────────────────────────
flutter pub get

flutter build web --release \
  --dart-define=APP_ENV="${APP_ENV:-prod}" \
  --dart-define=API_BASE_URL="${API_BASE_URL:-}" \
  --dart-define=USER_IDENTIFIER="${USER_IDENTIFIER:-netlify-web-user}" \
  --dart-define=ENABLE_VERBOSE_LOG="${ENABLE_VERBOSE_LOG:-false}" \
  --dart-define=USE_FIREBASE_ONLY="${USE_FIREBASE_ONLY:-true}" \
  --dart-define=ENABLE_BACKEND_FEATURES="${ENABLE_BACKEND_FEATURES:-false}" \
  --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY}" \
  --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID}" \
  --dart-define=FIREBASE_WEB_APP_ID="${FIREBASE_WEB_APP_ID}" \
  --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID:-}" \
  --dart-define=FIREBASE_ANDROID_APP_ID="${FIREBASE_ANDROID_APP_ID:-}" \
  --dart-define=FIREBASE_IOS_BUNDLE_ID="${FIREBASE_IOS_BUNDLE_ID:-}" \
  --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN:-}" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET:-}" \
  --dart-define=FIREBASE_MEASUREMENT_ID="${FIREBASE_MEASUREMENT_ID:-}" \
  --dart-define=FIREBASE_WEB_VAPID_KEY="${FIREBASE_WEB_VAPID_KEY:-}" \
  --dart-define=GOOGLE_CLIENT_ID="${GOOGLE_CLIENT_ID:-}" \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="${GOOGLE_SERVER_CLIENT_ID:-}" \
  --dart-define=KAKAO_OPENCHAT_URL="${KAKAO_OPENCHAT_URL:-}" \
  --dart-define=TELEGRAM_CHANNEL_URL="${TELEGRAM_CHANNEL_URL:-}"

echo "[netlify-build] 빌드 완료 → build/web"