import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/cricket_match.dart';
import '../../../shared/providers/repository_providers.dart';

/// All saved matches, newest first. Recomputed each time the list is shown
/// (autoDispose), and can be refreshed with ref.invalidate after a delete.
final matchHistoryProvider = Provider.autoDispose<List<CricketMatch>>((ref) {
  return ref.watch(matchRepositoryProvider).getAllMatches();
});
