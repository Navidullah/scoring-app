import 'api_client.dart';

/// Remote client for the public live-match endpoints.
class LiveApi {
  LiveApi(this._client);

  final ApiClient _client;

  /// Summaries of currently in-progress matches across all devices.
  Future<List<Map<String, dynamic>>> list() async {
    final res = await _client.get('/live');
    final data = (res.data['data'] as List<dynamic>?) ?? const [];
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// Summaries of finished matches across all devices (last 24h).
  Future<List<Map<String, dynamic>>> results() async {
    final res = await _client.get('/results');
    final data = (res.data['data'] as List<dynamic>?) ?? const [];
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// Global top run-scorers and wicket-takers across all devices. Each row is
  /// `{ name, value, matches }`.
  Future<({List<Map<String, dynamic>> runs, List<Map<String, dynamic>> wickets})>
      leaderboard() async {
    final res = await _client.get('/leaderboard');
    final data = (res.data['data'] as Map).cast<String, dynamic>();
    List<Map<String, dynamic>> rows(String key) =>
        ((data[key] as List<dynamic>?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
    return (runs: rows('runs'), wickets: rows('wickets'));
  }

  /// Full snapshot (CricketMatch JSON) for a single match, or null if missing.
  Future<Map<String, dynamic>?> getMatch(String id) async {
    try {
      final res = await _client.get('/live/$id');
      return (res.data['data'] as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
}
