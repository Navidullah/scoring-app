import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 theme. Scaffolds are transparent so the animated gradient
/// background shows through; cards are translucent and rounded for a modern,
/// layered look.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      secondary: AppColors.accent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0D2818),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xE6143626) : Colors.white.withValues(alpha: 0.82),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.accent),
    );
  }
}
