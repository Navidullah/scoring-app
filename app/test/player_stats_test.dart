import 'package:flutter_test/flutter_test.dart';

import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/ball_event.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/features/stats/services/player_stats.dart';

int _seq = 0;
BallEvent _run(String striker, String bowler, int runs) => BallEvent(
      id: 'b${_seq++}',
      runs: runs,
      strikerName: striker,
      nonStrikerName: 'other',
      bowlerName: bowler,
    );

BallEvent _wicket(String striker, String bowler) => BallEvent(
      id: 'b${_seq++}',
      runs: 0,
      wicket: WicketType.bowled,
      outBatsmanName: striker,
      strikerName: striker,
      nonStrikerName: 'other',
      bowlerName: bowler,
    );

/// Hitter makes 30 not out and Wicketman takes 3/1 in each match.
CricketMatch _match(String id) => CricketMatch(
      id: id,
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
          balls: [for (var i = 0; i < 6; i++) _run('Hitter', 'Bowler', 5)],
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
  group('player career', () {
    test('aggregates batting across matches, treating undismissed as not out', () {
      final c = playerCareer('Hitter', [_match('m1'), _match('m2')]);

      expect(c.matches, 2);
      expect(c.batting.innings, 2);
      expect(c.batting.runs, 60);
      expect(c.batting.highScore, 30);
      expect(c.batting.highScoreNotOut, isTrue);
      expect(c.batting.notOuts, 2);
      expect(c.batting.dismissals, 0);
      // No dismissals → average falls back to total runs.
      expect(c.batting.average, 60);
    });

    test('aggregates bowling and records best figures', () {
      final c = playerCareer('Wicketman', [_match('m1'), _match('m2')]);

      expect(c.bowling.innings, 2);
      expect(c.bowling.wickets, 6);
      expect(c.bowling.runs, 2); // 1 conceded per match
      expect(c.bowling.bestWickets, 3);
      expect(c.bowling.bestRuns, 1);
      expect(c.bowling.bestText, '3/1');
    });

    test('case-insensitive name match and ignores non-participants', () {
      final c = playerCareer('hITTER', [_match('m1')]);
      expect(c.batting.runs, 30);

      final none = playerCareer('Nobody', [_match('m1')]);
      expect(none.matches, 0);
    });

    test('counts a duck as out for zero', () {
      final m = CricketMatch(
        id: 'd1',
        team1: 'A',
        team2: 'B',
        overs: 1,
        battingFirst: 'A',
        createdAt: DateTime(2026),
        innings: [
          Innings(
            battingTeam: 'A',
            bowlingTeam: 'B',
            balls: [_wicket('Duck', 'Bowler')],
          ),
        ],
      );
      final c = playerCareer('Duck', [m]);
      expect(c.batting.ducks, 1);
      expect(c.batting.notOuts, 0);
    });
  });
}
