import 'package:flutter_test/flutter_test.dart';

import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/ball_event.dart';
import 'package:scoring_app/domain/models/innings.dart';

BallEvent ball({
  required String striker,
  required String nonStriker,
  required String bowler,
  int runs = 0,
  ExtraType? extraType,
  int extraRuns = 0,
  WicketType? wicket,
  String? outBatsman,
}) =>
    BallEvent(
      id: '${striker}_$runs${extraType?.name ?? ''}${wicket?.name ?? ''}',
      runs: runs,
      extraType: extraType,
      extraRuns: extraRuns,
      wicket: wicket,
      strikerName: striker,
      nonStrikerName: nonStriker,
      bowlerName: bowler,
      outBatsmanName: outBatsman,
    );

void main() {
  // A: 4 then bowled by X. C comes in, takes a single. One wide bowled by X.
  final innings = Innings(
    battingTeam: 'A-team',
    bowlingTeam: 'B-team',
    striker: 'C',
    nonStriker: 'B',
    bowler: 'X',
    balls: [
      ball(striker: 'A', nonStriker: 'B', bowler: 'X', runs: 4),
      ball(striker: 'A', nonStriker: 'B', bowler: 'X', wicket: WicketType.bowled, outBatsman: 'A'),
      ball(striker: 'C', nonStriker: 'B', bowler: 'X', extraType: ExtraType.wide, extraRuns: 1),
      ball(striker: 'C', nonStriker: 'B', bowler: 'X', runs: 1),
    ],
  );

  test('batsmen are listed in the order they came to the crease', () {
    expect(innings.batsmenInOrder, ['A', 'B', 'C']);
  });

  test('bowlers used are distinct and ordered', () {
    expect(innings.bowlersUsed, ['X']);
  });

  test('totals and extras are correct', () {
    expect(innings.runs, 6); // 4 + wide 1 + 1
    expect(innings.extras, 1);
    expect(innings.wickets, 1);
    expect(innings.legalBalls, 3); // wide excluded
  });

  test('batting stats credit the striker correctly', () {
    final a = innings.batStat('A');
    expect(a.runs, 4);
    expect(a.balls, 2); // boundary + the legal ball he was bowled on
    expect(a.fours, 1);

    final c = innings.batStat('C');
    expect(c.runs, 1);
    expect(c.balls, 1); // the wide is not a ball faced
  });

  test('dismissal lookup resolves the wicket delivery', () {
    final outBall = innings.dismissalOf('A');
    expect(outBall, isNotNull);
    expect(outBall!.wicket, WicketType.bowled);
    expect(innings.dismissalOf('B'), isNull); // not out
  });

  test('maidens require a completed over with zero runs', () {
    expect(innings.maidensFor('X'), 0); // over not completed
  });
}
