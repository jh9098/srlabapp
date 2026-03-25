class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.userIdentifier,
    this.appEnv = 'dev',
    this.enableVerboseLog = true,
    required this.firebaseProjectId,
    required this.firebaseAppId,
    required this.firebaseApiKey,
    required this.firebaseMessagingSenderId,
    required this.firebaseIosBundleId,
    required this.firebaseAndroidAppId,
    required this.firebaseWebAppId,
    required this.firebaseWebVapidKey,
    required this.firebaseAuthDomain,
    required this.firebaseStorageBucket,
    required this.firebaseMeasurementId,
    this.useFirebaseOnly = true,
    this.enableBackendFeatures = false,
    this.googleClientId = '',
    this.googleServerClientId = '',
    this.kakaoOpenChatUrl = '',
    this.telegramChannelUrl = '',
  });

  final String apiBaseUrl;
  final String userIdentifier;
  final String appEnv;
  final bool enableVerboseLog;
  final String firebaseProjectId;
  final String firebaseAppId;
  final String firebaseApiKey;
  final String firebaseMessagingSenderId;
  final String firebaseIosBundleId;
  final String firebaseAndroidAppId;
  final String firebaseWebAppId;
  final String firebaseWebVapidKey;
  final String firebaseAuthDomain;
  final String firebaseStorageBucket;
  final String firebaseMeasurementId;

  /// Firebase direct read/write 중심으로 앱을 실행할지 여부.
  final bool useFirebaseOnly;

  /// 기존 FastAPI/백엔드 기능을 계속 사용할지 여부.
  final bool enableBackendFeatures;

  /// Google 로그인용 클라이언트 설정.
  final String googleClientId;
  final String googleServerClientId;
  final String kakaoOpenChatUrl;
  final String telegramChannelUrl;

  bool get isFirebaseConfigured {
    return firebaseProjectId.isNotEmpty &&
        firebaseApiKey.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        (firebaseAppId.isNotEmpty ||
            firebaseAndroidAppId.isNotEmpty ||
            firebaseWebAppId.isNotEmpty);
  }

  bool get isProduction => appEnv == 'prod';

  factory AppConfig.fromEnvironment() {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const useFirebaseOnly = bool.fromEnvironment(
      'USE_FIREBASE_ONLY',
      defaultValue: true,
    );
    const enableBackendFeatures = bool.fromEnvironment(
      'ENABLE_BACKEND_FEATURES',
      defaultValue: !useFirebaseOnly,
    );

    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000/api/v1',
      ),
      userIdentifier: String.fromEnvironment(
        'USER_IDENTIFIER',
        defaultValue: 'demo-user',
      ),
      appEnv: appEnv,
      enableVerboseLog: bool.fromEnvironment(
        'ENABLE_VERBOSE_LOG',
        defaultValue: appEnv != 'prod',
      ),
      firebaseProjectId: String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: '',
      ),
      firebaseAppId: String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '',
      ),
      firebaseApiKey: String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: '',
      ),
      firebaseMessagingSenderId: String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '',
      ),
      firebaseIosBundleId: String.fromEnvironment(
        'FIREBASE_IOS_BUNDLE_ID',
        defaultValue: '',
      ),
      firebaseAndroidAppId: String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
        defaultValue: '',
      ),
      firebaseWebAppId: String.fromEnvironment(
        'FIREBASE_WEB_APP_ID',
        defaultValue: '',
      ),
      firebaseWebVapidKey: String.fromEnvironment(
        'FIREBASE_WEB_VAPID_KEY',
        defaultValue: '',
      ),
      firebaseAuthDomain: String.fromEnvironment(
        'FIREBASE_AUTH_DOMAIN',
        defaultValue: '',
      ),
      firebaseStorageBucket: String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
        defaultValue: '',
      ),
      firebaseMeasurementId: String.fromEnvironment(
        'FIREBASE_MEASUREMENT_ID',
        defaultValue: '',
      ),
      useFirebaseOnly: useFirebaseOnly,
      enableBackendFeatures: enableBackendFeatures,
      googleClientId: String.fromEnvironment(
        'GOOGLE_CLIENT_ID',
        defaultValue: '',
      ),
      googleServerClientId: String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
        defaultValue: '',
      ),
      kakaoOpenChatUrl: String.fromEnvironment(
        'KAKAO_OPENCHAT_URL',
        defaultValue: '',
      ),
      telegramChannelUrl: String.fromEnvironment(
        'TELEGRAM_CHANNEL_URL',
        defaultValue: '',
      ),
    );
  }
}
