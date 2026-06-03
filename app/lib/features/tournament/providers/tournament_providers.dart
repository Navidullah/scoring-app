import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/tournament.dart';
import '../../../shared/providers/repository_providers.dart';

/// All saved tournaments, newest first. Recomputed each time it's watched.
final tournamentListProvider = Provider.autoDispose<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).getAll();
});

/// A single tournament by id (null if missing).
final tournamentProvider =
    Provider.autoDispose.family<Tournament?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).get(id);
});
