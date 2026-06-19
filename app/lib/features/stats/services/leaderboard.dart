import '../../../domain/enums/cricket_enums.dart';
import '../../../domain/models/cricket_match.dart';
import 'player_stats.dart';

/// The ranking categories offered on the leaderboard screen.
enum LeaderCategory {
  runs,
  wickets,
  highScore,
  bestBowling,
  sixes,
  fours,
  battingAverage,
  strikeRate,
  economy,
}

extension LeaderCategoryInfo on LeaderCategory {
  String get label => switch (this) {
        LeaderCategory.runs => 'Most Runs',
        LeaderCategory.wickets => 'Most Wickets',
        LeaderCategory.highScore => 'Highest Score',
        LeaderCategory.bestBowling => 'Best Bowling',
        LeaderCategory.sixes => 'Most Sixes',
        LeaderCategory.fours => 'Most Fours',
        LeaderCategory.battingAverage => 'Best Average',
        LeaderCategory.strikeRate => 'Best Strike Rate',
        LeaderCategory.economy => 'Best Economy',
      };

  /// Short unit shown after the value (empty when the value is self-describing).
  String get unit => switch (this) {
        LeaderCategory.runs => 'runs',
        LeaderCategory.wickets => 'wkts',
        LeaderCategory.highScore => '',
        LeaderCategory.bestBowling => '',
        LeaderCategory.sixes => '6s',
        LeaderCategory.fours => '4s',
        LeaderCategory.battingAverage => 'avg',
        LeaderCategory.strikeRate => 'sr',
        LeaderCategory.economy => 'econ',
      };
}

/// A ranked leaderboard row for any category. [display] is the pre-formatted
/// headline value (e.g. "342", "4/12", "45.5").
class StatLeader {
  StatLeader({
    required this.name,
    required this.display,
    required this.sortKey,
    required this.subtitle,
  });
  final String name;
  final String display;
  final num sortKey;
  final String subtitle;
}

/// Minimum deliveries before a player qualifies for rate-based categories
/// (so a one-ball cameo can't top the strike-rate / average / economy charts).
const int _minBatBalls = 20;
const int _minBowlBalls = 12;

/// Builds a ranked leaderboard for [category] across [matches]. Optionally
/// restricts to a [ballType] (e.g. tennis-only). Higher [sortKey] ranks first,
/// except economy where lower is better.
List<StatLeader> leaderboardFor(
  LeaderCategory category,
  List<CricketMatch> matches, {
  BallType? ballType,
  int limit = 50,
}) {
  final pool = ballType == null
      ? matches
      : matches.where((m) => m.ballType == ballType).toList();
  final names = allPlayerNames(pool);
  final careers = [for (final n in names) playerCareer(n, pool)];

  final rows = <StatLeader>[];
  for (final c in careers) {
    final b = c.batting;
    final w = c.bowling;
    switch (category) {
      case LeaderCategory.runs:
        if (b.runs > 0) {
          rows.add(StatLeader(name: c.name, display: '${b.runs}', sortKey: b.runs, subtitle: '${b.innings} inns'));
        }
      case LeaderCategory.wickets:
        if (w.wickets > 0) {
          rows.add(StatLeader(name: c.name, display: '${w.wickets}', sortKey: w.wickets, subtitle: '${w.innings} inns'));
        }
      case LeaderCategory.highScore:
        if (b.innings > 0) {
          rows.add(StatLeader(name: c.name, display: b.highScoreText, sortKey: b.highScore, subtitle: '${c.matches} mat'));
        }
      case LeaderCategory.bestBowling:
        if (w.bestWickets > 0) {
          rows.add(StatLeader(
            name: c.name,
            display: w.bestText,
            // Rank by wickets, then fewer runs (encoded so more wkts always wins).
            sortKey: w.bestWickets * 1000 - w.bestRuns,
            subtitle: '${w.wickets} career',
          ));
        }
      case LeaderCategory.sixes:
        if (b.sixes > 0) {
          rows.add(StatLeader(name: c.name, display: '${b.sixes}', sortKey: b.sixes, subtitle: '${b.runs} runs'));
        }
      case LeaderCategory.fours:
        if (b.fours > 0) {
          rows.add(StatLeader(name: c.name, display: '${b.fours}', sortKey: b.fours, subtitle: '${b.runs} runs'));
        }
      case LeaderCategory.battingAverage:
        if (b.balls >= _minBatBalls && b.dismissals > 0) {
          rows.add(StatLeader(name: c.name, display: b.average.toStringAsFixed(1), sortKey: b.average, subtitle: '${b.runs} runs'));
        }
      case LeaderCategory.strikeRate:
        if (b.balls >= _minBatBalls) {
          rows.add(StatLeader(name: c.name, display: b.strikeRate.toStringAsFixed(1), sortKey: b.strikeRate, subtitle: '${b.runs} runs'));
        }
      case LeaderCategory.economy:
        if (w.balls >= _minBowlBalls) {
          rows.add(StatLeader(name: c.name, display: w.economy.toStringAsFixed(1), sortKey: w.economy, subtitle: '${w.oversText} ov'));
        }
    }
  }

  // Economy ranks ascending (lower is better); every other category descending.
  if (category == LeaderCategory.economy) {
    rows.sort((a, b) => a.sortKey.compareTo(b.sortKey));
  } else {
    rows.sort((a, b) => b.sortKey.compareTo(a.sortKey));
  }
  return rows.take(limit).toList();
}

/// A single leaderboard row.
class LeaderboardEntry {
  LeaderboardEntry(this.name);
  final String name;
  int value = 0; // runs or wickets
  int matches = 0;
}

List<LeaderboardEntry> _ranked(Map<String, LeaderboardEntry> map, int limit) {
  final list = map.values.toList()..sort((a, b) => b.value.compareTo(a.value));
  return list.take(limit).toList();
}

/// Most runs scored, aggregated across every match.
List<LeaderboardEntry> topRunScorers(List<CricketMatch> matches, {int limit = 50}) {
  final map = <String, LeaderboardEntry>{};
  for (final match in matches) {
    final seen = <String>{};
    for (final inn in match.innings) {
      for (final name in inn.batsmenInOrder) {
        final e = map.putIfAbsent(name, () => LeaderboardEntry(name));
        e.value += inn.batStat(name).runs;
        if (seen.add(name)) e.matches += 1;
      }
    }
  }
  return _ranked(map, limit);
}

/// Most wickets taken, aggregated across every match.
List<LeaderboardEntry> topWicketTakers(List<CricketMatch> matches, {int limit = 50}) {
  final map = <String, LeaderboardEntry>{};
  for (final match in matches) {
    final seen = <String>{};
    for (final inn in match.innings) {
      for (final name in inn.bowlersUsed) {
        final e = map.putIfAbsent(name, () => LeaderboardEntry(name));
        e.value += inn.bowlStat(name).wickets;
        if (seen.add(name)) e.matches += 1;
      }
    }
  }
  return _ranked(map, limit);
}
