import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';

/// Landing screen — a hero "New Match" call-to-action plus quick entry points
/// into the rest of the app.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const _HomeHeader(),
            const SizedBox(height: 22),
            const _HeroMatchCard(),
            const SizedBox(height: 14),
            const _LiveBanner(),
            const SizedBox(height: 26),
            const SectionHeader('Explore'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.02,
              children: const [
                _FeatureTile(
                  label: AppStrings.tournaments,
                  subtitle: 'Leagues & knockouts',
                  icon: Icons.emoji_events_rounded,
                  gradient: AppColors.trophy,
                  route: AppRoutes.tournaments,
                ),
                _FeatureTile(
                  label: AppStrings.history,
                  subtitle: 'Past scorecards',
                  icon: Icons.history_rounded,
                  gradient: AppColors.brand,
                  route: AppRoutes.history,
                ),
                _FeatureTile(
                  label: AppStrings.leaderboards,
                  subtitle: 'Top run & wicket takers',
                  icon: Icons.leaderboard_rounded,
                  gradient: AppColors.sixGrad,
                  route: AppRoutes.leaderboards,
                ),
                _FeatureTile(
                  label: AppStrings.settings,
                  subtitle: 'Theme & cloud sync',
                  icon: Icons.settings_rounded,
                  gradient: AppColors.fourGrad,
                  route: AppRoutes.settings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const NeonIconBadge(icon: Icons.sports_cricket_rounded, size: 48, iconSize: 26),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: theme.textTheme.bodySmall?.copyWith(color: context.txLow),
              ),
              GradientText(
                AppStrings.appName,
                style: theme.textTheme.headlineSmall ?? const TextStyle(),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_rounded),
          color: context.txMid,
        ),
      ],
    );
  }
}

class _HeroMatchCard extends StatelessWidget {
  const _HeroMatchCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      strong: true,
      glowColor: AppColors.primary,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NeonIconBadge(
                icon: Icons.sports_cricket_rounded,
                size: 58,
                iconSize: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start a New Match',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Ball-by-ball live scoring with full stats',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: context.txLow),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'New Match',
            icon: Icons.play_arrow_rounded,
            onPressed: () => context.push(AppRoutes.matchSetup),
          ),
        ],
      ),
    );
  }
}

class _LiveBanner extends StatelessWidget {
  const _LiveBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      glowColor: AppColors.wicket,
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(AppRoutes.live),
      child: Row(
        children: [
          const NeonIconBadge(
            icon: Icons.podcasts_rounded,
            gradient: AppColors.wicketGrad,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: AppColors.wicket, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('LIVE',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.wicket, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Live Matches', style: theme.textTheme.titleMedium),
                Text('Watch matches happening now',
                    style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textLow),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NeonIconBadge(icon: icon, gradient: gradient),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: context.txLow),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
