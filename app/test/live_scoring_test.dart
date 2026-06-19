import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:scoring_app/core/constants/app_constants.dart';
import 'package:scoring_app/data/local/local_match_data_source.dart';
import 'package:scoring_app/data/remote/api_client.dart';
import 'package:scoring_app/data/remote/match_api.dart';
import 'package:scoring_app/data/remote/sync_api.dart';
import 'package:scoring_app/data/repositories/match_repository.dart';
import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/features/match/providers/live_scoring_controller.dart';
import 'package:scoring_app/shared/providers/app_providers.dart';
import 'package:scoring_app/shared/providers/repository_providers.dart';

/// No-op sync so the controller's best-effort live push never hits the network.
class _FakeSyncApi implements SyncApi {
  @override
  Future<Map<String, dynamic>> push(
    String deviceId,
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> tournaments,
  ) async =>
      const {};

  @override
  Future<PulledDocs> pull(String deviceId) async =>
      (matches: const [], tournaments: const []);
}

void main() {
  late Directory tempDir;
  late MatchRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scoring_hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.matches);
    await Hive.openBox<String>(HiveBoxes.players);
    repo = MatchRepository(local: LocalMatchDataSource(), remote: MatchApi(ApiClient()));
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveBoxes.matches);
    await Hive.deleteBoxFromDisk(HiveBoxes.players);
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  CricketMatch newMatch({int overs = 20, int playersPerSide = 11}) => CricketMatch(
        id: 'm1',
        team1: 'A',
        team2: 'B',
        overs: overs,
        battingFirst: 'A',
        createdAt: DateTime(2026),
        playersPerSide: playersPerSide,
        innings: const [Innings(battingTeam: 'A', bowlingTeam: 'B')],
      );

  ({LiveScoringController controller, ProviderContainer container}) buildReady(
      {int overs = 20, int playersPerSide = 11}) {
    repo.saveMatch(newMatch(overs: overs, playersPerSide: playersPerSide));
    final container = ProviderContainer(
      overrides: [
        matchRepositoryProvider.overrideWithValue(repo),
        syncApiProvider.overrideWithValue(_FakeSyncApi()),
        deviceIdProvider.overrideWithValue('test-device'),
      ],
    );
    final controller = container.read(liveScoringControllerProvider('m1').notifier);
    controller.setOpeners(striker: 'Striker', nonStriker: 'NonStriker');
    controller.setBowler('Bowler');
    return (controller: controller, container: container);
  }

  CricketMatch read(ProviderContainer c) => c.read(liveScoringControllerProvider('m1'));

  test('single rotates the strike', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreRuns(1);
    final inn = read(container).currentInnings;

    expect(inn.runs, 1);
    expect(inn.legalBalls, 1);
    expect(inn.striker, 'NonStriker'); // rotated
    expect(inn.nonStriker, 'Striker');
  });

  test('boundary keeps the strike', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreRuns(4);
    final inn = read(container).currentInnings;

    expect(inn.runs, 4);
    expect(inn.striker, 'Striker');
    expect(inn.batStat('Striker').fours, 1);
  });

  test('wide adds a run but is not a legal ball', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreExtra(ExtraType.wide, runs: 1);
    final inn = read(container).currentInnings;

    expect(inn.runs, 1);
    expect(inn.legalBalls, 0);
  });

  test('completing the over swaps strike and requires a new bowler', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    for (var i = 0; i < 6; i++) {
      controller.scoreRuns(0); // six dot balls
    }
    final inn = read(container).currentInnings;

    expect(inn.legalBalls, 6);
    expect(inn.oversText, '1.0');
    expect(inn.bowler, isNull); // cleared → must pick next bowler
    expect(controller.needsBowler, isTrue);
    // 6 dots = no run-swaps; one end-of-over swap.
    expect(inn.striker, 'NonStriker');
  });

  test('a wide after a new over does not re-prompt for the bowler', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    for (var i = 0; i < 6; i++) {
      controller.scoreRuns(0); // complete the over → bowler cleared
    }
    controller.setBowler('NewBowler');
    expect(controller.needsBowler, isFalse);

    controller.scoreExtra(ExtraType.wide, runs: 1);

    expect(controller.needsBowler, isFalse); // bug: used to re-prompt
    expect(read(container).currentInnings.bowler, 'NewBowler');
    expect(read(container).currentInnings.runs, 1);
    expect(read(container).currentInnings.legalBalls, 6); // wide is not legal
  });

  test('a no-ball after a new over does not re-prompt for the bowler', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    for (var i = 0; i < 6; i++) {
      controller.scoreRuns(0);
    }
    controller.setBowler('NewBowler');

    controller.scoreExtra(ExtraType.noBall, runs: 1);

    expect(controller.needsBowler, isFalse);
    expect(read(container).currentInnings.bowler, 'NewBowler');
  });

  test('prior bowlers list grows and flags the last-over bowler', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    // Over 1 bowled by 'Bowler' (set in buildReady).
    for (var i = 0; i < 6; i++) {
      controller.scoreRuns(0);
    }
    expect(controller.priorBowlers, ['Bowler']);
    expect(controller.lastOverBowler, 'Bowler');

    // Over 2 by 'Second'.
    controller.setBowler('Second');
    for (var i = 0; i < 6; i++) {
      controller.scoreRuns(0);
    }
    expect(controller.priorBowlers, ['Bowler', 'Second']);
    expect(controller.lastOverBowler, 'Second'); // ineligible for over 3
  });

  test('wicket increments wickets and brings in the new batsman on strike', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreWicket(WicketType.bowled, newBatsman: 'Fresh');
    final inn = read(container).currentInnings;

    expect(inn.wickets, 1);
    expect(inn.legalBalls, 1);
    expect(inn.striker, 'Fresh');
    expect(inn.bowlStat('Bowler').wickets, 1);
  });

  test('first innings end starts the chase with a target', () {
    final (:controller, :container) = buildReady(overs: 1);
    addTearDown(container.dispose);

    controller.scoreRuns(2);
    for (var i = 0; i < 5; i++) {
      controller.scoreRuns(0);
    }
    final match = read(container);

    expect(match.isSecondInnings, isTrue);
    expect(match.innings.first.isComplete, isTrue);
    expect(match.currentInnings.battingTeam, 'B');
    expect(match.currentInnings.target, 3); // 2 runs + 1
  });

  test('undo removes the last ball', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreRuns(4);
    controller.scoreRuns(2);
    expect(read(container).currentInnings.runs, 6);

    controller.undo();
    expect(read(container).currentInnings.runs, 4);
    expect(read(container).currentInnings.balls.length, 1);
  });

  test('no-ball off the bat: +1 penalty plus bat runs to the striker', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreNoBall(batRuns: 4);
    final inn = read(container).currentInnings;

    expect(inn.runs, 5); // 4 off the bat + 1 no-ball penalty
    expect(inn.legalBalls, 0); // not a legal delivery
    expect(inn.extras, 1); // only the penalty is an extra
    expect(inn.batStat('Striker').runs, 4);
    expect(inn.batStat('Striker').fours, 1);
    expect(inn.bowlStat('Bowler').runsConceded, 5);
    expect(inn.striker, 'Striker'); // even bat runs → strike retained
  });

  test('no-ball off the bat rotates strike on odd bat runs', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreNoBall(batRuns: 1);
    final inn = read(container).currentInnings;

    expect(inn.runs, 2); // 1 + penalty
    expect(inn.striker, 'NonStriker'); // rotated on the single
  });

  test('squad size ends the innings at playersPerSide - 1 wickets', () {
    final (:controller, :container) = buildReady(playersPerSide: 3);
    addTearDown(container.dispose);

    // 3 a side → all out at 2 wickets.
    controller.scoreWicket(WicketType.bowled, newBatsman: 'Third');
    expect(read(container).isComplete, isFalse);
    expect(controller.isFinalWicket, isTrue); // the next wicket is the last

    controller.scoreWicket(WicketType.bowled, newBatsman: '');
    final match = read(container);
    expect(match.innings.first.wickets, 2); // all out at 2 down
    expect(match.innings.first.isComplete, isTrue);
    expect(match.isSecondInnings, isTrue); // chase begins
  });

  test('rewind to a ball removes it and everything after, restoring state', () {
    final (:controller, :container) = buildReady();
    addTearDown(container.dispose);

    controller.scoreRuns(2); // ball 1: Striker faces, even → keeps strike
    final firstBallId = read(container).currentInnings.balls.first.id;
    controller.scoreRuns(1); // ball 2: rotates
    controller.scoreRuns(4); // ball 3

    expect(read(container).currentInnings.balls.length, 3);

    controller.rewindToBall(firstBallId);
    final inn = read(container).currentInnings;

    expect(inn.balls, isEmpty); // ball 1 and everything after removed
    expect(inn.striker, 'Striker'); // restored to pre-ball-1 state
    expect(inn.nonStriker, 'NonStriker');
    expect(inn.bowler, 'Bowler');
  });
}
