import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/enums/cricket_enums.dart';
import '../../shared/providers/repository_providers.dart';
import 'providers/tournament_providers.dart';

/// Lists tournaments and lets the user create a new one.
class TournamentScreen extends ConsumerWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(tournamentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournaments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/tournaments/create'),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: tournaments.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: tournaments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = tournaments[i];
                final fmt = t.format == TournamentFormat.roundRobin ? 'Round-robin' : 'Knockout';
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.emoji_events)),
                    title: Text(t.name),
                    subtitle: Text(
                      '$fmt • ${t.teams.length} teams • ${t.fixtures.length} matches\n'
                      '${DateFormat('d MMM yyyy').format(t.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          ref.read(tournamentRepositoryProvider).delete(t.id);
                          ref.invalidate(tournamentListProvider);
                        }
                      },
                    ),
                    onTap: () => context.go('/tournaments/${t.id}'),
                  ),
                );
              },
            ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete tournament?'),
        content: const Text('This removes the tournament and its fixtures (played matches stay in History).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return r ?? false;
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          const Text('No tournaments yet. Tap New to create one.'),
        ],
      ),
    );
  }
}
