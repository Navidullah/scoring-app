import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_providers.dart';
import '../services/leaderboard.dart';

/// Top run-scorers across all saved matches.
final topRunScorersProvider = Provider.autoDispose<List<LeaderboardEntry>>((ref) {
  return topRunScorers(ref.watch(matchRepositoryProvider).getAllMatches());
});

/// Top wicket-takers across all saved matches.
final topWicketTakersProvider = Provider.autoDispose<List<LeaderboardEntry>>((ref) {
  return topWicketTakers(ref.watch(matchRepositoryProvider).getAllMatches());
});
