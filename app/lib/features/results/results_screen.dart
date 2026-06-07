import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';

/// Public feed of recently finished matches (across all devices). Results drop
/// off the list 24h after they end. Tap a match to view its full scorecard.
class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  List<Map<String, dynamic>> _matches = const [];
  bool _loading = true;
  bool _failed = false;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_inFlight) return; // don't stack requests while the server wakes up
    _inFlight = true;
    setState(() => _loading = true);
    try {
      final list = await ref.read(liveApiProvider).results();
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
    } finally {
      _inFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text('Loading results…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.txMid)),
            const SizedBox(height: 4),
            Text('The server may take a few seconds to wake up.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txLow)),
          ],
        ),
      );
    }
    if (_failed && _matches.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          EmptyState(
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
            icon: Icons.emoji_events_rounded,
            title: 'No results yet',
            subtitle: 'Finished matches show up here for 24 hours. Score a match to the end and it’ll appear.',
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ResultCard(
        data: _matches[i],
        onTap: () => context.push('/results/${_matches[i]['id']}'),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.data, required this.onTap});
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
    final resultText = data['resultText'] as String?;

    return GlassCard(
      glowColor: AppColors.accent,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('RESULT',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
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
          if (resultText != null) ...[
            const SizedBox(height: 8),
            Text(resultText,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}
