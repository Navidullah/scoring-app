import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums/cricket_enums.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/repository_providers.dart';
import '../services/leaderboard.dart';
import '../services/player_stats.dart';

/// A leaderboard request: which category, optionally filtered to a ball type.
typedef LeaderQuery = ({LeaderCategory category, BallType? ballType});

/// Ranked leaderboard for the chosen category/filter across all saved matches.
final leaderboardProvider =
    Provider.autoDispose.family<List<StatLeader>, LeaderQuery>((ref, q) {
  return leaderboardFor(
    q.category,
    ref.watch(matchRepositoryProvider).getAllMatches(),
    ballType: q.ballType,
  );
});

/// Full career stats for one player (by name) across all saved matches.
final playerCareerProvider = Provider.autoDispose.family<PlayerCareer, String>((ref, name) {
  return playerCareer(name, ref.watch(matchRepositoryProvider).getAllMatches());
});

/// Global leaderboards (runs + wickets) fetched from the backend across every
/// user's synced matches.
final globalLeaderboardProvider =
    FutureProvider.autoDispose<({List<StatLeader> runs, List<StatLeader> wickets})>((ref) async {
  final data = await ref.read(liveApiProvider).leaderboard();
  StatLeader toLeader(Map<String, dynamic> e) => StatLeader(
        name: e['name'] as String? ?? '?',
        display: '${e['value'] ?? 0}',
        sortKey: (e['value'] as num?) ?? 0,
        subtitle: '${e['matches'] ?? 0} mat',
      );
  return (
    runs: data.runs.map(toLeader).toList(),
    wickets: data.wickets.map(toLeader).toList(),
  );
});
