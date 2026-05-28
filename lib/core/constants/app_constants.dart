class AppConstants {
  AppConstants._();

  // Backend base URL. MUST be supplied at build time:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  //   flutter build apk --dart-define=API_BASE_URL=https://api.host/api
  //
  // Default points at Android emulator → host loopback so dev works
  // without flags. Production builds MUST override via --dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static const Duration apiConnectTimeout = Duration(seconds: 30);
  static const Duration apiReceiveTimeout = Duration(seconds: 30);

  // SecureStorage keys
  static const String kAuthToken = 'auth_token';
  static const String kAuthUser = 'auth_user';
}
