import '../../../domain/models/cricket_match.dart';

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
