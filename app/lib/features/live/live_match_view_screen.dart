import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/cricket_match.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ui_widgets.dart';
import '../history/widgets/innings_scorecard.dart';
import '../match/live_scoring_screen.dart' show shareLiveMatchLink;
import '../match/widgets/scoreboard_header.dart';

/// Read-only live view of a single match, fetched from the cloud and polled
/// every few seconds. Reuses the app's scoreboard + scorecard widgets.
class LiveMatchViewScreen extends ConsumerStatefulWidget {
  const LiveMatchViewScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LiveMatchViewScreen> createState() => _LiveMatchViewScreenState();
}

class _LiveMatchViewScreenState extends ConsumerState<LiveMatchViewScreen> {
  CricketMatch? _match;
  bool _loading = true;
  bool _notFound = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final json = await ref.read(liveApiProvider).getMatch(widget.matchId);
      if (!mounted) return;
      if (json == null) {
        setState(() {
          _loading = false;
          _notFound = _match == null;
        });
        return;
      }
      setState(() {
        _match = CricketMatch.fromJson(json);
        _loading = false;
        _notFound = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    return Scaffold(
      appBar: AppBar(
        title: Text(match == null ? 'Live Match' : '${match.team1} vs ${match.team2}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/live'),
        ),
        actions: [
          IconButton(
            tooltip: 'Share link',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => shareLiveMatchLink(widget.matchId),
          ),
        ],
      ),
      body: _buildBody(match),
    );
  }

  Widget _buildBody(CricketMatch? match) {
    if (_loading && match == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notFound && match == null) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Match not available',
        subtitle: 'It may not have been shared live, or the link is wrong.',
        gradient: [Color(0xFF64748B), Color(0xFF475569)],
      );
    }
    if (match == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (match.isComplete)
          _ResultBanner(match: match)
        else
          ScoreboardHeader(match: match),
        const SizedBox(height: 12),
        for (final inn in match.innings) ...[
          InningsScorecard(innings: inn),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.match});
  final CricketMatch match;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      strong: true,
      glowColor: AppColors.accent,
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text('${match.team1}  vs  ${match.team2}',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              match.resultText ?? 'Completed',
              style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
