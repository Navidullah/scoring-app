import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/cricket_match.dart';
import '../../domain/models/innings.dart';
import '../../shared/providers/repository_providers.dart';

/// Collects the two teams, overs, and who bats first, then creates the match
/// locally and navigates into live scoring.
class MatchSetupScreen extends ConsumerStatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  ConsumerState<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends ConsumerState<MatchSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _team1 = TextEditingController(text: 'Team A');
  final _team2 = TextEditingController(text: 'Team B');
  int _overs = AppConstants.defaultOvers;
  bool _team1BatsFirst = true;

  static const _overOptions = [5, 6, 8, 10, 15, 20, 50];

  @override
  void dispose() {
    _team1.dispose();
    _team2.dispose();
    super.dispose();
  }

  void _start() {
    if (!_formKey.currentState!.validate()) return;
    final t1 = _team1.text.trim();
    final t2 = _team2.text.trim();
    final battingFirst = _team1BatsFirst ? t1 : t2;
    final bowlingFirst = _team1BatsFirst ? t2 : t1;

    final match = CricketMatch(
      id: const Uuid().v4(),
      team1: t1,
      team2: t2,
      overs: _overs,
      battingFirst: battingFirst,
      createdAt: DateTime.now(),
      status: MatchStatus.inProgress,
      innings: [Innings(battingTeam: battingFirst, bowlingTeam: bowlingFirst)],
    );

    ref.read(matchRepositoryProvider).saveMatch(match);
    context.go('/match/${match.id}/score');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newMatch),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _team1,
              decoration: const InputDecoration(labelText: 'Team 1', border: OutlineInputBorder()),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _team2,
              decoration: const InputDecoration(labelText: 'Team 2', border: OutlineInputBorder()),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _overs,
              decoration: const InputDecoration(labelText: 'Overs', border: OutlineInputBorder()),
              items: _overOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text('$o overs')))
                  .toList(),
              onChanged: (v) => setState(() => _overs = v ?? _overs),
            ),
            const SizedBox(height: 24),
            Text('Batting first', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(_team1.text.trim().isEmpty ? 'Team 1' : _team1.text.trim())),
                ButtonSegment(value: false, label: Text(_team2.text.trim().isEmpty ? 'Team 2' : _team2.text.trim())),
              ],
              selected: {_team1BatsFirst},
              onSelectionChanged: (s) => setState(() => _team1BatsFirst = s.first),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start scoring'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
