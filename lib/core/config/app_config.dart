class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.userIdentifier,
  });

  final String apiBaseUrl;
  final String userIdentifier;

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000/api/v1',
      ),
      userIdentifier: String.fromEnvironment(
        'USER_IDENTIFIER',
        defaultValue: 'demo-user',
      ),
    );
  }
}
