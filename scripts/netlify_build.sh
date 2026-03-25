#!/usr/bin/env bash
set -euo pipefail

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
