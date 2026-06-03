import '../../../core/constants/app_constants.dart';
import '../../../domain/models/cricket_match.dart';
import '../../../domain/models/tournament.dart';

/// One row of the points table.
class Standing {
  Standing(this.team);

  final String team;
  int played = 0;
  int won = 0;
  int lost = 0;
  int tied = 0;
  int runsFor = 0;
  double oversFor = 0;
  int runsAgainst = 0;
  double oversAgainst = 0;

  int get points => won * 2 + tied;

  /// Net run rate: (runs scored / overs faced) − (runs conceded / overs bowled).
  double get nrr {
    final scoredRate = oversFor == 0 ? 0.0 : runsFor / oversFor;
    final concededRate = oversAgainst == 0 ? 0.0 : runsAgainst / oversAgainst;
    return scoredRate - concededRate;
  }
}

double _overs(int legalBalls) => legalBalls / AppConstants.ballsPerOver;

/// Computes the standings for a tournament. [resolveMatch] returns the played
/// match for a fixture's matchId (or null if not played / not found).
List<Standing> computeStandings(
  Tournament tournament,
  CricketMatch? Function(String matchId) resolveMatch,
) {
  final table = <String, Standing>{
    for (final t in tournament.teams) t.name: Standing(t.name),
  };

  for (final fixture in tournament.fixtures) {
    if (fixture.isBye || fixture.matchId == null) continue;
    final match = resolveMatch(fixture.matchId!);
    if (match == null || !match.isComplete || match.innings.length < 2) continue;

    final a = table[fixture.teamA];
    final b = table[fixture.teamB];
    if (a == null || b == null) continue;

    // Pull each team's batting/bowling figures from the match innings.
    for (final team in [a, b]) {
      final batInn = match.innings.firstWhere(
        (i) => i.battingTeam == team.team,
        orElse: () => match.innings.first,
      );
      final bowlInn = match.innings.firstWhere(
        (i) => i.battingTeam != team.team,
        orElse: () => match.innings.last,
      );
      team.played += 1;
      team.runsFor += batInn.runs;
      team.oversFor += _overs(batInn.legalBalls);
      team.runsAgainst += bowlInn.runs;
      team.oversAgainst += _overs(bowlInn.legalBalls);
    }

    final winner = match.winnerTeam;
    if (winner == null) {
      a.tied += 1;
      b.tied += 1;
    } else if (winner == a.team) {
      a.won += 1;
      b.lost += 1;
    } else {
      b.won += 1;
      a.lost += 1;
    }
  }

  final standings = table.values.toList();
  standings.sort((x, y) {
    final byPoints = y.points.compareTo(x.points);
    if (byPoints != 0) return byPoints;
    return y.nrr.compareTo(x.nrr);
  });
  return standings;
}
