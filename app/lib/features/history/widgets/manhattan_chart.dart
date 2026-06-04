import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A Manhattan chart: one vertical bar per over (height = runs), with a marker
/// on overs in which a wicket fell. Bars share the available width and the
/// chart scrolls horizontally when there are many overs.
class ManhattanChart extends StatelessWidget {
  const ManhattanChart({super.key, required this.overs});

  /// Per-over (runs, wickets), in over order.
  final List<({int runs, int wickets})> overs;

  static const double _maxBarHeight = 96;

  @override
  Widget build(BuildContext context) {
    if (overs.isEmpty) return const SizedBox.shrink();
    final maxRuns = overs.map((o) => o.runs).fold(1, (a, b) => b > a ? b : a);

    final bars = [
      for (var i = 0; i < overs.length; i++)
        _OverBar(
          overNo: i + 1,
          runs: overs[i].runs,
          wickets: overs[i].wickets,
          heightFactor: overs[i].runs / maxRuns,
          maxBarHeight: _maxBarHeight,
        ),
    ];

    final chart = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Manhattan', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            _legendDot(AppColors.wicket, 'wicket', context),
          ],
        ),
        const SizedBox(height: 12),
        // Bars: spread to fill width when few overs; scroll when many.
        overs.length <= 14
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [for (final b in bars) Expanded(child: b)],
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final b in bars) SizedBox(width: 26, child: b),
                  ],
                ),
              ),
      ],
    );

    return chart;
  }

  Widget _legendDot(Color color, String label, BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.txLow)),
        ],
      );
}

class _OverBar extends StatelessWidget {
  const _OverBar({
    required this.overNo,
    required this.runs,
    required this.wickets,
    required this.heightFactor,
    required this.maxBarHeight,
  });

  final int overNo;
  final int runs;
  final int wickets;
  final double heightFactor;
  final double maxBarHeight;

  @override
  Widget build(BuildContext context) {
    // A minimum visible nub even for a 0-run over.
    final barHeight = (heightFactor.clamp(0.0, 1.0) * maxBarHeight).clamp(3.0, maxBarHeight);
    final hasWicket = wickets > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$runs',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: context.txMid,
            ),
          ),
          const SizedBox(height: 2),
          if (hasWicket)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(color: AppColors.wicket, shape: BoxShape.circle),
            ),
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasWicket ? AppColors.wicketGrad : AppColors.brand,
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$overNo',
            style: TextStyle(fontSize: 9, color: context.txLow),
          ),
        ],
      ),
    );
  }
}
