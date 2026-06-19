import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/leaderboard_provider.dart';
import 'services/player_stats.dart';
import 'services/share_player_image.dart';

/// Career profile for a single player: batting, bowling, and recent form,
/// aggregated from every saved match. Reached by tapping a player anywhere.
class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final career = ref.watch(playerCareerProvider(name));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Player'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/leaderboards'),
        ),
        actions: [
          if (career.matches > 0)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Share stats',
              onPressed: () => sharePlayerImage(context, career),
            ),
        ],
      ),
      body: career.matches == 0
          ? EmptyState(
              icon: Icons.person_off_rounded,
              title: 'No stats yet',
              subtitle: '$name hasn\'t appeared in any match.',
              gradient: AppColors.brand,
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + MediaQuery.paddingOf(context).bottom),
              children: [
                _Header(career: career),
                const SizedBox(height: 18),
                const SectionHeader('Batting'),
                GlassCard(
                  glowColor: AppColors.primary,
                  child: _StatWrap(stats: _battingStats(career.batting, career.matches)),
                ),
                const SizedBox(height: 18),
                const SectionHeader('Bowling'),
                GlassCard(
                  glowColor: AppColors.wicket,
                  child: _StatWrap(stats: _bowlingStats(career.bowling)),
                ),
                if (career.recent.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const SectionHeader('Recent form'),
                  for (final p in career.recent.take(8))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onTap: () => context.push('/match/${p.matchId}/scorecard'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(p.title,
                                  style: theme.textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            _FormPill(label: 'BAT', value: p.battingText, dim: !p.batted),
                            const SizedBox(width: 8),
                            _FormPill(label: 'BOWL', value: p.bowlingText, dim: !p.bowled),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  List<({String label, String value})> _battingStats(BattingCareer b, int matches) => [
        (label: 'Matches', value: '$matches'),
        (label: 'Innings', value: '${b.innings}'),
        (label: 'Runs', value: '${b.runs}'),
        (label: 'High score', value: b.highScoreText),
        (label: 'Average', value: b.dismissals == 0 && b.runs == 0 ? '-' : b.average.toStringAsFixed(1)),
        (label: 'Strike rate', value: b.balls == 0 ? '-' : b.strikeRate.toStringAsFixed(1)),
        (label: '50s', value: '${b.fifties}'),
        (label: '100s', value: '${b.hundreds}'),
        (label: 'Fours', value: '${b.fours}'),
        (label: 'Sixes', value: '${b.sixes}'),
        (label: 'Not outs', value: '${b.notOuts}'),
        (label: 'Ducks', value: '${b.ducks}'),
      ];

  List<({String label, String value})> _bowlingStats(BowlingCareer b) => [
        (label: 'Innings', value: '${b.innings}'),
        (label: 'Overs', value: b.balls == 0 ? '-' : b.oversText),
        (label: 'Wickets', value: '${b.wickets}'),
        (label: 'Best', value: b.bestText),
        (label: 'Average', value: b.wickets == 0 ? '-' : b.average.toStringAsFixed(1)),
        (label: 'Economy', value: b.balls == 0 ? '-' : b.economy.toStringAsFixed(1)),
        (label: 'Maidens', value: '${b.maidens}'),
        (label: '3+ wkts', value: '${b.threeWicketHauls}'),
        (label: '5+ wkts', value: '${b.fiveWicketHauls}'),
      ];
}

class _Header extends StatelessWidget {
  const _Header({required this.career});
  final PlayerCareer career;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = career.name.isEmpty
        ? '?'
        : career.name.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();
    return GlassCard(
      strong: true,
      glowColor: AppColors.accent,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.brand),
              shape: BoxShape.circle,
            ),
            child: Text(initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(career.name, style: theme.textTheme.headlineSmall, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${career.matches} match${career.matches == 1 ? '' : 'es'}  ·  '
                  '${career.batting.runs} runs  ·  ${career.bowling.wickets} wkts',
                  style: theme.textTheme.bodySmall?.copyWith(color: context.txLow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A responsive grid of label/value stat cells.
class _StatWrap extends StatelessWidget {
  const _StatWrap({required this.stats});
  final List<({String label, String value})> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, c) {
      const perRow = 3;
      final cellWidth = (c.maxWidth - (perRow - 1) * 12) / perRow;
      return Wrap(
        spacing: 12,
        runSpacing: 16,
        children: [
          for (final s in stats)
            SizedBox(
              width: cellWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.value,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text(s.label,
                      style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _FormPill extends StatelessWidget {
  const _FormPill({required this.label, required this.value, this.dim = false});
  final String label;
  final String value;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.hairline),
      ),
      child: Column(
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: context.txLow, fontSize: 9)),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: dim ? context.txLow : context.txHi,
            ),
          ),
        ],
      ),
    );
  }
}
