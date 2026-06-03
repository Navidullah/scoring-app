import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';

/// Persisted theme mode. Defaults to dark (user preference).
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._box) : super(_load(_box));

  final Box<dynamic> _box;

  static ThemeMode _load(Box<dynamic> box) {
    return (box.get('themeMode') as String?) == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  bool get isDark => state == ThemeMode.dark;

  void setDark(bool dark) {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    _box.put('themeMode', dark ? 'dark' : 'light');
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(Hive.box<dynamic>(HiveBoxes.settings));
});
