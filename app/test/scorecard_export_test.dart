import 'package:flutter_test/flutter_test.dart';

import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/ball_event.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/features/history/scorecard_format.dart';
import 'package:scoring_app/features/history/services/scorecard_pdf.dart';

void main() {
  final caughtInnings = Innings(
    battingTeam: 'A',
    bowlingTeam: 'B',
    balls: [
      BallEvent(
        id: '1',
        runs: 0,
        wicket: WicketType.caught,
        outBatsmanName: 'Kohli',
        fielderName: 'Root',
        strikerName: 'Kohli',
        nonStrikerName: 'Rohit',
        bowlerName: 'Anderson',
      ),
    ],
    striker: 'Rohit',
    nonStriker: 'Pant',
  );

  test('caught dismissal includes the fielder', () {
    expect(dismissalText(caughtInnings, 'Kohli'), 'c Root b Anderson');
  });

  test('run out shows the fielder in parentheses', () {
    final inn = Innings(
      battingTeam: 'A',
      bowlingTeam: 'B',
      balls: [
        BallEvent(
          id: '1',
          runs: 0,
          wicket: WicketType.runOut,
          outBatsmanName: 'Rohit',
          fielderName: 'Stokes',
          strikerName: 'Rohit',
          nonStrikerName: 'Kohli',
          bowlerName: 'Anderson',
        ),
      ],
    );
    expect(dismissalText(inn, 'Rohit'), 'run out (Stokes)');
  });

  test('scorecard PDF is generated as non-empty bytes', () async {
    final match = CricketMatch(
      id: 'm',
      team1: 'A',
      team2: 'B',
      overs: 20,
      battingFirst: 'A',
      createdAt: DateTime(2026),
      status: MatchStatus.completed,
      resultText: 'A won by 10 runs',
      innings: [caughtInnings],
    );
    final bytes = await buildScorecardPdf(match);
    expect(bytes.length, greaterThan(500)); // a real PDF, not empty
  });
}
