import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/innings.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ui_widgets.dart';
import '../scorecard_format.dart';

/// Full batting + bowling card for a single innings.
class InningsScorecard extends StatelessWidget {
  const InningsScorecard({super.key, required this.innings});

  final Innings innings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final batsmen = innings.batsmenInOrder;
    final bowlers = innings.bowlersUsed;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  innings.battingTeam,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GradientText(
                '${innings.runs}/${innings.wickets}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('(${innings.oversText})',
                    style: theme.textTheme.bodySmall?.copyWith(color: context.txLow)),
              ),
            ],
          ),
          const SizedBox(height: 12),
            // Batting
            _batHeader(theme),
            const Divider(height: 12),
            ...batsmen.map((b) => _batRow(context, b)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Extras', style: theme.textTheme.bodyMedium),
                Text('${innings.extras}', style: theme.textTheme.bodyMedium),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  '${innings.runs}/${innings.wickets}  (${innings.oversText} ov)',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bowling
            _bowlHeader(theme),
            const Divider(height: 12),
            ...bowlers.map((b) => _bowlRow(context, b)),
          ],
        ),
      );
  }

  Widget _batHeader(ThemeData theme) {
    final s = theme.textTheme.labelSmall;
    return Row(
      children: [
        Expanded(flex: 5, child: Text('Batsman', style: s)),
        Expanded(child: Text('R', style: s, textAlign: TextAlign.end)),
        Expanded(child: Text('B', style: s, textAlign: TextAlign.end)),
        Expanded(child: Text('4s', style: s, textAlign: TextAlign.end)),
        Expanded(child: Text('6s', style: s, textAlign: TextAlign.end)),
        Expanded(flex: 2, child: Text('SR', style: s, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _batRow(BuildContext context, String name) {
    final theme = Theme.of(context);
    final st = innings.batStat(name);
    final dismissal = dismissalText(innings, name);
    final notOut = innings.dismissalOf(name) == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: notOut ? FontWeight.bold : FontWeight.normal)),
                Text(dismissal, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
          Expanded(child: Text('${st.runs}', textAlign: TextAlign.end)),
          Expanded(child: Text('${st.balls}', textAlign: TextAlign.end)),
          Expanded(child: Text('${st.fours}', textAlign: TextAlign.end)),
          Expanded(child: Text('${st.sixes}', textAlign: TextAlign.end)),
          Expanded(flex: 2, child: Text(st.strikeRate.toStringAsFixed(1), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _bowlHeader(ThemeData theme) {
    final s = theme.textTheme.labelSmall;
    return Row(
      children: [
        Expanded(flex: 4, child: Text('Bowler', style: s)),
        Expanded(child: Text('O', style: s, textAlign: TextAlign.end)),
        Expanded(child: Text('M', style: s, textAlign: TextAlign.end)),
        Expanded(child: Text('R', style: s, textAlign: TextAlign.end)),
        Expanded(child: Text('W', style: s, textAlign: TextAlign.end)),
        Expanded(flex: 2, child: Text('Econ', style: s, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _bowlRow(BuildContext context, String name) {
    final st = innings.bowlStat(name);
    final maidens = innings.maidensFor(name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(name)),
          Expanded(child: Text(st.oversText, textAlign: TextAlign.end)),
          Expanded(child: Text('$maidens', textAlign: TextAlign.end)),
          Expanded(child: Text('${st.runsConceded}', textAlign: TextAlign.end)),
          Expanded(child: Text('${st.wickets}', textAlign: TextAlign.end)),
          Expanded(flex: 2, child: Text(st.economy.toStringAsFixed(1), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

