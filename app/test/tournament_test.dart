import 'package:flutter_test/flutter_test.dart';

import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/ball_event.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/domain/models/tournament.dart';
import 'package:scoring_app/features/tournament/services/fixture_generator.dart';
import 'package:scoring_app/features/tournament/services/points_table.dart';

List<BallEvent> _over(String striker, String bowler, int runsPerBall) => List.generate(
      6,
      (i) => BallEvent(
        id: '$striker$bowler$i',
        runs: runsPerBall,
        strikerName: striker,
        nonStrikerName: 'x',
        bowlerName: bowler,
      ),
    );

void main() {
  group('fixtures', () {
    test('round-robin of 4 teams produces 6 fixtures', () {
      final f = generateInitialFixtures(TournamentFormat.roundRobin, ['A', 'B', 'C', 'D']);
      expect(f.length, 6);
      expect(f.every((x) => x.round == 1), isTrue);
    });

    test('knockout of 4 teams produces 2 first-round fixtures', () {
      final f = generateInitialFixtures(TournamentFormat.knockout, ['A', 'B', 'C', 'D']);
      expect(f.length, 2);
    });

    test('knockout with an odd team gives a bye', () {
      final f = generateInitialFixtures(TournamentFormat.knockout, ['A', 'B', 'C']);
      expect(f.length, 2);
      expect(f.where((x) => x.isBye).length, 1);
    });

    test('next knockout round pairs the winners', () {
      final next = generateNextKnockoutRound(1, ['A', 'B']);
      expect(next.length, 1);
      expect(next.first.round, 2);
    });

    test('a single winner means no further round (champion)', () {
      expect(generateNextKnockoutRound(2, ['A']), isEmpty);
    });
  });

  group('points table', () {
    test('win awards 2 points and a positive NRR; loser gets 0', () {
      final match = CricketMatch(
        id: 'm',
        team1: 'A',
        team2: 'B',
        overs: 1,
        battingFirst: 'A',
        createdAt: DateTime(2026),
        status: MatchStatus.completed,
        innings: [
          Innings(battingTeam: 'A', bowlingTeam: 'B', balls: _over('p', 'q', 4)), // 24 runs
          Innings(battingTeam: 'B', bowlingTeam: 'A', balls: _over('r', 's', 1)), // 6 runs
        ],
      );

      final tournament = Tournament(
        id: 't',
        name: 'Cup',
        format: TournamentFormat.roundRobin,
        overs: 1,
        teams: const [TournamentTeam(name: 'A'), TournamentTeam(name: 'B')],
        fixtures: [const Fixture(id: 'f', round: 1, teamA: 'A', teamB: 'B', matchId: 'm')],
        createdAt: DateTime(2026),
      );

      final standings = computeStandings(tournament, (id) => id == 'm' ? match : null);

      expect(standings.first.team, 'A'); // sorted top by points
      final a = standings.firstWhere((s) => s.team == 'A');
      final b = standings.firstWhere((s) => s.team == 'B');
      expect(a.points, 2);
      expect(a.won, 1);
      expect(b.points, 0);
      expect(b.lost, 1);
      expect(a.nrr, greaterThan(0));
      expect(b.nrr, lessThan(0));
    });

    test('unplayed fixtures are ignored', () {
      final tournament = Tournament(
        id: 't',
        name: 'Cup',
        format: TournamentFormat.roundRobin,
        overs: 1,
        teams: const [TournamentTeam(name: 'A'), TournamentTeam(name: 'B')],
        fixtures: [const Fixture(id: 'f', round: 1, teamA: 'A', teamB: 'B')],
        createdAt: DateTime(2026),
      );
      final standings = computeStandings(tournament, (_) => null);
      expect(standings.every((s) => s.played == 0), isTrue);
    });
  });
}
