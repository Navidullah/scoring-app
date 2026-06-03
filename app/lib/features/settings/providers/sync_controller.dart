import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/remote/sync_api.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/repositories/tournament_repository.dart';
import '../../../domain/models/cricket_match.dart';
import '../../../domain/models/tournament.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/repository_providers.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.online = true,
    this.message,
    this.lastSyncedAt,
  });

  final SyncStatus status;
  final bool online;
  final String? message;
  final DateTime? lastSyncedAt;

  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    bool? online,
    String? message,
    DateTime? lastSyncedAt,
  }) {
    return SyncState(
      status: status ?? this.status,
      online: online ?? this.online,
      message: message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

/// Coordinates offline-first snapshot sync: pushes all local matches/tournaments
/// to the backend and can restore them. Auto-pushes when connectivity returns.
class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required this.deviceId,
    required this.syncApi,
    required this.matchRepo,
    required this.tournamentRepo,
    required this.settings,
    bool watchConnectivity = true,
  }) : super(const SyncState()) {
    final saved = settings.get('lastSyncedAt') as String?;
    if (saved != null) {
      state = state.copyWith(lastSyncedAt: DateTime.tryParse(saved));
    }
    if (watchConnectivity) _watchConnectivity();
  }

  final String deviceId;
  final SyncApi syncApi;
  final MatchRepository matchRepo;
  final TournamentRepository tournamentRepo;
  final Box<dynamic> settings;

  void _watchConnectivity() {
    // Defensive: if the platform plugin is unavailable, assume online.
    Connectivity().checkConnectivity().then(_apply).catchError((_) {});
    Connectivity().onConnectivityChanged.listen(_apply, onError: (_) {});
  }

  void _apply(List<ConnectivityResult> result) {
    final online = !result.contains(ConnectivityResult.none);
    final wasOffline = !state.online;
    state = state.copyWith(online: online);
    // Best-effort auto-push when coming back online.
    if (online && wasOffline && !state.isSyncing) {
      syncNow();
    }
  }

  /// Pushes every local match and tournament to the backend.
  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(status: SyncStatus.syncing, message: null);
    try {
      final matches = matchRepo.getAllMatches().map((m) => m.toJson()).toList();
      final tournaments = tournamentRepo.getAll().map((t) => t.toJson()).toList();
      final result = await syncApi.push(deviceId, matches, tournaments);
      final now = DateTime.now();
      await settings.put('lastSyncedAt', now.toIso8601String());
      final pushed = result['pushed'] as Map?;
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncedAt: now,
        message: 'Synced ${pushed?['matches'] ?? 0} matches, '
            '${pushed?['tournaments'] ?? 0} tournaments',
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Sync failed (offline?). Will retry when online.',
      );
    }
  }

  /// Restores documents from the cloud. Local data wins: only documents not
  /// present locally are added (in-progress local matches are never clobbered).
  Future<void> restoreFromCloud() async {
    if (state.isSyncing) return;
    state = state.copyWith(status: SyncStatus.syncing, message: null);
    try {
      final docs = await syncApi.pull(deviceId);
      var added = 0;
      for (final raw in docs.matches) {
        final json = (raw as Map).cast<String, dynamic>();
        if (matchRepo.getMatch(json['id'] as String) == null) {
          matchRepo.saveMatch(CricketMatch.fromJson(json));
          added++;
        }
      }
      for (final raw in docs.tournaments) {
        final json = (raw as Map).cast<String, dynamic>();
        if (tournamentRepo.get(json['id'] as String) == null) {
          tournamentRepo.save(Tournament.fromJson(json));
          added++;
        }
      }
      state = state.copyWith(
        status: SyncStatus.success,
        message: added == 0 ? 'Already up to date' : 'Restored $added item(s)',
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        message: 'Restore failed (offline?)',
      );
    }
  }
}

final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(
    deviceId: ref.watch(deviceIdProvider),
    syncApi: ref.watch(syncApiProvider),
    matchRepo: ref.watch(matchRepositoryProvider),
    tournamentRepo: ref.watch(tournamentRepositoryProvider),
    settings: Hive.box<dynamic>(HiveBoxes.settings),
  );
});
