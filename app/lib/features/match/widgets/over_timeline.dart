import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ball_event.dart';

/// This over's deliveries as colored chips. Uses a [Wrap] so a long over flows
/// onto the next line instead of scrolling off the right edge of the screen.
class OverTimeline extends StatelessWidget {
  const OverTimeline({super.key, required this.balls});

  final List<BallEvent> balls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS OVER', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          if (balls.isEmpty)
            Text('—', style: TextStyle(color: context.txLow, fontSize: 18))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final b in balls) _BallChip(b)],
            ),
        ],
      ),
    );
  }
}

class _BallChip extends StatelessWidget {
  const _BallChip(this.ball);
  final BallEvent ball;

  List<Color>? get _gradient {
    if (ball.wicket != null) return AppColors.wicketGrad;
    if (ball.extraType != null) return AppColors.amber;
    if (ball.runs == 6) return AppColors.sixGrad;
    if (ball.runs == 4) return AppColors.fourGrad;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient;
    final isDot = gradient == null && ball.runs == 0;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    // NOTE: no `alignment` on this Container — inside a Wrap an aligned
    // Container expands to the full available width (each chip would become a
    // full-width bar). We size to content and center via the Center below.
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: gradient == null
            ? (isDot
                ? (isDarkTheme ? AppColors.glassFill : Colors.black.withValues(alpha: 0.05))
                : AppColors.dot)
            : null,
        borderRadius: BorderRadius.circular(19),
        border: gradient == null ? Border.all(color: context.hairline) : null,
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Center(
        widthFactor: 1.0,
        child: Text(
          ball.label,
          style: TextStyle(
            color: isDot ? context.txMid : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
