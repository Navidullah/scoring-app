import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/tournament.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';
import 'providers/tournament_providers.dart';
import 'services/fixture_generator.dart';

/// Form to create a tournament: name, format, overs, and teams (with players).
class TournamentCreateScreen extends ConsumerStatefulWidget {
  const TournamentCreateScreen({super.key});

  @override
  ConsumerState<TournamentCreateScreen> createState() => _TournamentCreateScreenState();
}

class _TeamInput {
  _TeamInput(this.name, this.players);
  final TextEditingController name;
  final TextEditingController players; // comma-separated
}

class _TournamentCreateScreenState extends ConsumerState<TournamentCreateScreen> {
  final _name = TextEditingController(text: 'My Tournament');
  TournamentFormat _format = TournamentFormat.roundRobin;
  int _overs = AppConstants.defaultOvers;
  final _teams = <_TeamInput>[];

  static const _overOptions = [5, 6, 8, 10, 15, 20, 50];

  @override
  void initState() {
    super.initState();
    _teams.add(_TeamInput(TextEditingController(text: 'Team A'), TextEditingController()));
    _teams.add(_TeamInput(TextEditingController(text: 'Team B'), TextEditingController()));
  }

  @override
  void dispose() {
    _name.dispose();
    for (final t in _teams) {
      t.name.dispose();
      t.players.dispose();
    }
    super.dispose();
  }

  void _addTeam() {
    setState(() => _teams.add(_TeamInput(TextEditingController(), TextEditingController())));
  }

  void _removeTeam(int i) {
    setState(() {
      _teams[i].name.dispose();
      _teams[i].players.dispose();
      _teams.removeAt(i);
    });
  }

  void _create() {
    final names = _teams.map((t) => titleCase(t.name.text)).where((n) => n.isNotEmpty).toList();
    if (names.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 teams with names.')),
      );
      return;
    }
    if (names.toSet().length != names.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team names must be unique.')),
      );
      return;
    }

    final teams = _teams
        .where((t) => t.name.text.trim().isNotEmpty)
        .map((t) => TournamentTeam(
              name: titleCase(t.name.text),
              players: t.players.text
                  .split(',')
                  .where((p) => p.trim().isNotEmpty)
                  .map((p) => titleCase(p))
                  .toList(),
            ))
        .toList();

    final tournament = Tournament(
      id: const Uuid().v4(),
      name: _name.text.trim().isEmpty ? 'Tournament' : _name.text.trim(),
      format: _format,
      overs: _overs,
      teams: teams,
      fixtures: generateInitialFixtures(_format, teams.map((t) => t.name).toList()),
      createdAt: DateTime.now(),
    );

    ref.read(tournamentRepositoryProvider).save(tournament);
    ref.invalidate(tournamentListProvider);
    // Replace the create screen so Back from the detail returns to the list.
    context.pushReplacement('/tournaments/${tournament.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Tournament'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/tournaments'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + MediaQuery.paddingOf(context).bottom),
        children: [
          const SectionHeader('Details'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tournament name',
                    prefixIcon: Icon(Icons.emoji_events_rounded, color: AppColors.accent),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Format', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TournamentFormat>(
                    segments: const [
                      ButtonSegment(value: TournamentFormat.roundRobin, label: Text('Round-robin')),
                      ButtonSegment(value: TournamentFormat.knockout, label: Text('Knockout')),
                    ],
                    selected: {_format},
                    onSelectionChanged: (s) => setState(() => _format = s.first),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<int>(
                  initialValue: _overs,
                  decoration: const InputDecoration(
                    labelText: 'Overs per match',
                    prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
                  ),
                  items: _overOptions.map((o) => DropdownMenuItem(value: o, child: Text('$o overs'))).toList(),
                  onChanged: (v) => setState(() => _overs = v ?? _overs),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            'Teams',
            trailing: TextButton.icon(
              onPressed: _addTeam,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add team'),
            ),
          ),
          for (var i = 0; i < _teams.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _teams[i].name,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(labelText: 'Team ${i + 1} name'),
                          ),
                        ),
                        if (_teams.length > 2)
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: context.txLow),
                            onPressed: () => _removeTeam(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teams[i].players,
                      decoration: const InputDecoration(
                        labelText: 'Players (comma-separated, optional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Create Tournament',
            icon: Icons.check_rounded,
            onPressed: _create,
          ),
        ],
      ),
    );
  }
}
