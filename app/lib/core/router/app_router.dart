import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/match/match_setup_screen.dart';
import '../../features/match/live_scoring_screen.dart';
import '../../features/tournament/tournament_screen.dart';
import '../../features/tournament/tournament_create_screen.dart';
import '../../features/tournament/tournament_detail_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/history/scorecard_screen.dart';
import '../../features/stats/leaderboard_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Central route table. Keep paths as named constants to avoid typos.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String matchSetup = '/match/setup';
  static String matchScore(String id) => '/match/$id/score';
  static const String tournaments = '/tournaments';
  static const String history = '/history';
  static const String leaderboards = '/leaderboards';
  static const String settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.matchSetup,
      builder: (context, state) => const MatchSetupScreen(),
    ),
    GoRoute(
      path: '/match/:id/score',
      builder: (context, state) =>
          LiveScoringScreen(matchId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/match/:id/scorecard',
      builder: (context, state) =>
          ScorecardScreen(matchId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.tournaments,
      builder: (context, state) => const TournamentScreen(),
    ),
    GoRoute(
      path: '/tournaments/create',
      builder: (context, state) => const TournamentCreateScreen(),
    ),
    GoRoute(
      path: '/tournaments/:id',
      builder: (context, state) =>
          TournamentDetailScreen(tournamentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.leaderboards,
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
