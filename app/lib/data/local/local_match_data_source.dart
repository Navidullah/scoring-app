import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/cricket_match.dart';

/// Persists matches to the local Hive box as JSON. This is the offline-first
/// source of truth — every scoring change is saved here immediately.
class LocalMatchDataSource {
  Box<String> get _box => Hive.box<String>(HiveBoxes.matches);

  void save(CricketMatch match) {
    _box.put(match.id, jsonEncode(match.toJson()));
  }

  CricketMatch? get(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return CricketMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  List<CricketMatch> getAll() {
    return _box.values
        .map((raw) => CricketMatch.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void delete(String id) => _box.delete(id);
}
