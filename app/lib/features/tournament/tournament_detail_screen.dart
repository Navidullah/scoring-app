import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/cricket_match.dart';
import '../../domain/models/innings.dart';
import '../../domain/models/tournament.dart';
import '../../shared/providers/repository_providers.dart';
import 'providers/tournament_providers.dart';
import 'services/fixture_generator.dart';
import 'services/points_table.dart';
import 'widgets/points_table_view.dart';

/// Shows a tournament's fixtures (grouped by round) and, for round-robin, the
/// points table. Tapping a fixture starts/resumes/views its match.
class TournamentDetailScreen extends ConsumerWidget {
  const TournamentDetailScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentProvider(tournamentId));
    final matchRepo = ref.read(matchRepositoryProvider);
    CricketMatch? resolve(String id) => matchRepo.getMatch(id);

    if (tournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tournament')),
        body: const Center(child: Text('Tournament not found')),
      );
    }

    final isKnockout = tournament.format == TournamentFormat.knockout;
    final rounds = tournament.fixtures.map((f) => f.round).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tournaments'),
        ),
      ),
      body: ListView(
        children: [
          for (final round in rounds) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                isKnockout ? _roundName(round, rounds.length, tournament) : 'Fixtures',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...tournament.fixtures.where((f) => f.round == round).map(
                  (f) => _FixtureTile(
                    fixture: f,
                    match: f.matchId == null ? null : resolve(f.matchId!),
                    onTap: () => _openFixture(ref, context, tournament, f),
                  ),
                ),
          ],
          if (isKnockout) _knockoutFooter(ref, context, tournament, resolve),
          if (!isKnockout) PointsTableView(standings: computeStandings(tournament, resolve)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _roundName(int round, int totalRounds, Tournament t) {
    final inRound = t.fixtures.where((f) => f.round == round).length;
    if (inRound == 1) return 'Final';
    if (inRound == 2) return 'Semi-finals';
    return 'Round $round';
  }

  void _openFixture(WidgetRef ref, BuildContext context, Tournament t, Fixture f) {
    if (f.isBye) return;
    final matchRepo = ref.read(matchRepositoryProvider);

    // Already linked → resume or view.
    if (f.matchId != null) {
      final m = matchRepo.getMatch(f.matchId!);
      if (m != null) {
        context.go(m.isComplete ? '/match/${m.id}/scorecard' : '/match/${m.id}/score');
        return;
      }
    }

    // Create a fresh match for this fixture and link it.
    final match = CricketMatch(
      id: const Uuid().v4(),
      team1: f.teamA,
      team2: f.teamB,
      overs: t.overs,
      battingFirst: f.teamA,
      createdAt: DateTime.now(),
      status: MatchStatus.inProgress,
      innings: [Innings(battingTeam: f.teamA, bowlingTeam: f.teamB)],
    );
    matchRepo.saveMatch(match);

    final fixtures =
        t.fixtures.map((x) => x.id == f.id ? x.copyWith(matchId: match.id) : x).toList();
    ref.read(tournamentRepositoryProvider).save(t.copyWith(fixtures: fixtures));
    ref.invalidate(tournamentProvider(t.id));

    context.go('/match/${match.id}/score');
  }

  Widget _knockoutFooter(
    WidgetRef ref,
    BuildContext context,
    Tournament t,
    CricketMatch? Function(String) resolve,
  ) {
    final round = t.currentRound;
    final roundFixtures = t.fixtures.where((f) => f.round == round).toList();
    final winners = <String>[];
    var allDecided = true;
    for (final f in roundFixtures) {
      if (f.isBye) {
        winners.add(f.teamA == Fixture.byeMarker ? f.teamB : f.teamA);
        continue;
      }
      final w = f.matchId == null ? null : resolve(f.matchId!)?.winnerTeam;
      if (w == null) {
        allDecided = false;
        break;
      }
      winners.add(w);
    }

    if (allDecided && winners.length == 1) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: AppColors.scoreboard,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.accent, size: 40),
              const SizedBox(height: 8),
              Text('Champion: ${winners.first}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        onPressed: allDecided
            ? () {
                final next = generateNextKnockoutRound(round, winners);
                if (next.isEmpty) return;
                ref.read(tournamentRepositoryProvider).save(
                      t.copyWith(fixtures: [...t.fixtures, ...next]),
                    );
                ref.invalidate(tournamentProvider(t.id));
              }
            : null,
        icon: const Icon(Icons.skip_next),
        label: Text(allDecided ? 'Generate next round' : 'Finish all matches to advance'),
      ),
    );
  }
}

class _FixtureTile extends StatelessWidget {
  const _FixtureTile({required this.fixture, required this.match, required this.onTap});

  final Fixture fixture;
  final CricketMatch? match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String status;
    IconData icon;
    if (fixture.isBye) {
      final advancing = fixture.teamA == Fixture.byeMarker ? fixture.teamB : fixture.teamA;
      status = '$advancing advances (bye)';
      icon = Icons.fast_forward;
    } else if (match == null) {
      status = 'Not played — tap to start';
      icon = Icons.play_circle_outline;
    } else if (!match!.isComplete) {
      status = 'In progress — tap to resume';
      icon = Icons.play_circle_fill;
    } else {
      final w = match!.winnerTeam;
      status = w == null ? 'Match tied' : '$w won';
      icon = Icons.emoji_events;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          fixture.isBye
              ? (fixture.teamA == Fixture.byeMarker ? fixture.teamB : fixture.teamA)
              : '${fixture.teamA}  vs  ${fixture.teamB}',
        ),
        subtitle: Text(status, style: theme.textTheme.bodySmall),
        trailing: fixture.isBye ? null : const Icon(Icons.chevron_right),
        onTap: fixture.isBye ? null : onTap,
      ),
    );
  }
}
