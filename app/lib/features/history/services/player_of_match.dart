import '../../../domain/models/cricket_match.dart';

/// Aggregated contribution of one player across a match.
class PlayerImpact {
  PlayerImpact(this.name);

  final String name;
  String? team;
  int runs = 0;
  int wickets = 0;
  int fieldDismissals = 0; // catches + stumpings + run-outs effected
  bool onWinningTeam = false;

  /// Impact score. The ICC's Player-of-the-Match award is an adjudicator's
  /// subjective call (there is no official formula), so this is a transparent
  /// heuristic: batting + bowling + fielding, with a bonus for the winning side.
  int get score =>
      runs +
      wickets * 20 +
      fieldDismissals * 10 +
      (onWinningTeam ? 10 : 0);
}

/// Picks the Player of the Match for a completed match, or null if the match
/// is not finished. Ties break on score, then runs, then wickets.
PlayerImpact? playerOfTheMatch(CricketMatch match) {
  if (!match.isComplete) return null;

  final impacts = <String, PlayerImpact>{};
  PlayerImpact at(String name) => impacts.putIfAbsent(name, () => PlayerImpact(name));

  for (final inn in match.innings) {
    for (final name in inn.batsmenInOrder) {
      final p = at(name);
      p.runs += inn.batStat(name).runs;
      p.team ??= inn.battingTeam;
    }
    for (final name in inn.bowlersUsed) {
      final p = at(name);
      p.wickets += inn.bowlStat(name).wickets;
      // A bowler belongs to the side that is fielding in this innings.
      p.team ??= inn.bowlingTeam;
    }
    for (final ball in inn.balls) {
      final fielder = ball.fielderName;
      if (fielder != null) {
        final p = at(fielder);
        p.fieldDismissals += 1;
        p.team ??= inn.bowlingTeam;
      }
    }
  }

  if (impacts.isEmpty) return null;

  final winner = match.winnerTeam;
  for (final p in impacts.values) {
    p.onWinningTeam = winner != null && p.team == winner;
  }

  final ranked = impacts.values.toList()
    ..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byRuns = b.runs.compareTo(a.runs);
      if (byRuns != 0) return byRuns;
      return b.wickets.compareTo(a.wickets);
    });
  return ranked.first;
}
