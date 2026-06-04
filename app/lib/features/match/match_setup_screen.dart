import 'package:flutter/material.dart';
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
  int _overs = AppConstants.defaultOvers;
  bool _team1BatsFirst = true;
  BallType _ballType = BallType.leather;
  bool _lbwAllowed = true;

  static const _overOptions = [5, 6, 8, 10, 15, 20, 50];

  @override
  void dispose() {
    _team1.dispose();
    _team2.dispose();
    super.dispose();
  }

  void _start() {
    if (!_formKey.currentState!.validate()) return;
    final t1 = titleCase(_team1.text);
    final t2 = titleCase(_team2.text);
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
      ballType: _ballType,
      lbwAllowed: _lbwAllowed,
      innings: [Innings(battingTeam: battingFirst, bowlingTeam: bowlingFirst)],
    );

    ref.read(matchRepositoryProvider).saveMatch(match);
    // Replace setup so Back from live scoring returns to the previous screen.
    context.pushReplacement('/match/${match.id}/score');
  }

  @override
  Widget build(BuildContext context) {
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
                  TextFormField(
                    controller: _team1,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Team 1',
                      prefixIcon: Icon(Icons.shield_rounded, color: AppColors.primary),
                    ),
                    validator: _required,
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
                  TextFormField(
                    controller: _team2,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Team 2',
                      prefixIcon: Icon(Icons.shield_rounded, color: AppColors.cyan),
                    ),
                    validator: _required,
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
                  DropdownButtonFormField<int>(
                    initialValue: _overs,
                    decoration: const InputDecoration(
                      labelText: 'Overs',
                      prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
                    ),
                    items: _overOptions
                        .map((o) => DropdownMenuItem(value: o, child: Text('$o overs')))
                        .toList(),
                    onChanged: (v) => setState(() => _overs = v ?? _overs),
                  ),
                  const SizedBox(height: 20),
                  Text('Batting first', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: true, label: Text(_team1.text.trim().isEmpty ? 'Team 1' : _team1.text.trim())),
                        ButtonSegment(value: false, label: Text(_team2.text.trim().isEmpty ? 'Team 2' : _team2.text.trim())),
                      ],
                      selected: {_team1BatsFirst},
                      onSelectionChanged: (s) => setState(() => _team1BatsFirst = s.first),
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

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}
