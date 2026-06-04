import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/live_api.dart';
import '../../data/remote/sync_api.dart';

/// Shared singletons exposed to the widget tree via Riverpod.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final syncApiProvider = Provider<SyncApi>((ref) => SyncApi(ref.read(apiClientProvider)));

final liveApiProvider = Provider<LiveApi>((ref) => LiveApi(ref.read(apiClientProvider)));

/// Anonymous device identity (CLAUDE.md: device-id based, no auth). Generated
/// once and persisted in the settings box.
final deviceIdProvider = Provider<String>((ref) {
  final box = Hive.box<dynamic>(HiveBoxes.settings);
  var id = box.get('deviceId') as String?;
  if (id == null) {
    id = const Uuid().v4();
    box.put('deviceId', id);
  }
  return id;
});
