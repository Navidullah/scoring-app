import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:scoring_app/core/constants/app_constants.dart';
import 'package:scoring_app/data/local/local_match_data_source.dart';
import 'package:scoring_app/data/local/local_tournament_data_source.dart';
import 'package:scoring_app/data/remote/api_client.dart';
import 'package:scoring_app/data/remote/match_api.dart';
import 'package:scoring_app/data/remote/sync_api.dart';
import 'package:scoring_app/data/repositories/match_repository.dart';
import 'package:scoring_app/data/repositories/tournament_repository.dart';
import 'package:scoring_app/domain/enums/cricket_enums.dart';
import 'package:scoring_app/domain/models/cricket_match.dart';
import 'package:scoring_app/domain/models/innings.dart';
import 'package:scoring_app/features/settings/providers/sync_controller.dart';

/// Records pushes and serves canned pull data — no network.
class FakeSyncApi extends SyncApi {
  FakeSyncApi() : super(ApiClient());

  List<Map<String, dynamic>>? pushedMatches;
  List<Map<String, dynamic>>? pushedTournaments;
  PulledDocs pullResult = (matches: const [], tournaments: const []);
  bool failPush = false;

  @override
  Future<Map<String, dynamic>> push(
    String deviceId,
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> tournaments,
  ) async {
    if (failPush) throw Exception('offline');
    pushedMatches = matches;
    pushedTournaments = tournaments;
    return {
      'pushed': {'matches': matches.length, 'tournaments': tournaments.length},
    };
  }

  @override
  Future<PulledDocs> pull(String deviceId) async => pullResult;
}

CricketMatch _match(String id) => CricketMatch(
      id: id,
      team1: 'A',
      team2: 'B',
      overs: 20,
      battingFirst: 'A',
      createdAt: DateTime(2026),
      status: MatchStatus.inProgress,
      innings: const [Innings(battingTeam: 'A', bowlingTeam: 'B')],
    );

void main() {
  late Directory dir;
  late MatchRepository matchRepo;
  late TournamentRepository tournamentRepo;
  late Box<dynamic> settings;
  late FakeSyncApi api;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_test');
    Hive.init(dir.path);
    await Hive.openBox<String>(HiveBoxes.matches);
    await Hive.openBox<String>(HiveBoxes.tournaments);
    settings = await Hive.openBox<dynamic>(HiveBoxes.settings);
    matchRepo = MatchRepository(local: LocalMatchDataSource(), remote: MatchApi(ApiClient()));
    tournamentRepo = TournamentRepository(local: LocalTournamentDataSource());
    api = FakeSyncApi();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  SyncController build() => SyncController(
        deviceId: 'dev-test',
        syncApi: api,
        matchRepo: matchRepo,
        tournamentRepo: tournamentRepo,
        settings: settings,
        watchConnectivity: false,
      );

  test('syncNow pushes all local matches and records the time', () async {
    matchRepo.saveMatch(_match('m1'));
    matchRepo.saveMatch(_match('m2'));

    final controller = build();
    await controller.syncNow();

    expect(api.pushedMatches, isNotNull);
    expect(api.pushedMatches!.length, 2);
    expect(controller.state.status, SyncStatus.success);
    expect(controller.state.lastSyncedAt, isNotNull);
    expect(settings.get('lastSyncedAt'), isNotNull);
  });

  test('syncNow reports an error when the push fails', () async {
    api.failPush = true;
    final controller = build();
    await controller.syncNow();
    expect(controller.state.status, SyncStatus.error);
  });

  test('restore adds cloud matches that are missing locally', () async {
    api.pullResult = (matches: [_match('remote1').toJson()], tournaments: const []);
    final controller = build();

    expect(matchRepo.getMatch('remote1'), isNull);
    await controller.restoreFromCloud();

    expect(matchRepo.getMatch('remote1'), isNotNull);
    expect(controller.state.status, SyncStatus.success);
  });

  test('restore does not clobber an existing local match', () async {
    matchRepo.saveMatch(_match('m1')); // local copy exists
    final remote = _match('m1').toJson()..['team1'] = 'CHANGED';
    api.pullResult = (matches: [remote], tournaments: const []);

    final controller = build();
    await controller.restoreFromCloud();

    expect(matchRepo.getMatch('m1')!.team1, 'A'); // local wins
  });
}
