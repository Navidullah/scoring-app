/// App-wide constants. No hardcoded strings in widgets — reference these.
class AppStrings {
  const AppStrings._();

  static const String appName = 'CricLive';
  static const String homeTitle = 'CricLive';
  static const String newMatch = 'New Match';
  static const String tournaments = 'Tournaments';
  static const String results = 'Results';
  static const String history = 'History';
  static const String leaderboards = 'Leaderboards';
  static const String settings = 'Settings';
  static const String noMatchesYet = 'No matches yet. Start a new match!';
}

/// Hive box names — central registry so we never typo a box key.
class HiveBoxes {
  const HiveBoxes._();

  static const String matches = 'matches';
  static const String tournaments = 'tournaments';
  static const String syncQueue = 'sync_queue';
  static const String settings = 'settings';
}

class AppConstants {
  const AppConstants._();

  static const int defaultOvers = 20;
  static const int ballsPerOver = 6;
}
