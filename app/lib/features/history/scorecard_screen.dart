import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../shared/providers/repository_providers.dart';
import 'services/player_of_match.dart';
import 'services/scorecard_pdf.dart';
import 'widgets/innings_scorecard.dart';

/// Full scorecard for a match: result banner + a card per innings.
class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchRepositoryProvider).getMatch(matchId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/history'),
        ),
        actions: [
          if (match != null)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share / download',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await shareScorecardPdf(match);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Could not share scorecard: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: match == null
          ? const Center(child: Text('Match not found'))
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Container(
                  width: double.infinity,
                  color: AppColors.scoreboard,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${match.team1} vs ${match.team2}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match.status == MatchStatus.completed
                            ? (match.resultText ?? 'Completed')
                            : 'In progress',
                        style: const TextStyle(color: AppColors.accent, fontSize: 14),
                      ),
                      if (match.status == MatchStatus.completed)
                        Builder(builder: (_) {
                          final potm = playerOfTheMatch(match);
                          if (potm == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: AppColors.accent, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Player of the Match: ${potm.name}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                for (final inn in match.innings)
                  InningsScorecard(innings: inn),
              ],
            ),
    );
  }
}
