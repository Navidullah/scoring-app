import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/leaderboard_provider.dart';
import 'services/leaderboard.dart';

/// Global leaderboards across all saved matches, with a category picker and a
/// ball-type filter. Every row taps through to the player's profile.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _global = false;
  LeaderCategory _category = LeaderCategory.runs;
  BallType? _ballType; // null = all
  bool _globalWickets = false; // global only ranks runs / wickets

  /// Categories that rank batters use a batting glow; bowling categories a red.
  bool get _isBowling =>
      _category == LeaderCategory.wickets ||
      _category == LeaderCategory.bestBowling ||
      _category == LeaderCategory.economy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('My matches'), icon: Icon(Icons.phone_android_rounded)),
                  ButtonSegment(value: true, label: Text('Global'), icon: Icon(Icons.public_rounded)),
                ],
                selected: {_global},
                onSelectionChanged: (s) => setState(() => _global = s.first),
              ),
            ),
          ),
          Expanded(child: _global ? _buildGlobal() : _buildLocal()),
        ],
      ),
    );
  }

  Widget _buildLocal() {
    final entries = ref.watch(leaderboardProvider((category: _category, ballType: _ballType)));
    final gradient = _isBowling ? AppColors.wicketGrad : AppColors.brand;
    return Column(
      children: [
        _CategoryBar(
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        _BallTypeFilter(
          selected: _ballType,
          onSelected: (b) => setState(() => _ballType = b),
        ),
        Expanded(
          child: entries.isEmpty
              ? EmptyState(
                  icon: Icons.leaderboard_rounded,
                  title: 'Nothing here yet',
                  subtitle: 'No data for ${_category.label.toLowerCase()} yet.',
                  gradient: gradient,
                )
              : _list(entries, _category.unit, gradient),
        ),
      ],
    );
  }

  Widget _buildGlobal() {
    final async = ref.watch(globalLeaderboardProvider);
    final gradient = _globalWickets ? AppColors.wicketGrad : AppColors.brand;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              for (final option in [('Most Runs', false), ('Most Wickets', true)])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option.$1),
                    selected: _globalWickets == option.$2,
                    onSelected: (_) => setState(() => _globalWickets = option.$2),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn\'t load',
              subtitle: 'Check your connection and try again.',
              gradient: gradient,
            ),
            data: (d) {
              final entries = _globalWickets ? d.wickets : d.runs;
              if (entries.isEmpty) {
                return EmptyState(
                  icon: Icons.public_off_rounded,
                  title: 'No global data yet',
                  subtitle: 'Stats appear here once matches sync to the cloud.',
                  gradient: gradient,
                );
              }
              return _list(entries, _globalWickets ? 'wkts' : 'runs', gradient);
            },
          ),
        ),
      ],
    );
  }

  Widget _list(List<StatLeader> entries, String unit, List<Color> gradient) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + MediaQuery.paddingOf(context).bottom),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _LeaderRow(
        entry: entries[i],
        rank: i + 1,
        unit: unit,
        gradient: gradient,
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});
  final LeaderCategory selected;
  final ValueChanged<LeaderCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final c in LeaderCategory.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(c.label),
                selected: c == selected,
                onSelected: (_) => onSelected(c),
              ),
            ),
        ],
      ),
    );
  }
}

class _BallTypeFilter extends StatelessWidget {
  const _BallTypeFilter({required this.selected, required this.onSelected});
  final BallType? selected;
  final ValueChanged<BallType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final option in <(String, BallType?)>[
            ('All balls', null),
            ('Leather', BallType.leather),
            ('Tennis', BallType.tennis),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(option.$1),
                selected: selected == option.$2,
                onSelected: (_) => onSelected(option.$2),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.entry,
    required this.rank,
    required this.unit,
    required this.gradient,
  });

  final StatLeader entry;
  final int rank;
  final String unit;
  final List<Color> gradient;

  static const _medals = [
    AppColors.trophy,
    [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    [Color(0xFFE2A86B), Color(0xFFB87333)],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topThree = rank <= 3;
    final rankGradient = topThree ? _medals[rank - 1] : gradient;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      glowColor: topThree ? rankGradient.last : null,
      onTap: () => context.push('/player/${Uri.encodeComponent(entry.name)}'),
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
                    child: Text('$rank',
                        style: theme.textTheme.titleMedium?.copyWith(color: context.txMid)),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                Text(entry.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
              ],
            ),
          ),
          GradientText(
            entry.display,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            gradient: rankGradient,
          ),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(unit, style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
            ),
          ],
        ],
      ),
    );
  }
}
