import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums/cricket_enums.dart';
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
      ),
      body: match.isComplete
          ? _ResultView(matchId: match.id, resultText: match.resultText ?? 'Match complete')
          : Column(
              children: [
                ScoreboardHeader(match: match),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        BattingBowlingPanel(innings: match.currentInnings),
                        OverTimeline(balls: match.currentInnings.currentOverBalls),
                      ],
                    ),
                  ),
                ),
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
    final result = await showWicketDialog(context);
    if (result != null) {
      _controller.scoreWicket(result.type, newBatsman: result.batsman, fielder: result.fielder);
    }
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.matchId, required this.resultText});
  final String matchId;
  final String resultText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 80, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              resultText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/match/$matchId/scorecard'),
            icon: const Icon(Icons.assignment),
            label: const Text('View scorecard'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.go('/match/setup'),
            icon: const Icon(Icons.add),
            label: const Text('New match'),
          ),
          TextButton(onPressed: () => context.go('/'), child: const Text('Home')),
        ],
      ),
    );
  }
}
