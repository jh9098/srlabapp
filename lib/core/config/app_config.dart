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

  bool get isFirebaseConfigured {
    return firebaseProjectId.isNotEmpty &&
        firebaseApiKey.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        (firebaseAppId.isNotEmpty || firebaseAndroidAppId.isNotEmpty || firebaseWebAppId.isNotEmpty);
  }

  bool get isProduction => appEnv == 'prod';

  factory AppConfig.fromEnvironment() {
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
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
      enableVerboseLog: bool.fromEnvironment('ENABLE_VERBOSE_LOG', defaultValue: appEnv != 'prod'),
      firebaseProjectId: String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: ''),
      firebaseAppId: String.fromEnvironment('FIREBASE_APP_ID', defaultValue: ''),
      firebaseApiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: ''),
      firebaseMessagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: ''),
      firebaseIosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: ''),
      firebaseAndroidAppId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: ''),
      firebaseWebAppId: String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: ''),
      firebaseWebVapidKey: String.fromEnvironment('FIREBASE_WEB_VAPID_KEY', defaultValue: ''),
    );
  }
}
