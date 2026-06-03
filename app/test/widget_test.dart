import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scoring_app/features/home/home_screen.dart';

void main() {
  testWidgets('Home screen shows the feature tiles', (tester) async {
    // Large surface so the lazy GridView builds every tile.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('New Match'), findsOneWidget);
    expect(find.text('Tournaments'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Leaderboards'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
