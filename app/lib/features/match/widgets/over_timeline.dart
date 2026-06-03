import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/ball_event.dart';

/// Horizontal strip of this over's deliveries as colored chips.
class OverTimeline extends StatelessWidget {
  const OverTimeline({super.key, required this.balls});

  final List<BallEvent> balls;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('This over', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 36,
              child: balls.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('—'),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: balls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => _BallChip(balls[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BallChip extends StatelessWidget {
  const _BallChip(this.ball);
  final BallEvent ball;

  Color get _color {
    if (ball.wicket != null) return AppColors.wicket;
    if (ball.extraType != null) return AppColors.accent;
    if (ball.runs == 6) return AppColors.six;
    if (ball.runs == 4) return AppColors.four;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        ball.label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
