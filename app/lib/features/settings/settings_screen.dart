import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../shared/providers/app_providers.dart';
import '../../shared/providers/theme_provider.dart';
import 'providers/sync_controller.dart';

/// Settings + cloud sync controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final deviceId = ref.watch(deviceIdProvider);

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
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark mode'),
            value: ref.watch(themeModeProvider) == ThemeMode.dark,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setDark(v),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Cloud sync', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(sync.online ? Icons.cloud_done : Icons.cloud_off,
                color: sync.online ? Colors.green : Colors.grey),
            title: Text(sync.online ? 'Online' : 'Offline'),
            subtitle: Text('Last synced: $lastSynced'),
          ),
          if (sync.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                sync.message!,
                style: TextStyle(
                  color: sync.status == SyncStatus.error
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: sync.isSyncing ? null : controller.syncNow,
                  icon: sync.isSyncing
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: Text(sync.isSyncing ? 'Syncing…' : 'Sync now'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: sync.isSyncing ? null : controller.restoreFromCloud,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Restore from cloud'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Device ID'),
            subtitle: Text(deviceId),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Cricket Scoring',
            applicationVersion: '1.0.0',
            child: Text('About'),
          ),
        ],
      ),
    );
  }
}
