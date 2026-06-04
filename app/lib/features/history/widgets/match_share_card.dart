import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/cricket_enums.dart';
import '../../../domain/models/cricket_match.dart';
import '../../../shared/widgets/ui_widgets.dart';
import '../services/player_of_match.dart';

/// A fixed-width, fully opaque match-summary card designed to be captured to a
/// PNG and shared (WhatsApp / Instagram). Self-contained styling (no glass /
/// transparency) so it renders cleanly as an image.
class MatchShareCard extends StatelessWidget {
  const MatchShareCard({super.key, required this.match, this.width = 340});

  final CricketMatch match;
  final double width;

  @override
  Widget build(BuildContext context) {
    final potm = playerOfTheMatch(match);
    final ballLabel = match.ballType == BallType.tennis ? 'Tennis' : 'Leather';

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
                'CRICKET SCORING',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM yyyy').format(match.createdAt),
                style: const TextStyle(color: AppColors.textLow, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${match.team1}  vs  ${match.team2}',
            style: const TextStyle(
              color: AppColors.textHi,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$ballLabel ball  •  ${match.overs} overs',
            style: const TextStyle(color: AppColors.textLow, fontSize: 11),
          ),
          if (match.resultText != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brand),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                match.resultText!,
                style: const TextStyle(
                  color: Color(0xFF06251A),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          for (final inn in match.innings) ...[
            _InningsRow(
              team: inn.battingTeam,
              score: '${inn.runs}/${inn.wickets}',
              overs: '(${inn.oversText} ov)',
            ),
            const SizedBox(height: 10),
          ],
          if (potm != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const NeonIconBadge(
                    icon: Icons.star_rounded,
                    gradient: AppColors.trophy,
                    size: 32,
                    iconSize: 17,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PLAYER OF THE MATCH',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            )),
                        Text(potm.name,
                            style: const TextStyle(
                                color: AppColors.textHi, fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Scored with Cricket Scoring',
              style: TextStyle(color: AppColors.textLow, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _InningsRow extends StatelessWidget {
  const _InningsRow({required this.team, required this.score, required this.overs});
  final String team;
  final String score;
  final String overs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.brand,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(
            team,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textHi, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Text(score,
            style: const TextStyle(color: AppColors.primary, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Text(overs, style: const TextStyle(color: AppColors.textLow, fontSize: 11)),
      ],
    );
  }
}
