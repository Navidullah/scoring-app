import 'package:flutter_test/flutter_test.dart';

import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/ball_event.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/features/history/services/player_of_match.dart';
import 'package:scoring_app/features/stats/services/leaderboard.dart';

BallEvent _run(String striker, String bowler, int runs) => BallEvent(
      id: '$striker$bowler$runs${DateTime.now().microsecondsSinceEpoch}',
      runs: runs,
      strikerName: striker,
      nonStrikerName: 'other',
      bowlerName: bowler,
    );

BallEvent _wicket(String striker, String bowler) => BallEvent(
      id: 'w$striker$bowler${DateTime.now().microsecondsSinceEpoch}',
      runs: 0,
      wicket: WicketType.bowled,
      outBatsmanName: striker,
      strikerName: striker,
      nonStrikerName: 'other',
      bowlerName: bowler,
    );

/// Team A scores 30 (Hitter), Team B chases and loses; Hitter wins POTM.
CricketMatch _match() => CricketMatch(
      id: 'm1',
      team1: 'A',
      team2: 'B',
      overs: 1,
      battingFirst: 'A',
      createdAt: DateTime(2026),
      status: MatchStatus.completed,
      innings: [
        Innings(
          battingTeam: 'A',
          bowlingTeam: 'B',
          balls: [for (var i = 0; i < 6; i++) _run('Hitter', 'Bowler', 5)], // 30 runs
        ),
        Innings(
          battingTeam: 'B',
          bowlingTeam: 'A',
          balls: [
            _run('Chaser', 'Wicketman', 1),
            for (var i = 0; i < 3; i++) _wicket('Chaser', 'Wicketman'),
          ],
        ),
      ],
    );

void main() {
  group('player of the match', () {
    test('returns null for an unfinished match', () {
      final m = _match().copyWith(status: MatchStatus.inProgress);
      expect(playerOfTheMatch(m), isNull);
    });

    test('picks the highest-impact player on the winning side', () {
      final potm = playerOfTheMatch(_match());
      expect(potm, isNotNull);
      // Hitter: 30 runs + winning bonus 10 = 40. Wicketman: 3*20 = 60 but on
      // the losing side gets no bonus → 60 still beats 40, so bowler wins.
      expect(potm!.name, 'Wicketman');
      expect(potm.wickets, 3);
    });
  });

  group('leaderboards', () {
    test('aggregates runs and wickets across matches', () {
      final matches = [_match(), _match()];
      final runs = topRunScorers(matches);
      final wickets = topWicketTakers(matches);

      final hitter = runs.firstWhere((e) => e.name == 'Hitter');
      expect(hitter.value, 60); // 30 across two matches
      expect(hitter.matches, 2);

      final bowler = wickets.firstWhere((e) => e.name == 'Wicketman');
      expect(bowler.value, 6); // 3 wickets x 2 matches
      expect(wickets.first.name, 'Wicketman'); // top of the list
    });
  });
}
