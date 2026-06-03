import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Offline-first: initialize local storage before the app starts.
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(HiveBoxes.settings);
  await Hive.openBox<String>(HiveBoxes.matches); // matches stored as JSON
  await Hive.openBox<String>(HiveBoxes.tournaments); // tournaments as JSON

  runApp(const ProviderScope(child: CricketScoringApp()));
}
