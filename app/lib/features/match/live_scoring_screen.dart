import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/live_scoring_controller.dart';
import 'widgets/batting_bowling_panel.dart';
import 'widgets/over_timeline.dart';
import 'widgets/scoreboard_header.dart';
import 'widgets/scoring_dialogs.dart';
import 'widgets/scoring_pad.dart';

/// Live ball-by-ball scoring screen for a single match.
class LiveScoringScreen extends ConsumerStatefulWidget {
  const LiveScoringScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends ConsumerState<LiveScoringScreen> {
  bool _prompting = false;

  LiveScoringController get _controller =>
      ref.read(liveScoringControllerProvider(widget.matchId).notifier);

  @override
  Widget build(BuildContext context) {
    final provider = liveScoringControllerProvider(widget.matchId);
    final match = ref.watch(provider);

    // After each build, prompt for any required input (openers / next bowler).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());

    return Scaffold(
      appBar: AppBar(
        title: Text('${match.team1} vs ${match.team2}'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (!match.isComplete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'retire') _onRetire();
                if (v == 'share') shareLiveMatchLink(widget.matchId);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.podcasts_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Share live link'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'retire',
                  child: Row(
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Retire batsman'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: match.isComplete
          ? _ResultView(matchId: match.id, resultText: match.resultText ?? 'Match complete')
          : Column(
              children: [
                ScoreboardHeader(match: match),
                Expanded(
                  child: SingleChildScrollView(
                    child: BattingBowlingPanel(innings: match.currentInnings),
                  ),
                ),
                // Pinned above the pad so the current over is always fully visible.
                OverTimeline(balls: match.currentInnings.currentOverBalls),
                if (match.currentInnings.isFreeHit) const _FreeHitBanner(),
                ScoringPad(
                  enabled: _controller.canScore,
                  onRuns: _controller.scoreRuns,
                  onExtra: _onExtra,
                  onWicket: _onWicket,
                  onUndo: _controller.undo,
                ),
              ],
            ),
    );
  }

  Future<void> _maybePrompt() async {
    if (_prompting || !mounted) return;
    final controller = _controller;
    final match = ref.read(liveScoringControllerProvider(widget.matchId));
    if (match.isComplete) return;

    if (controller.needsOpeners) {
      _prompting = true;
      final names = await showOpenersDialog(context, teamName: match.currentInnings.battingTeam);
      if (names != null) controller.setOpeners(striker: names[0], nonStriker: names[1]);
      _prompting = false;
    } else if (controller.needsBowler) {
      _prompting = true;
      final name = await showBowlerDialog(
        context,
        previousBowlers: controller.priorBowlers,
        disabledBowler: controller.lastOverBowler,
      );
      if (name != null) controller.setBowler(name);
      _prompting = false;
    }
  }

  Future<void> _onExtra(ExtraType type) async {
    if (type == ExtraType.bye || type == ExtraType.legBye) {
      final runs = await showRunCountDialog(context, title: type == ExtraType.bye ? 'Byes' : 'Leg byes');
      if (runs != null) _controller.scoreExtra(type, runs: runs);
    } else {
      _controller.scoreExtra(type, runs: 1);
    }
  }

  Future<void> _onWicket() async {
    final match = ref.read(liveScoringControllerProvider(widget.matchId));
    final inn = match.currentInnings;
    final result = await showWicketDialog(
      context,
      striker: inn.striker ?? 'Striker',
      nonStriker: inn.nonStriker ?? 'Non-striker',
      lbwAllowed: match.lbwAllowed,
      runOutOnly: inn.isFreeHit,
    );
    if (result != null) {
      _controller.scoreWicket(
        result.type,
        newBatsman: result.batsman,
        fielder: result.fielder,
        nonStrikerOut: result.nonStrikerOut,
      );
    }
  }

  Future<void> _onRetire() async {
    final inn = ref.read(liveScoringControllerProvider(widget.matchId)).currentInnings;
    if (inn.striker == null || inn.nonStriker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both batsmen must be in before retiring.')),
      );
      return;
    }
    final r = await showRetireDialog(context, striker: inn.striker!, nonStriker: inn.nonStriker!);
    if (r != null) {
      _controller.retire(nonStriker: r.nonStriker, replacement: r.replacement);
    }
  }
}

/// Shares the public live-scoreboard link for [matchId] (opens in any browser).
Future<void> shareLiveMatchLink(String matchId) {
  return SharePlus.instance.share(
    ShareParams(text: 'Follow my cricket match live:\n${Env.liveMatchUrl(matchId)}'),
  );
}

/// Thin amber strip shown when the next delivery is a free hit.
class _FreeHitBanner extends StatelessWidget {
  const _FreeHitBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.amber),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: -4,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            'FREE HIT  •  batter can only be run out',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.matchId, required this.resultText});
  final String matchId;
  final String resultText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          strong: true,
          glowColor: AppColors.accent,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NeonIconBadge(
                icon: Icons.emoji_events_rounded,
                gradient: AppColors.trophy,
                size: 88,
                iconSize: 46,
              ),
              const SizedBox(height: 20),
              Text(
                'Match Complete',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                resultText,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'View Scorecard',
                icon: Icons.assignment_rounded,
                onPressed: () => context.push('/match/$matchId/scorecard'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => shareLiveMatchLink(matchId),
                icon: const Icon(Icons.podcasts_rounded),
                label: const Text('Share match link'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.pushReplacement('/match/setup'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New match'),
              ),
              const SizedBox(height: 4),
              TextButton(onPressed: () => context.go('/'), child: const Text('Back to Home')),
            ],
          ),
        ),
      ),
    );
  }
}
