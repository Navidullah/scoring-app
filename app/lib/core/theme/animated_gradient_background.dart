import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A deep, premium backdrop painted behind the whole app: a base vertical
/// gradient plus two slowly drifting neon "glow" blobs (green + cyan) that give
/// the UI depth and that signature sports/energy feel. Adapts to brightness.
/// Wrap the app's content so transparent Scaffolds reveal it.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColors = isDark
        ? const [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom]
        : const [AppColors.lightBgTop, Color(0xFFEDF4FA), AppColors.lightBgBottom];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final glowOpacity = isDark ? 0.22 : 0.16;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: baseColors,
            ),
          ),
          child: Stack(
            children: [
              // Green glow drifting near the top.
              _glow(
                alignment: Alignment(-0.9 + t * 0.5, -1.0 + t * 0.25),
                color: AppColors.primary.withValues(alpha: glowOpacity),
              ),
              // Cyan glow drifting near the bottom.
              _glow(
                alignment: Alignment(0.95 - t * 0.4, 0.9 - t * 0.2),
                color: AppColors.cyan.withValues(alpha: glowOpacity * 0.85),
              ),
              if (child != null) Positioned.fill(child: child),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _glow({required Alignment alignment, required Color color}) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: 460,
          height: 460,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
