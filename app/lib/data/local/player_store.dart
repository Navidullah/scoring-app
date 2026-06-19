import 'dart:convert';

import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/string_utils.dart';

/// Remembered teams and players so names don't have to be re-typed every match.
///
/// Stored as a single JSON document in the [HiveBoxes.players] box:
/// `{ "names": [...all distinct players...], "squads": { "team": [players] } }`.
/// Team keys are lower-cased for case-insensitive recall; the display name keeps
/// the original casing via [teamNames].
class PlayerStore {
  Box<String> get _box => Hive.box<String>(HiveBoxes.players);
  static const _key = 'store';

  Map<String, dynamic> _read() {
    final raw = _box.get(_key);
    if (raw == null) return {'names': <String>[], 'squads': <String, dynamic>{}};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  void _write(Map<String, dynamic> data) => _box.put(_key, jsonEncode(data));

  /// All distinct player names ever entered, alphabetically sorted.
  List<String> get allPlayers {
    final list = (_read()['names'] as List<dynamic>).cast<String>();
    return [...list]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Distinct team names ever used, in their saved display casing, sorted.
  List<String> get teamNames {
    final squads = (_read()['squads'] as Map<String, dynamic>);
    final names = squads.values
        .map((v) => (v as Map<String, dynamic>)['display'] as String)
        .toList();
    return names..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Saved squad for [team] (case-insensitive), or empty if unknown.
  List<String> squadFor(String team) {
    final squads = _read()['squads'] as Map<String, dynamic>;
    final entry = squads[team.trim().toLowerCase()];
    if (entry == null) return const [];
    return ((entry as Map<String, dynamic>)['players'] as List<dynamic>).cast<String>();
  }

  /// Records a single player name into the global list (title-cased, de-duped).
  void recordPlayer(String name) => recordPlayers([name]);

  /// Records several player names into the global list.
  void recordPlayers(Iterable<String> names) {
    final data = _read();
    final list = (data['names'] as List<dynamic>).cast<String>();
    final set = {for (final n in list) n.toLowerCase(): n};
    for (final raw in names) {
      final n = titleCase(raw);
      if (n.isEmpty) continue;
      set[n.toLowerCase()] = n; // last write wins, keeps newest casing
    }
    data['names'] = set.values.toList();
    _write(data);
  }

  /// Merges [players] into [team]'s saved squad and records them globally.
  /// Existing squad members are kept; new ones are appended in arrival order.
  void recordSquad(String team, Iterable<String> players) {
    final teamName = titleCase(team);
    if (teamName.isEmpty) return;
    final cleaned = players.map(titleCase).where((p) => p.isNotEmpty).toList();

    final data = _read();
    final squads = data['squads'] as Map<String, dynamic>;
    final key = teamName.toLowerCase();
    final existing = squads[key] as Map<String, dynamic>?;
    final current = existing == null
        ? <String>[]
        : (existing['players'] as List<dynamic>).cast<String>();
    final seen = {for (final p in current) p.toLowerCase()};
    for (final p in cleaned) {
      if (seen.add(p.toLowerCase())) current.add(p);
    }
    squads[key] = {'display': teamName, 'players': current};
    data['squads'] = squads;
    _write(data);

    if (cleaned.isNotEmpty) recordPlayers(cleaned);
  }
}
