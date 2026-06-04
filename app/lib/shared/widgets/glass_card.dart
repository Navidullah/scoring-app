import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// A frosted, translucent "glass" surface with a soft border and depth shadow.
/// The workhorse container for the redesigned UI. Keeps things cheap (no
/// backdrop blur by default) so it's safe to use inside long scrolling lists.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius = 22,
    this.glowColor,
    this.strong = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;

  /// When set, adds a soft colored glow behind the card for emphasis.
  final Color? glowColor;

  /// Slightly more opaque fill — use for hero/primary surfaces.
  final bool strong;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    final fill = isDark
        ? (strong ? AppColors.glassFillStrong : AppColors.glassFill)
        : Colors.white.withValues(alpha: strong ? 0.92 : 0.82);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.28),
              blurRadius: 34,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: fill,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.05 : 0.0),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
              border: Border.all(
                color: borderColor ??
                    (isDark ? AppColors.glassStroke : Colors.black.withValues(alpha: 0.06)),
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
