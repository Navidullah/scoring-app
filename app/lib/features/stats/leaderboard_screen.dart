import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
              Tab(text: 'Most Runs', icon: Icon(Icons.sports_cricket)),
              Tab(text: 'Most Wickets', icon: Icon(Icons.gps_fixed)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaderList(entries: runs, unit: 'runs', empty: 'No batting data yet.'),
            _LeaderList(entries: wickets, unit: 'wkts', empty: 'No bowling data yet.'),
          ],
        ),
      ),
    );
  }
}

class _LeaderList extends StatelessWidget {
  const _LeaderList({required this.entries, required this.unit, required this.empty});

  final List<LeaderboardEntry> entries;
  final String unit;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty || entries.every((e) => e.value == 0)) {
      return Center(child: Text(empty));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final e = entries[i];
        final rank = i + 1;
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: rank <= 3 ? AppColors.accent : null,
              child: Text('$rank'),
            ),
            title: Text(e.name),
            subtitle: Text('${e.matches} match${e.matches == 1 ? '' : 'es'}'),
            trailing: Text(
              '${e.value} $unit',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
