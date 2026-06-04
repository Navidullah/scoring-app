/// Environment-based configuration.
///
/// API base URL defaults to the hosted (production) backend so release builds
/// work with no flags. Override at build/run time for local development:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://scoring-app-backend-xs6g.onrender.com/api',
  );

  /// Origin of the backend (without the trailing /api) — used to build the
  /// public live-match web link, e.g. `$webBaseUrl/m/{matchId}`.
  static String get webBaseUrl => apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// Public live scoreboard URL for a match.
  static String liveMatchUrl(String matchId) => '$webBaseUrl/m/$matchId';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
