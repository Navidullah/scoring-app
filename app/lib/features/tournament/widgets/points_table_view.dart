import 'package:flutter/material.dart';

import '../services/points_table.dart';

/// Renders the league standings table.
class PointsTableView extends StatelessWidget {
  const PointsTableView({super.key, required this.standings});

  final List<Standing> standings;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Points Table', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 4, child: Text('Team', style: s)),
                Expanded(child: Text('P', style: s, textAlign: TextAlign.end)),
                Expanded(child: Text('W', style: s, textAlign: TextAlign.end)),
                Expanded(child: Text('L', style: s, textAlign: TextAlign.end)),
                Expanded(child: Text('T', style: s, textAlign: TextAlign.end)),
                Expanded(child: Text('Pts', style: s, textAlign: TextAlign.end)),
                Expanded(flex: 2, child: Text('NRR', style: s, textAlign: TextAlign.end)),
              ],
            ),
            const Divider(height: 12),
            ...standings.map((st) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(st.team)),
                      Expanded(child: Text('${st.played}', textAlign: TextAlign.end)),
                      Expanded(child: Text('${st.won}', textAlign: TextAlign.end)),
                      Expanded(child: Text('${st.lost}', textAlign: TextAlign.end)),
                      Expanded(child: Text('${st.tied}', textAlign: TextAlign.end)),
                      Expanded(
                        child: Text('${st.points}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          (st.nrr >= 0 ? '+' : '') + st.nrr.toStringAsFixed(2),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
