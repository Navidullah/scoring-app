import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/cricket_match.dart';
import '../../shared/providers/repository_providers.dart';
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
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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
    final completed = match.status == MatchStatus.completed;
    final date = DateFormat('d MMM yyyy, h:mm a').format(match.createdAt);
    final summary = match.innings
        .map((i) => '${i.battingTeam} ${i.runs}/${i.wickets} (${i.oversText})')
        .join('  •  ');

    return Dismissible(
      key: ValueKey(match.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete),
      ),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(completed ? Icons.emoji_events : Icons.play_arrow),
          ),
          title: Text('${match.team1} vs ${match.team2}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary),
              const SizedBox(height: 2),
              Text(
                completed ? (match.resultText ?? 'Completed') : 'In progress — tap to resume',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => completed
              ? context.go('/match/${match.id}/scorecard')
              : context.go('/match/${match.id}/score'),
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return result ?? false;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text('No matches yet. Start a new match!'),
        ],
      ),
    );
  }
}
