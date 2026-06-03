import '../../domain/models/cricket_match.dart';
import '../local/local_match_data_source.dart';
import '../remote/match_api.dart';

/// Single entry point for match data. UI/providers talk to this, never to the
/// data sources directly. Local-first: writes hit Hive synchronously; remote
/// sync is best-effort and never blocks scoring.
class MatchRepository {
  MatchRepository({required this.local, required this.remote});

  final LocalMatchDataSource local;
  final MatchApi remote;

  void saveMatch(CricketMatch match) => local.save(match);

  CricketMatch? getMatch(String id) => local.get(id);

  List<CricketMatch> getAllMatches() => local.getAll();

  void deleteMatch(String id) => local.delete(id);
}
