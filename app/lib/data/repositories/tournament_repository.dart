import '../../domain/models/tournament.dart';
import '../local/local_tournament_data_source.dart';

/// Single entry point for tournament data (local-first).
class TournamentRepository {
  TournamentRepository({required this.local});

  final LocalTournamentDataSource local;

  void save(Tournament tournament) => local.save(tournament);
  Tournament? get(String id) => local.get(id);
  List<Tournament> getAll() => local.getAll();
  void delete(String id) => local.delete(id);
}
