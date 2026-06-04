import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';

/// Public feed of matches being scored live right now (across all devices).
/// Polls the backend every few seconds. Tap a match to follow it live.
class LiveMatchesScreen extends ConsumerStatefulWidget {
  const LiveMatchesScreen({super.key});

  @override
  ConsumerState<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends ConsumerState<LiveMatchesScreen> {
  List<Map<String, dynamic>> _matches = const [];
  bool _loading = true;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final list = await ref.read(liveApiProvider).list();
      if (!mounted) return;
      setState(() {
        _matches = list;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = _matches.isEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Matches'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _matches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed && _matches.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          const EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn’t reach the server',
            subtitle: 'Pull down to retry. The server may be waking up — give it a moment.',
            gradient: [Color(0xFF64748B), Color(0xFF475569)],
          ),
        ],
      );
    }
    if (_matches.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
            icon: Icons.podcasts_rounded,
            title: 'No live matches right now',
            subtitle: 'When someone scores a match with this app, it shows up here live.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _LiveCard(
        data: _matches[i],
        onTap: () => context.push('/live/${_matches[i]['id']}'),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runs = data['runs'] ?? 0;
    final wickets = data['wickets'] ?? 0;
    final oversText = data['oversText'] ?? '0.0';
    final overs = data['overs'] ?? 0;
    final battingTeam = (data['battingTeam'] ?? '') as String;
    final target = data['target'];

    return GlassCard(
      glowColor: AppColors.wicket,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.wicket, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('LIVE',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.wicket, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textLow),
            ],
          ),
          const SizedBox(height: 10),
          Text('${data['team1']}  vs  ${data['team2']}',
              style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(battingTeam,
                    style: theme.textTheme.bodyMedium?.copyWith(color: context.txMid),
                    overflow: TextOverflow.ellipsis),
              ),
              GradientText('$runs/$wickets',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('($oversText/$overs ov)',
                    style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
              ),
            ],
          ),
          if (target != null) ...[
            const SizedBox(height: 6),
            Text('Target $target',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
