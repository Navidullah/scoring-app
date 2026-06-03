import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/tournament.dart';
import '../../shared/providers/repository_providers.dart';
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
    final names = _teams.map((t) => t.name.text.trim()).where((n) => n.isNotEmpty).toList();
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
              name: t.name.text.trim(),
              players: t.players.text
                  .split(',')
                  .map((p) => p.trim())
                  .where((p) => p.isNotEmpty)
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
    context.go('/tournaments/${tournament.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Tournament'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tournaments'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Tournament name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Format', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<TournamentFormat>(
            segments: const [
              ButtonSegment(value: TournamentFormat.roundRobin, label: Text('Round-robin')),
              ButtonSegment(value: TournamentFormat.knockout, label: Text('Knockout')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _overs,
            decoration: const InputDecoration(labelText: 'Overs per match', border: OutlineInputBorder()),
            items: _overOptions.map((o) => DropdownMenuItem(value: o, child: Text('$o overs'))).toList(),
            onChanged: (v) => setState(() => _overs = v ?? _overs),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Teams', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(onPressed: _addTeam, icon: const Icon(Icons.add), label: const Text('Add team')),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _teams.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _teams[i].name,
                            decoration: InputDecoration(labelText: 'Team ${i + 1} name'),
                          ),
                        ),
                        if (_teams.length > 2)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _removeTeam(i),
                          ),
                      ],
                    ),
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
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.check),
            label: const Text('Create tournament'),
          ),
        ],
      ),
    );
  }
}
