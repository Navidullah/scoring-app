import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/innings.dart';
import '../../../shared/widgets/glass_card.dart';

/// Live batsmen (striker marked with *) and current bowler figures.
class BattingBowlingPanel extends StatelessWidget {
  const BattingBowlingPanel({super.key, required this.innings});

  final Innings innings;

  @override
  Widget build(BuildContext context) {
    final striker = innings.striker;
    final nonStriker = innings.nonStriker;
    final bowler = innings.bowler;

    return GlassCard(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          _header(context, 'BATTER', 'R', 'B', '4s', '6s', 'SR'),
          const SizedBox(height: 6),
          const Divider(height: 12),
          if (striker != null) _batRow(context, striker, isStriker: true),
          if (nonStriker != null) _batRow(context, nonStriker, isStriker: false),
          const Divider(height: 18),
          _bowlerRow(context, bowler),
        ],
      ),
    );
  }

  Widget _header(BuildContext c, String a, String b, String d, String e, String f, String g) {
    final style = Theme.of(c).textTheme.labelSmall;
    return Row(
      children: [
        Expanded(flex: 4, child: Text(a, style: style)),
        Expanded(child: Text(b, style: style, textAlign: TextAlign.end)),
        Expanded(child: Text(d, style: style, textAlign: TextAlign.end)),
        Expanded(child: Text(e, style: style, textAlign: TextAlign.end)),
        Expanded(child: Text(f, style: style, textAlign: TextAlign.end)),
        Expanded(flex: 2, child: Text(g, style: style, textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _batRow(BuildContext c, String name, {required bool isStriker}) {
    final s = innings.batStat(name);
    final weight = isStriker ? FontWeight.w800 : FontWeight.w500;
    final color = isStriker ? AppColors.primary : c.txHi;
    Widget num(String v, {int flex = 1, bool bold = false}) => Expanded(
          flex: flex,
          child: Text(
            v,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: c.txHi,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                if (isStriker)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.sports_cricket_rounded, size: 14, color: AppColors.primary),
                  ),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: weight, color: color),
                  ),
                ),
              ],
            ),
          ),
          num('${s.runs}', bold: true),
          num('${s.balls}'),
          num('${s.fours}'),
          num('${s.sixes}'),
          num(s.strikeRate.toStringAsFixed(1), flex: 2),
        ],
      ),
    );
  }

  Widget _bowlerRow(BuildContext c, String? bowler) {
    if (bowler == null) {
      return Row(
        children: [
          const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text('Select next bowler',
              style: Theme.of(c).textTheme.bodyMedium?.copyWith(color: c.txMid)),
        ],
      );
    }
    final b = innings.bowlStat(bowler);
    return Row(
      children: [
        const Icon(Icons.sports_baseball_rounded, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            bowler,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.txHi),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '${b.oversText}-${b.runsConceded}-${b.wickets}',
            textAlign: TextAlign.end,
            style: TextStyle(color: c.txHi, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Econ ${b.economy.toStringAsFixed(1)}',
            textAlign: TextAlign.end,
            style: TextStyle(color: c.txMid, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
