import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/cricket_match.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/history_provider.dart';

/// Lists saved matches. Tap a completed match to view its scorecard, or an
/// in-progress match to resume scoring. Swipe to delete.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: matches.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: 'No matches yet',
              subtitle: 'Start a new match and it will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _MatchTile(
                match: matches[i],
                onDelete: () {
                  ref.read(matchRepositoryProvider).deleteMatch(matches[i].id);
                  ref.invalidate(matchHistoryProvider);
                },
              ),
            ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.onDelete});

  final CricketMatch match;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = match.status == MatchStatus.completed;
    final date = DateFormat('d MMM yyyy, h:mm a').format(match.createdAt);
    final statusColor = completed ? AppColors.accent : AppColors.primary;
    final statusText =
        completed ? (match.resultText ?? 'Completed') : 'In progress — tap to resume';

    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.wicket.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.wicket.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.wicket),
      ),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => completed
            ? context.push('/match/${match.id}/scorecard')
            : context.push('/match/${match.id}/score'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NeonIconBadge(
                  icon: completed ? Icons.emoji_events_rounded : Icons.play_arrow_rounded,
                  gradient: completed ? AppColors.trophy : AppColors.brand,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '${match.team1}  vs  ${match.team2}',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.txLow),
              ],
            ),
            const SizedBox(height: 12),
            for (final inn in match.innings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        inn.battingTeam,
                        style: theme.textTheme.bodyMedium?.copyWith(color: context.txMid),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${inn.runs}/${inn.wickets}  (${inn.oversText})',
                      style: TextStyle(
                        color: context.txHi,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.28)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(date, style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete match?'),
        content: const Text('This permanently removes the match and its scorecard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.wicket, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
