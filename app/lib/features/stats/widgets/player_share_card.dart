import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ui_widgets.dart';
import '../services/player_stats.dart';

/// A fixed-width, fully opaque player-stats card designed to be captured to a
/// PNG and shared (WhatsApp / Instagram). Self-contained styling so it renders
/// cleanly as an image.
class PlayerShareCard extends StatelessWidget {
  const PlayerShareCard({super.key, required this.career, this.width = 340});

  final PlayerCareer career;
  final double width;

  String get _initials => career.name.isEmpty
      ? '?'
      : career.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final b = career.batting;
    final w = career.bowling;
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1C30), Color(0xFF0A1322), Color(0xFF0B1A14)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassStroke),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NeonIconBadge(icon: Icons.sports_cricket_rounded, size: 34, iconSize: 18),
              const SizedBox(width: 10),
              const GradientText(
                'CRICLIVE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const Spacer(),
              Text(
                '${career.matches} match${career.matches == 1 ? '' : 'es'}',
                style: const TextStyle(color: AppColors.textLow, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.brand),
                  shape: BoxShape.circle,
                ),
                child: Text(_initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  career.name,
                  style: const TextStyle(
                    color: AppColors.textHi,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Section(
            title: 'BATTING',
            gradient: AppColors.brand,
            stats: [
              ('Runs', '${b.runs}'),
              ('HS', b.highScoreText),
              ('Avg', b.dismissals == 0 && b.runs == 0 ? '-' : b.average.toStringAsFixed(1)),
              ('SR', b.balls == 0 ? '-' : b.strikeRate.toStringAsFixed(0)),
              ('50/100', '${b.fifties}/${b.hundreds}'),
              ('6s', '${b.sixes}'),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'BOWLING',
            gradient: AppColors.wicketGrad,
            stats: [
              ('Wkts', '${w.wickets}'),
              ('Best', w.bestText),
              ('Avg', w.wickets == 0 ? '-' : w.average.toStringAsFixed(1)),
              ('Econ', w.balls == 0 ? '-' : w.economy.toStringAsFixed(1)),
              ('Overs', w.balls == 0 ? '-' : w.oversText),
              ('5w', '${w.fiveWicketHauls}'),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Career stats on CricLive',
              style: TextStyle(color: AppColors.textLow, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.gradient, required this.stats});
  final String title;
  final List<Color> gradient;
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 12, color: gradient.last),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textMid, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 0,
            runSpacing: 12,
            children: [
              for (final s in stats)
                SizedBox(
                  width: (width - 28) / 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2,
                          style: const TextStyle(
                              color: AppColors.textHi, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(s.$1, style: const TextStyle(color: AppColors.textLow, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Card body width minus this section's horizontal padding (matches the parent
  // card width of 340 − 22*2 outer − 14*2 inner). Kept simple/constant.
  double get width => 340 - 44;
}
