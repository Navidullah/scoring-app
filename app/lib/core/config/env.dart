/// Environment-based configuration.
///
/// API base URL is never hardcoded — pass it at build/run time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
///
/// Defaults to the Android emulator loopback (10.0.2.2 maps to the host's
/// localhost). For web/desktop use http://localhost:3000/api.
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
