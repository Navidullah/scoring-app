import 'package:flutter/material.dart';

/// A slowly shifting gradient painted behind the whole app. Adapts to the
/// current brightness (rich dark greens/teal/navy in dark mode, soft pastels
/// in light mode). Wrap the app's content so transparent Scaffolds reveal it.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  // Dark palette endpoints.
  static const _darkA = [Color(0xFF06281A), Color(0xFF0A3340), Color(0xFF0B1E33)];
  static const _darkB = [Color(0xFF0A3A2A), Color(0xFF0E2A3A), Color(0xFF102444)];
  // Light palette endpoints.
  static const _lightA = [Color(0xFFE8F5E9), Color(0xFFE0F2F1), Color(0xFFE3F2FD)];
  static const _lightB = [Color(0xFFF1F8E9), Color(0xFFE0F7FA), Color(0xFFEDE7F6)];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final from = isDark ? _darkA : _lightA;
    final to = isDark ? _darkB : _lightB;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final colors = [
          Color.lerp(from[0], to[0], t)!,
          Color.lerp(from[1], to[1], t)!,
          Color.lerp(from[2], to[2], t)!,
        ];
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
