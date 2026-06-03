import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/animated_gradient_background.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/theme_provider.dart';

/// App root: theme + router. The animated gradient is painted behind every
/// route via the [MaterialApp.router] builder.
class CricketScoringApp extends ConsumerWidget {
  const CricketScoringApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) =>
          AnimatedGradientBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
