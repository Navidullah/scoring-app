import 'package:uuid/uuid.dart';

import '../../../domain/enums/cricket_enums.dart';
import '../../../domain/models/tournament.dart';

const _uuid = Uuid();

/// Builds the initial fixture list for a tournament based on its format.
List<Fixture> generateInitialFixtures(TournamentFormat format, List<String> teamNames) {
  switch (format) {
    case TournamentFormat.roundRobin:
      return _roundRobin(teamNames);
    case TournamentFormat.knockout:
      return _knockoutRound(teamNames, round: 1);
  }
}

/// Round-robin: every team plays every other team once.
List<Fixture> _roundRobin(List<String> teams) {
  final fixtures = <Fixture>[];
  for (var i = 0; i < teams.length; i++) {
    for (var j = i + 1; j < teams.length; j++) {
      fixtures.add(Fixture(id: _uuid.v4(), round: 1, teamA: teams[i], teamB: teams[j]));
    }
  }
  return fixtures;
}

/// Knockout round: pair teams sequentially. An odd team out gets a bye.
List<Fixture> _knockoutRound(List<String> teams, {required int round}) {
  final fixtures = <Fixture>[];
  for (var i = 0; i + 1 < teams.length; i += 2) {
    fixtures.add(Fixture(id: _uuid.v4(), round: round, teamA: teams[i], teamB: teams[i + 1]));
  }
  if (teams.length.isOdd) {
    fixtures.add(Fixture(id: _uuid.v4(), round: round, teamA: teams.last, teamB: Fixture.byeMarker));
  }
  return fixtures;
}

/// Builds the next knockout round from the winners of the current round.
/// [winners] must be in fixture order. Returns an empty list if a champion
/// has already been decided (one winner) or winners are incomplete.
List<Fixture> generateNextKnockoutRound(int currentRound, List<String> winners) {
  if (winners.length < 2) return [];
  return _knockoutRound(winners, round: currentRound + 1);
}
