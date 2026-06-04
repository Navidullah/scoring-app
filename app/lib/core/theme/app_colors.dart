import 'package:flutter/material.dart';

/// Brand palette — a dark, premium, neon-accented system tuned to the glowing
/// launcher icon (deep navy base with vivid green/cyan energy). Use these
/// tokens everywhere; never hardcode raw colors in widgets.
class AppColors {
  const AppColors._();

  // ---- Brand seed + accents ------------------------------------------------
  static const Color seed = Color(0xFF12E29A); // neon spring-green
  static const Color primary = Color(0xFF12E29A);
  static const Color primaryDeep = Color(0xFF0BBF80);
  static const Color cyan = Color(0xFF22D3EE); // electric cyan
  static const Color accent = Color(0xFFFFB020); // ball-leather amber

  // ---- Backgrounds (dark) --------------------------------------------------
  static const Color bgTop = Color(0xFF0A0E1A);
  static const Color bgMid = Color(0xFF0A1124);
  static const Color bgBottom = Color(0xFF0B1630);
  static const Color surface = Color(0xFF111A2E);
  static const Color surfaceHi = Color(0xFF16223C);
  static const Color scoreboard = Color(0xFF0C1426);

  // ---- Backgrounds (light) -------------------------------------------------
  static const Color lightBgTop = Color(0xFFEAF7F1);
  static const Color lightBgBottom = Color(0xFFE7F0FB);

  // ---- Cricket event colors ------------------------------------------------
  static const Color four = Color(0xFF2E8BFF);
  static const Color six = Color(0xFFB15CFF);
  static const Color wicket = Color(0xFFFF4D6D);
  static const Color dot = Color(0xFF55617A);

  // ---- Text (on dark) ------------------------------------------------------
  static const Color textHi = Color(0xFFF2F6FC);
  static const Color textMid = Color(0xB3FFFFFF); // 70%
  static const Color textLow = Color(0x66FFFFFF); // 40%

  // ---- Text (on light) -----------------------------------------------------
  static const Color lightTextHi = Color(0xFF0B1A2E); // deep navy ink

  // ---- Glass surfaces ------------------------------------------------------
  static const Color glassFill = Color(0x14FFFFFF); // ~8% white
  static const Color glassFillStrong = Color(0x1FFFFFFF); // ~12% white
  static const Color glassStroke = Color(0x26FFFFFF); // ~15% white border
  static const Color glassStrokeSoft = Color(0x14FFFFFF);

  // ---- Gradients -----------------------------------------------------------
  static const List<Color> brand = [Color(0xFF12E29A), Color(0xFF22D3EE)];
  static const List<Color> amber = [Color(0xFFFFC24B), Color(0xFFFF7A1A)];
  static const List<Color> wicketGrad = [Color(0xFFFF6584), Color(0xFFE11D48)];
  static const List<Color> fourGrad = [Color(0xFF4F9DFF), Color(0xFF1F6FE5)];
  static const List<Color> sixGrad = [Color(0xFFC174FF), Color(0xFF8B2FE0)];
  static const List<Color> trophy = [Color(0xFFFFD76A), Color(0xFFFF9D2E)];
}

/// Brightness-adaptive text tones. Use `context.txHi/txMid/txLow` instead of
/// the raw `AppColors.textHi/...` tokens so text stays readable in BOTH themes
/// (near-white on dark, deep-navy ink on light).
extension AppTones on BuildContext {
  bool get _toneDark => Theme.of(this).brightness == Brightness.dark;
  Color get _toneBase => _toneDark ? AppColors.textHi : AppColors.lightTextHi;

  Color get txHi => _toneBase;
  Color get txMid => _toneBase.withValues(alpha: 0.66);
  Color get txLow => _toneBase.withValues(alpha: 0.42);

  /// A subtle hairline/border tone that reads on both backgrounds.
  Color get hairline =>
      _toneDark ? AppColors.glassStroke : Colors.black.withValues(alpha: 0.08);
}
