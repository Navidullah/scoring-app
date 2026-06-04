import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cricket_match.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ui_widgets.dart';

/// Big broadcast-style score line + run-rate info. Shows chase context in the
/// second innings.
class ScoreboardHeader extends StatelessWidget {
  const ScoreboardHeader({super.key, required this.match});

  final CricketMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inn = match.currentInnings;
    final ballsRemaining = match.overs * AppConstants.ballsPerOver - inn.legalBalls;

    return GlassCard(
      strong: true,
      glowColor: AppColors.primary,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.wicket,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.wicket,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                inn.battingTeam,
                style: theme.textTheme.titleSmall?.copyWith(color: context.txMid),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GradientText(
                '${inn.runs}/${inn.wickets}',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${inn.oversText}/${match.overs} ov',
                  style: theme.textTheme.titleMedium?.copyWith(color: context.txMid),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(label: 'CRR', value: inn.runRate.toStringAsFixed(2)),
              if (inn.target != null)
                StatPill(
                  label: 'Target',
                  value: '${inn.target}',
                  color: AppColors.accent,
                ),
            ],
          ),
          if (inn.target != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                _chaseLine(inn.target! - inn.runs, ballsRemaining),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _chaseLine(int need, int ballsRemaining) {
    if (need <= 0) return '🎉 Target reached';
    if (ballsRemaining <= 0) return 'Overs finished';
    final rrr = (need * AppConstants.ballsPerOver) / ballsRemaining;
    return 'Need $need run${need == 1 ? '' : 's'} from $ballsRemaining ball'
        '${ballsRemaining == 1 ? '' : 's'}  •  RRR ${rrr.toStringAsFixed(2)}';
  }
}
