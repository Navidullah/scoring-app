import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/enums/cricket_enums.dart';
import '../../domain/models/cricket_match.dart';
import '../../domain/models/innings.dart';
import '../../shared/providers/repository_providers.dart';
import '../../shared/widgets/autocomplete_field.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';

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
  final _overs = TextEditingController(text: '${AppConstants.defaultOvers}');
  int _playersPerSide = 11;
  bool _tossWonByTeam1 = true;
  TossDecision _tossDecision = TossDecision.bat;
  BallType _ballType = BallType.leather;
  bool _lbwAllowed = true;

  static const _overPresets = [5, 6, 8, 10, 15, 20, 50];
  static const _sideSizeOptions = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  static const _maxOvers = 100;

  @override
  void dispose() {
    _team1.dispose();
    _team2.dispose();
    _overs.dispose();
    super.dispose();
  }

  void _start() {
    final t1 = titleCase(_team1.text);
    final t2 = titleCase(_team2.text);
    if (t1.isEmpty || t2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both team names.')),
      );
      return;
    }
    final overs = int.tryParse(_overs.text.trim());
    if (overs == null || overs < 1 || overs > _maxOvers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid number of overs (1–$_maxOvers).')),
      );
      return;
    }
    final tossWinner = _tossWonByTeam1 ? t1 : t2;
    final tossLoser = _tossWonByTeam1 ? t2 : t1;
    // Toss winner bats first only if they chose to bat; otherwise they bowl.
    final battingFirst = _tossDecision == TossDecision.bat ? tossWinner : tossLoser;
    final bowlingFirst = battingFirst == t1 ? t2 : t1;

    // Remember the team names so they autocomplete next time.
    final store = ref.read(playerStoreProvider);
    store.recordSquad(t1, const []);
    store.recordSquad(t2, const []);

    final match = CricketMatch(
      id: const Uuid().v4(),
      team1: t1,
      team2: t2,
      overs: overs,
      battingFirst: battingFirst,
      createdAt: DateTime.now(),
      status: MatchStatus.inProgress,
      ballType: _ballType,
      lbwAllowed: _lbwAllowed,
      tossWinner: tossWinner,
      tossDecision: _tossDecision,
      playersPerSide: _playersPerSide,
      innings: [Innings(battingTeam: battingFirst, bowlingTeam: bowlingFirst)],
    );

    ref.read(matchRepositoryProvider).saveMatch(match);
    // Replace setup so Back from live scoring returns to the previous screen.
    context.pushReplacement('/match/${match.id}/score');
  }

  @override
  Widget build(BuildContext context) {
    final teamNames = ref.watch(playerStoreProvider).teamNames;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newMatch),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Extra bottom inset so the Start button clears the system nav bar.
          padding: EdgeInsets.fromLTRB(16, 8, 16, 28 + MediaQuery.paddingOf(context).bottom),
          children: [
            const SectionHeader('Teams'),
            GlassCard(
              child: Column(
                children: [
                  AutocompleteField(
                    controller: _team1,
                    label: 'Team 1',
                    suggestions: teamNames,
                    prefixIcon: const Icon(Icons.shield_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('VS',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AutocompleteField(
                    controller: _team2,
                    label: 'Team 2',
                    suggestions: teamNames,
                    prefixIcon: const Icon(Icons.shield_rounded, color: AppColors.cyan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionHeader('Match settings'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _overs,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Overs',
                      hintText: 'Enter overs per innings',
                      prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final o in _overPresets)
                        ActionChip(
                          label: Text('$o'),
                          onPressed: () => setState(() => _overs.text = '$o'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _playersPerSide,
                    dropdownColor: AppColors.surfaceHi,
                    decoration: const InputDecoration(
                      labelText: 'Players per side',
                      helperText: 'All out at one wicket fewer',
                      prefixIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
                    ),
                    items: _sideSizeOptions
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n a side')))
                        .toList(),
                    onChanged: (v) => setState(() => _playersPerSide = v ?? _playersPerSide),
                  ),
                  const SizedBox(height: 20),
                  Text('Toss won by', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: true, label: Text(_team1.text.trim().isEmpty ? 'Team 1' : _team1.text.trim())),
                        ButtonSegment(value: false, label: Text(_team2.text.trim().isEmpty ? 'Team 2' : _team2.text.trim())),
                      ],
                      selected: {_tossWonByTeam1},
                      onSelectionChanged: (s) => setState(() => _tossWonByTeam1 = s.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Elected to', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<TossDecision>(
                      segments: const [
                        ButtonSegment(
                          value: TossDecision.bat,
                          label: Text('Bat'),
                          icon: Icon(Icons.sports_cricket_rounded),
                        ),
                        ButtonSegment(
                          value: TossDecision.bowl,
                          label: Text('Bowl'),
                          icon: Icon(Icons.sports_baseball_outlined),
                        ),
                      ],
                      selected: {_tossDecision},
                      onSelectionChanged: (s) => setState(() => _tossDecision = s.first),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Ball type', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<BallType>(
                      segments: const [
                        ButtonSegment(
                          value: BallType.leather,
                          label: Text('Leather'),
                          icon: Icon(Icons.sports_cricket_rounded),
                        ),
                        ButtonSegment(
                          value: BallType.tennis,
                          label: Text('Tennis'),
                          icon: Icon(Icons.sports_baseball_rounded),
                        ),
                      ],
                      selected: {_ballType},
                      onSelectionChanged: (s) => setState(() {
                        _ballType = s.first;
                        // Tennis-ball cricket is almost always played without LBW.
                        _lbwAllowed = _ballType == BallType.leather;
                      }),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('LBW allowed'),
                    subtitle: Text(
                      _lbwAllowed ? 'LBW is available as a dismissal' : 'LBW hidden when scoring',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txLow),
                    ),
                    value: _lbwAllowed,
                    onChanged: (v) => setState(() => _lbwAllowed = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Start Scoring',
              icon: Icons.play_arrow_rounded,
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }
}
