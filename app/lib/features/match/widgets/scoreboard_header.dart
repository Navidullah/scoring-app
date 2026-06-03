import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/cricket_match.dart';

/// Big score line + run-rate info. Shows chase context in the second innings.
class ScoreboardHeader extends StatelessWidget {
  const ScoreboardHeader({super.key, required this.match});

  final CricketMatch match;

  @override
  Widget build(BuildContext context) {
    final inn = match.currentInnings;
    final ballsRemaining = match.overs * AppConstants.ballsPerOver - inn.legalBalls;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.scoreboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inn.battingTeam,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${inn.runs}/${inn.wickets}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '(${inn.oversText}/${match.overs} ov)',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('CRR', inn.runRate.toStringAsFixed(2)),
              if (inn.target != null) ...[
                const SizedBox(width: 8),
                _chip('Target', '${inn.target}'),
              ],
            ],
          ),
          if (inn.target != null) ...[
            const SizedBox(height: 8),
            Text(
              _chaseLine(inn.target! - inn.runs, ballsRemaining),
              style: const TextStyle(color: AppColors.accent, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  String _chaseLine(int need, int ballsRemaining) {
    if (need <= 0) return 'Target reached';
    if (ballsRemaining <= 0) return 'Overs finished';
    final rrr = (need * AppConstants.ballsPerOver) / ballsRemaining;
    return 'Need $need run${need == 1 ? '' : 's'} from $ballsRemaining ball'
        '${ballsRemaining == 1 ? '' : 's'}  •  RRR ${rrr.toStringAsFixed(2)}';
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label  $value', style: const TextStyle(color: Colors.white)),
    );
  }
}
