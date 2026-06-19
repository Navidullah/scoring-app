import '../../../core/constants/app_constants.dart';
import '../../../domain/models/cricket_match.dart';

/// Aggregated batting career for one player across many matches.
class BattingCareer {
  int innings = 0;
  int notOuts = 0;
  int runs = 0;
  int balls = 0;
  int fours = 0;
  int sixes = 0;
  int fifties = 0;
  int hundreds = 0;
  int ducks = 0;
  int highScore = 0;
  bool highScoreNotOut = false;

  int get dismissals => innings - notOuts;
  double get average => dismissals == 0 ? runs.toDouble() : runs / dismissals;
  double get strikeRate => balls == 0 ? 0 : runs * 100 / balls;
  String get highScoreText =>
      innings == 0 ? '-' : '$highScore${highScoreNotOut ? '*' : ''}';
}

/// Aggregated bowling career for one player across many matches.
class BowlingCareer {
  int innings = 0;
  int balls = 0;
  int runs = 0;
  int wickets = 0;
  int maidens = 0;
  int threeWicketHauls = 0;
  int fiveWicketHauls = 0;
  int bestWickets = -1;
  int bestRuns = 0;

  double get average => wickets == 0 ? 0 : runs / wickets;
  double get economy =>
      balls == 0 ? 0 : runs * AppConstants.ballsPerOver / balls;
  double get strikeRate => wickets == 0 ? 0 : balls / wickets;
  String get oversText =>
      '${balls ~/ AppConstants.ballsPerOver}.${balls % AppConstants.ballsPerOver}';
  String get bestText => bestWickets < 0 ? '-' : '$bestWickets/$bestRuns';
}

/// One match line for the recent-form strip.
class MatchPerformance {
  MatchPerformance({
    required this.matchId,
    required this.title,
    required this.date,
    required this.runs,
    required this.batNotOut,
    required this.batted,
    required this.wickets,
    required this.bowled,
  });

  final String matchId;
  final String title; // e.g. "Lions vs Tigers"
  final DateTime date;
  final int runs;
  final bool batNotOut;
  final bool batted;
  final int wickets;
  final bool bowled;

  String get battingText => batted ? '$runs${batNotOut ? '*' : ''}' : '-';
  String get bowlingText => bowled ? '$wickets wkt${wickets == 1 ? '' : 's'}' : '-';
}

/// A player's full career across the supplied matches.
class PlayerCareer {
  PlayerCareer(this.name);
  final String name;
  int matches = 0;
  final BattingCareer batting = BattingCareer();
  final BowlingCareer bowling = BowlingCareer();
  final List<MatchPerformance> recent = [];
}

/// Builds a [PlayerCareer] for [name] from [matches] (case-insensitive match on
/// the stored, title-cased name). Only innings the player actually appeared in
/// count toward batting/bowling tallies.
PlayerCareer playerCareer(String name, List<CricketMatch> matches) {
  final career = PlayerCareer(name);
  final key = name.toLowerCase();

  // Newest first so the recent-form strip reads left-to-right as latest games.
  final sorted = [...matches]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  for (final match in sorted) {
    var batted = false, bowled = false;
    var matchRuns = 0, matchWkts = 0;
    var matchNotOut = false;

    for (final inn in match.innings) {
      // Batting.
      final batsmen = inn.batsmenInOrder;
      final didBat = batsmen.any((n) => n.toLowerCase() == key);
      if (didBat) {
        batted = true;
        final stat = inn.batStat(_canonical(batsmen, key));
        final out = inn.dismissalOf(_canonical(batsmen, key)) != null;
        career.batting.innings += 1;
        career.batting.runs += stat.runs;
        career.batting.balls += stat.balls;
        career.batting.fours += stat.fours;
        career.batting.sixes += stat.sixes;
        if (!out) career.batting.notOuts += 1;
        if (out && stat.runs == 0) career.batting.ducks += 1;
        if (stat.runs >= 100) {
          career.batting.hundreds += 1;
        } else if (stat.runs >= 50) {
          career.batting.fifties += 1;
        }
        if (stat.runs > career.batting.highScore) {
          career.batting.highScore = stat.runs;
          career.batting.highScoreNotOut = !out;
        }
        matchRuns += stat.runs;
        matchNotOut = !out;
      }

      // Bowling.
      final bowlers = inn.bowlersUsed;
      final didBowl = bowlers.any((n) => n.toLowerCase() == key);
      if (didBowl) {
        bowled = true;
        final canon = _canonical(bowlers, key);
        final stat = inn.bowlStat(canon);
        career.bowling.innings += 1;
        career.bowling.balls += stat.legalBalls;
        career.bowling.runs += stat.runsConceded;
        career.bowling.wickets += stat.wickets;
        career.bowling.maidens += inn.maidensFor(canon);
        if (stat.wickets >= 5) {
          career.bowling.fiveWicketHauls += 1;
        } else if (stat.wickets >= 3) {
          career.bowling.threeWicketHauls += 1;
        }
        // Best bowling: more wickets wins; tie broken by fewer runs.
        if (stat.wickets > career.bowling.bestWickets ||
            (stat.wickets == career.bowling.bestWickets &&
                stat.runsConceded < career.bowling.bestRuns)) {
          career.bowling.bestWickets = stat.wickets;
          career.bowling.bestRuns = stat.runsConceded;
        }
        matchWkts += stat.wickets;
      }
    }

    if (batted || bowled) {
      career.matches += 1;
      career.recent.add(MatchPerformance(
        matchId: match.id,
        title: '${match.team1} vs ${match.team2}',
        date: match.createdAt,
        runs: matchRuns,
        batNotOut: matchNotOut,
        batted: batted,
        wickets: matchWkts,
        bowled: bowled,
      ));
    }
  }

  return career;
}

/// The exact stored spelling of [key] from a list of names (preserves casing).
String _canonical(List<String> names, String key) =>
    names.firstWhere((n) => n.toLowerCase() == key, orElse: () => key);

/// Distinct player names across all matches (batters and bowlers), sorted.
List<String> allPlayerNames(List<CricketMatch> matches) {
  final set = <String, String>{};
  for (final match in matches) {
    for (final inn in match.innings) {
      for (final n in [...inn.batsmenInOrder, ...inn.bowlersUsed]) {
        set[n.toLowerCase()] = n;
      }
    }
  }
  final list = set.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}
