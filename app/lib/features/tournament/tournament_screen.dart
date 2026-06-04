import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
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
        onPressed: () => context.push('/tournaments/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: tournaments.isEmpty
          ? const EmptyState(
              icon: Icons.emoji_events_rounded,
              title: 'No tournaments yet',
              subtitle: 'Tap “New” to create a league or knockout.',
              gradient: AppColors.trophy,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: tournaments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final t = tournaments[i];
                final fmt = t.format == TournamentFormat.roundRobin ? 'Round-robin' : 'Knockout';
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push('/tournaments/${t.id}'),
                  child: Row(
                    children: [
                      const NeonIconBadge(
                        icon: Icons.emoji_events_rounded,
                        gradient: AppColors.trophy,
                        size: 48,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '$fmt · ${t.teams.length} teams · ${t.fixtures.length} matches',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txMid),
                            ),
                            Text(
                              DateFormat('d MMM yyyy').format(t.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txLow),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: context.txLow),
                        onPressed: () async {
                          final ok = await _confirmDelete(context);
                          if (ok) {
                            ref.read(tournamentRepositoryProvider).delete(t.id);
                            ref.invalidate(tournamentListProvider);
                          }
                        },
                      ),
                    ],
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.wicket, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return r ?? false;
  }
}
