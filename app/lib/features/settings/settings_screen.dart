import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/sync_controller.dart';

/// Settings + cloud sync controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final deviceId = ref.watch(deviceIdProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    final lastSynced = sync.lastSyncedAt == null
        ? 'Never'
        : DateFormat('d MMM yyyy, h:mm a').format(sync.lastSyncedAt!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const SectionHeader('Appearance'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              secondary: const NeonIconBadge(
                icon: Icons.dark_mode_rounded,
                gradient: AppColors.sixGrad,
                size: 42,
                iconSize: 20,
              ),
              title: const Text('Dark mode'),
              subtitle: Text(isDark ? 'On' : 'Off',
                  style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
              value: isDark,
              onChanged: (v) => ref.read(themeModeProvider.notifier).setDark(v),
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('Cloud sync'),
          GlassCard(
            child: Column(
              children: [
                Row(
                  children: [
                    NeonIconBadge(
                      icon: sync.online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      gradient: sync.online ? AppColors.brand : const [Color(0xFF64748B), Color(0xFF475569)],
                      size: 44,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sync.online ? 'Online' : 'Offline', style: theme.textTheme.titleMedium),
                          Text('Last synced: $lastSynced',
                              style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sync.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      sync.message!,
                      style: TextStyle(
                        color: sync.status == SyncStatus.error ? AppColors.wicket : AppColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                GradientButton(
                  label: sync.isSyncing ? 'Syncing…' : 'Sync now',
                  icon: sync.isSyncing ? null : Icons.cloud_upload_rounded,
                  onPressed: sync.isSyncing ? null : controller.syncNow,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: sync.isSyncing ? null : controller.restoreFromCloud,
                  icon: const Icon(Icons.cloud_download_rounded),
                  label: const Text('Restore from cloud'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('About'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.devices_rounded),
                  title: const Text('Device ID'),
                  subtitle: Text(deviceId, style: theme.textTheme.bodySmall),
                ),
                const Divider(height: 1),
                const AboutListTile(
                  icon: Icon(Icons.info_outline_rounded),
                  applicationName: 'CricLive',
                  applicationVersion: '1.0.0',
                  child: Text('About this app'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
