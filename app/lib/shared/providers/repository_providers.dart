import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_match_data_source.dart';
import '../../data/local/local_tournament_data_source.dart';
import '../../data/remote/match_api.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/tournament_repository.dart';
import 'app_providers.dart';

/// Repository wiring. Local Hive source + best-effort remote API.
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(
    local: LocalMatchDataSource(),
    remote: MatchApi(ref.read(apiClientProvider)),
  );
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository(local: LocalTournamentDataSource());
});
