import 'api_client.dart';

/// Remote API for matches. Wired to the backend endpoints from CLAUDE.md.
///
/// V1 note: live scoring is fully functional offline via Hive. Pushing local
/// matches to the server requires the backend to hold Team/Player rows first,
/// so the sync mapping is intentionally a structured stub for now — the local
/// store remains the source of truth (local-first per CLAUDE.md).
class MatchApi {
  MatchApi(this._client);

  final ApiClient _client;

  Future<bool> pushBall(String matchId, Map<String, dynamic> ball) async {
    try {
      await _client.post('/matches/$matchId/balls', data: ball);
      return true;
    } catch (_) {
      // Offline or not-yet-synced match — keep local and try again later.
      return false;
    }
  }
}
