import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/leaderboard_provider.dart';
import 'services/leaderboard.dart';

/// Global leaderboards: most runs and most wickets across all matches.
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(topRunScorersProvider);
    final wickets = ref.watch(topWicketTakersProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboards'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Most Runs', icon: Icon(Icons.sports_cricket_rounded)),
              Tab(text: 'Most Wickets', icon: Icon(Icons.gps_fixed_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaderList(
              entries: runs,
              unit: 'runs',
              gradient: AppColors.brand,
              empty: 'No batting data yet.',
            ),
            _LeaderList(
              entries: wickets,
              unit: 'wkts',
              gradient: AppColors.wicketGrad,
              empty: 'No bowling data yet.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderList extends StatelessWidget {
  const _LeaderList({
    required this.entries,
    required this.unit,
    required this.gradient,
    required this.empty,
  });

  final List<LeaderboardEntry> entries;
  final String unit;
  final List<Color> gradient;
  final String empty;

  static const _medals = [AppColors.trophy, [Color(0xFFCBD5E1), Color(0xFF94A3B8)], [Color(0xFFE2A86B), Color(0xFFB87333)]];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty || entries.every((e) => e.value == 0)) {
      return EmptyState(
        icon: Icons.leaderboard_rounded,
        title: 'Nothing here yet',
        subtitle: empty,
        gradient: gradient,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = entries[i];
        final rank = i + 1;
        final topThree = rank <= 3;
        final rankGradient = topThree ? _medals[rank - 1] : gradient;
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          glowColor: topThree ? rankGradient.last : null,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: topThree
                    ? NeonIconBadge(
                        icon: Icons.emoji_events_rounded,
                        gradient: rankGradient,
                        size: 40,
                        iconSize: 20,
                      )
                    : Center(
                        child: Text(
                          '$rank',
                          style: theme.textTheme.titleMedium?.copyWith(color: context.txMid),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    Text(
                      '${e.matches} match${e.matches == 1 ? '' : 'es'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: context.txLow),
                    ),
                  ],
                ),
              ),
              GradientText(
                '${e.value}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                gradient: rankGradient,
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(unit, style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
              ),
            ],
          ),
        );
      },
    );
  }
}
