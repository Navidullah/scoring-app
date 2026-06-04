import 'package:flutter_test/flutter_test.dart';

import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/ball_event.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/core/utils/string_utils.dart';

BallEvent _ball(
  String s,
  String ns,
  String bw, {
  int runs = 0,
  ExtraType? extra,
  int extraRuns = 0,
  WicketType? wicket,
}) =>
    BallEvent(
      id: 'b',
      runs: runs,
      extraType: extra,
      extraRuns: extraRuns,
      wicket: wicket,
      strikerName: s,
      nonStrikerName: ns,
      bowlerName: bw,
    );

void main() {
  group('free hit', () {
    test('a no-ball makes the next delivery a free hit', () {
      final inn = Innings(
        battingTeam: 'A',
        bowlingTeam: 'B',
        balls: [_ball('X', 'Y', 'Z', extra: ExtraType.noBall, extraRuns: 1)],
      );
      expect(inn.isFreeHit, isTrue);
    });

    test('a wide does not consume the free hit', () {
      final inn = Innings(
        battingTeam: 'A',
        bowlingTeam: 'B',
        balls: [
          _ball('X', 'Y', 'Z', extra: ExtraType.noBall, extraRuns: 1),
          _ball('X', 'Y', 'Z', extra: ExtraType.wide, extraRuns: 1),
        ],
      );
      expect(inn.isFreeHit, isTrue);
    });

    test('a legal delivery ends the free hit', () {
      final inn = Innings(
        battingTeam: 'A',
        bowlingTeam: 'B',
        balls: [
          _ball('X', 'Y', 'Z', extra: ExtraType.noBall, extraRuns: 1),
          _ball('X', 'Y', 'Z', runs: 1),
        ],
      );
      expect(inn.isFreeHit, isFalse);
    });
  });

  test('over breakdown groups runs and wickets per over', () {
    final inn = Innings(
      battingTeam: 'A',
      bowlingTeam: 'B',
      balls: [
        for (var i = 0; i < 6; i++) _ball('X', 'Y', 'Z', runs: 1),
        _ball('X', 'Y', 'Z', runs: 4),
        _ball('X', 'Y', 'Z', runs: 0, wicket: WicketType.bowled),
      ],
    );
    final ob = inn.overBreakdown;
    expect(ob.length, 2); // one full over + an in-progress over
    expect(ob[0].runs, 6);
    expect(ob[0].wickets, 0);
    expect(ob[1].runs, 4);
    expect(ob[1].wickets, 1);
  });

  group('titleCase', () {
    test('capitalizes the first letter of each word', () {
      expect(titleCase('naveed ullah'), 'Naveed Ullah');
      expect(titleCase('team a'), 'Team A');
    });
    test('trims and collapses whitespace', () {
      expect(titleCase('  taimur   mirza  '), 'Taimur Mirza');
    });
    test('leaves existing capitals intact', () {
      expect(titleCase('MS dhoni'), 'MS Dhoni');
    });
  });

  group('ball type + lbw serialization', () {
    test('round-trips tennis ball and lbw disabled', () {
      final match = CricketMatch(
        id: 'm',
        team1: 'A',
        team2: 'B',
        overs: 10,
        battingFirst: 'A',
        createdAt: DateTime(2026, 6, 4),
        ballType: BallType.tennis,
        lbwAllowed: false,
        innings: const [Innings(battingTeam: 'A', bowlingTeam: 'B')],
      );
      final back = CricketMatch.fromJson(match.toJson());
      expect(back.ballType, BallType.tennis);
      expect(back.lbwAllowed, isFalse);
    });

    test('older matches without the fields default to leather / lbw allowed', () {
      final legacy = {
        'id': 'm',
        'team1': 'A',
        'team2': 'B',
        'overs': 20,
        'battingFirst': 'A',
        'innings': <dynamic>[
          {'battingTeam': 'A', 'bowlingTeam': 'B', 'balls': <dynamic>[]}
        ],
        'status': 'inProgress',
        'createdAt': DateTime(2026).toIso8601String(),
      };
      final m = CricketMatch.fromJson(legacy);
      expect(m.ballType, BallType.leather);
      expect(m.lbwAllowed, isTrue);
    });
  });
}
