import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../services/points_table.dart';

/// Renders the league standings table.
class PointsTableView extends StatelessWidget {
  const PointsTableView({super.key, required this.standings});

  final List<Standing> standings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall;
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Points Table', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 22),
              Expanded(flex: 4, child: Text('TEAM', style: labelStyle)),
              Expanded(child: Text('P', style: labelStyle, textAlign: TextAlign.end)),
              Expanded(child: Text('W', style: labelStyle, textAlign: TextAlign.end)),
              Expanded(child: Text('L', style: labelStyle, textAlign: TextAlign.end)),
              Expanded(child: Text('T', style: labelStyle, textAlign: TextAlign.end)),
              Expanded(child: Text('PTS', style: labelStyle, textAlign: TextAlign.end)),
              Expanded(flex: 2, child: Text('NRR', style: labelStyle, textAlign: TextAlign.end)),
            ],
          ),
          const Divider(height: 16),
          for (var i = 0; i < standings.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i < 2 ? AppColors.primary : context.txLow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      standings[i].team,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.txHi),
                    ),
                  ),
                  _cell(context, '${standings[i].played}'),
                  _cell(context, '${standings[i].won}'),
                  _cell(context, '${standings[i].lost}'),
                  _cell(context, '${standings[i].tied}'),
                  _cell(context, '${standings[i].points}', bold: true, color: AppColors.primary),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (standings[i].nrr >= 0 ? '+' : '') + standings[i].nrr.toStringAsFixed(2),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: standings[i].nrr >= 0 ? AppColors.primary : AppColors.wicket,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String v, {bool bold = false, Color? color}) {
    return Expanded(
      child: Text(
        v,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: color ?? context.txHi,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}
