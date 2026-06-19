import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/cricket_match.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'services/player_of_match.dart';
import 'services/scorecard_pdf.dart';
import 'services/share_image.dart';
import 'widgets/innings_scorecard.dart';

/// Full scorecard for a match: result banner + a card per innings.
///
/// Pass [matchId] to load a locally-stored match (History), or pass an in-memory
/// [match] to render a snapshot fetched from the cloud (Results). Exactly one
/// should be provided.
class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({super.key, this.matchId, this.match})
      : assert(matchId != null || match != null,
            'Provide either a matchId or a match');

  final String? matchId;
  final CricketMatch? match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match =
        this.match ?? ref.watch(matchRepositoryProvider).getMatch(matchId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/history'),
        ),
        actions: [
          if (match != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share',
              onSelected: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  if (v == 'image') {
                    await shareMatchImage(context, match);
                  } else {
                    await shareScorecardPdf(match);
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Could not share scorecard: $e')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'image',
                  child: Row(children: [
                    Icon(Icons.image_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Share as image'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Share as PDF'),
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: match == null
          ? const Center(child: Text('Match not found'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                GlassCard(
                  strong: true,
                  glowColor: AppColors.accent,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '${match.team1}  vs  ${match.team2}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${match.ballType == BallType.tennis ? 'Tennis' : 'Leather'} ball  ·  ${match.overs} overs'
                        '${match.playersPerSide != 11 ? '  ·  ${match.playersPerSide} a side' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txLow),
                      ),
                      if (match.tossText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          match.tossText!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txLow),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          match.status == MatchStatus.completed
                              ? (match.resultText ?? 'Completed')
                              : 'In progress',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (match.status == MatchStatus.completed)
                        Builder(builder: (_) {
                          final potm = playerOfTheMatch(match);
                          if (potm == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const NeonIconBadge(
                                  icon: Icons.star_rounded,
                                  gradient: AppColors.trophy,
                                  size: 34,
                                  iconSize: 18,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('PLAYER OF THE MATCH',
                                          style: Theme.of(context).textTheme.labelSmall),
                                      Text(potm.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800, color: context.txHi)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final inn in match.innings) ...[
                  InningsScorecard(
                    innings: inn,
                    // Only locally-stored matches have career stats to show.
                    onTapPlayer: matchId == null
                        ? null
                        : (name) => context.push('/player/${Uri.encodeComponent(name)}'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}
