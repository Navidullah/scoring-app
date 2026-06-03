import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/tournament.dart';

/// Persists tournaments to the local Hive box as JSON (offline-first).
class LocalTournamentDataSource {
  Box<String> get _box => Hive.box<String>(HiveBoxes.tournaments);

  void save(Tournament tournament) {
    _box.put(tournament.id, jsonEncode(tournament.toJson()));
  }

  Tournament? get(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Tournament.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<Tournament> getAll() {
    return _box.values
        .map((raw) => Tournament.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void delete(String id) => _box.delete(id);
}
