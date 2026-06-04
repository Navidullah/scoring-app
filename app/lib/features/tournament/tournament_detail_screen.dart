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
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/tournaments'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          for (final round in rounds) ...[
            SectionHeader(
              isKnockout ? _roundName(round, rounds.length, tournament) : 'Fixtures',
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
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
        context.push(m.isComplete ? '/match/${m.id}/scorecard' : '/match/${m.id}/score');
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

    context.push('/match/${match.id}/score');
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
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GlassCard(
          strong: true,
          glowColor: AppColors.accent,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const NeonIconBadge(
                icon: Icons.emoji_events_rounded,
                gradient: AppColors.trophy,
                size: 72,
                iconSize: 38,
              ),
              const SizedBox(height: 14),
              Text('CHAMPION',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.accent, letterSpacing: 2)),
              const SizedBox(height: 6),
              Text(winners.first,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: allDecided
          ? GradientButton(
              label: 'Generate next round',
              icon: Icons.skip_next_rounded,
              onPressed: () {
                final next = generateNextKnockoutRound(round, winners);
                if (next.isEmpty) return;
                ref.read(tournamentRepositoryProvider).save(
                      t.copyWith(fixtures: [...t.fixtures, ...next]),
                    );
                ref.invalidate(tournamentProvider(t.id));
              },
            )
          : OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.hourglass_empty_rounded),
              label: const Text('Finish all matches to advance'),
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
    List<Color> gradient;
    Color statusColor;
    if (fixture.isBye) {
      final advancing = fixture.teamA == Fixture.byeMarker ? fixture.teamB : fixture.teamA;
      status = '$advancing advances (bye)';
      icon = Icons.fast_forward_rounded;
      gradient = const [Color(0xFF64748B), Color(0xFF475569)];
      statusColor = context.txLow;
    } else if (match == null) {
      status = 'Not played — tap to start';
      icon = Icons.play_circle_outline_rounded;
      gradient = AppColors.brand;
      statusColor = AppColors.primary;
    } else if (!match!.isComplete) {
      status = 'In progress — tap to resume';
      icon = Icons.play_circle_fill_rounded;
      gradient = AppColors.brand;
      statusColor = AppColors.primary;
    } else {
      final w = match!.winnerTeam;
      status = w == null ? 'Match tied' : '$w won';
      icon = Icons.emoji_events_rounded;
      gradient = AppColors.trophy;
      statusColor = AppColors.accent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: fixture.isBye ? null : onTap,
        child: Row(
          children: [
            NeonIconBadge(icon: icon, gradient: gradient, size: 42, iconSize: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fixture.isBye
                        ? (fixture.teamA == Fixture.byeMarker ? fixture.teamB : fixture.teamA)
                        : '${fixture.teamA}  vs  ${fixture.teamB}',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(status, style: theme.textTheme.bodySmall?.copyWith(color: statusColor)),
                ],
              ),
            ),
            if (!fixture.isBye)
              Icon(Icons.chevron_right_rounded, color: context.txLow),
          ],
        ),
      ),
    );
  }
}
