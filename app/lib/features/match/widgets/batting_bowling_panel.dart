import 'package:flutter/material.dart';

import '../../../domain/models/innings.dart';

/// Live batsmen (striker marked with *) and current bowler figures.
class BattingBowlingPanel extends StatelessWidget {
  const BattingBowlingPanel({super.key, required this.innings});

  final Innings innings;

  @override
  Widget build(BuildContext context) {
    final striker = innings.striker;
    final nonStriker = innings.nonStriker;
    final bowler = innings.bowler;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _header(context, 'Batsman', 'R', 'B', '4s', '6s', 'SR'),
            const Divider(height: 12),
            if (striker != null) _batRow(context, striker, isStriker: true),
            if (nonStriker != null) _batRow(context, nonStriker, isStriker: false),
            const Divider(height: 20),
            _bowlerRow(context, bowler),
          ],
        ),
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
    final label = isStriker ? '$name *' : name;
    final weight = isStriker ? FontWeight.bold : FontWeight.normal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: TextStyle(fontWeight: weight))),
          Expanded(child: Text('${s.runs}', textAlign: TextAlign.end)),
          Expanded(child: Text('${s.balls}', textAlign: TextAlign.end)),
          Expanded(child: Text('${s.fours}', textAlign: TextAlign.end)),
          Expanded(child: Text('${s.sixes}', textAlign: TextAlign.end)),
          Expanded(flex: 2, child: Text(s.strikeRate.toStringAsFixed(1), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _bowlerRow(BuildContext c, String? bowler) {
    if (bowler == null) {
      return Text('Select next bowler', style: Theme.of(c).textTheme.bodyMedium);
    }
    final b = innings.bowlStat(bowler);
    return Row(
      children: [
        Expanded(flex: 4, child: Text('$bowler (bowling)')),
        Expanded(flex: 3, child: Text('${b.oversText}-${b.runsConceded}-${b.wickets}', textAlign: TextAlign.end)),
        Expanded(flex: 2, child: Text('Econ ${b.economy.toStringAsFixed(1)}', textAlign: TextAlign.end)),
      ],
    );
  }
}
