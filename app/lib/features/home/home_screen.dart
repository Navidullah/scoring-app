import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

/// Landing screen — entry points into the four V1 features.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: const [
            _HomeTile(
              label: AppStrings.newMatch,
              icon: Icons.sports_cricket,
              route: AppRoutes.matchSetup,
            ),
            _HomeTile(
              label: AppStrings.tournaments,
              icon: Icons.emoji_events,
              route: AppRoutes.tournaments,
            ),
            _HomeTile(
              label: AppStrings.history,
              icon: Icons.history,
              route: AppRoutes.history,
            ),
            _HomeTile(
              label: AppStrings.leaderboards,
              icon: Icons.leaderboard,
              route: AppRoutes.leaderboards,
            ),
            _HomeTile(
              label: AppStrings.settings,
              icon: Icons.settings,
              route: AppRoutes.settings,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
