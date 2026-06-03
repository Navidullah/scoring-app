import 'api_client.dart';

/// Documents returned from a pull.
typedef PulledDocs = ({List<dynamic> matches, List<dynamic> tournaments});

/// Remote client for the snapshot sync endpoints (POST/GET /api/sync).
class SyncApi {
  SyncApi(this._client);

  final ApiClient _client;

  /// Pushes local match/tournament snapshots. Returns the server's summary.
  Future<Map<String, dynamic>> push(
    String deviceId,
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> tournaments,
  ) async {
    final res = await _client.post('/sync', data: {
      'deviceId': deviceId,
      'matches': matches,
      'tournaments': tournaments,
    });
    return (res.data['data'] as Map).cast<String, dynamic>();
  }

  /// Pulls all stored documents for the device.
  Future<PulledDocs> pull(String deviceId) async {
    final res = await _client.get('/sync/$deviceId');
    final data = res.data['data'] as Map;
    return (
      matches: (data['matches'] as List<dynamic>?) ?? const [],
      tournaments: (data['tournaments'] as List<dynamic>?) ?? const [],
    );
  }
}
