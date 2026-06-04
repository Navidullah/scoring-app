import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/enums/cricket_enums.dart';

/// The scorer's input deck: runs, extras, wicket, and undo.
/// Purely presentational — all actions are delegated via callbacks.
class ScoringPad extends StatelessWidget {
  const ScoringPad({
    super.key,
    required this.enabled,
    required this.onRuns,
    required this.onExtra,
    required this.onWicket,
    required this.onUndo,
  });

  final bool enabled;
  final void Function(int runs) onRuns;
  final void Function(ExtraType type) onExtra;
  final VoidCallback onWicket;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Kept dark in both themes: the keypad reads as a premium broadcast
        // "control deck". Near-solid so it looks intentional over a light page.
        color: AppColors.scoreboard.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.glassStroke)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            children: [
              // Dot + singles row.
              Row(
                children: [
                  for (final r in [0, 1, 2, 3])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _RunButton(
                          label: '$r',
                          sub: r == 0 ? 'dot' : null,
                          onTap: enabled ? () => onRuns(r) : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Boundaries.
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _RunButton(
                        label: '4',
                        sub: 'FOUR',
                        gradient: AppColors.fourGrad,
                        onTap: enabled ? () => onRuns(4) : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _RunButton(
                        label: '6',
                        sub: 'SIX',
                        gradient: AppColors.sixGrad,
                        onTap: enabled ? () => onRuns(6) : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Extras.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _ExtraButton(label: 'Wide', onTap: enabled ? () => onExtra(ExtraType.wide) : null),
                  _ExtraButton(label: 'No ball', onTap: enabled ? () => onExtra(ExtraType.noBall) : null),
                  _ExtraButton(label: 'Bye', onTap: enabled ? () => onExtra(ExtraType.bye) : null),
                  _ExtraButton(label: 'Leg bye', onTap: enabled ? () => onExtra(ExtraType.legBye) : null),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _ActionButton(
                      label: 'Wicket',
                      icon: Icons.sports_cricket_rounded,
                      gradient: AppColors.wicketGrad,
                      onTap: enabled ? onWicket : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Undo',
                      icon: Icons.undo_rounded,
                      onTap: onUndo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A big run-value key. Boundaries get a gradient fill + glow.
class _RunButton extends StatelessWidget {
  const _RunButton({required this.label, required this.onTap, this.sub, this.gradient});

  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: hasGradient
              ? LinearGradient(
                  colors: gradient!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: hasGradient ? null : AppColors.glassFillStrong,
          border: Border.all(
            color: hasGradient ? Colors.transparent : AppColors.glassStroke,
          ),
          boxShadow: hasGradient
              ? [
                  BoxShadow(
                    color: gradient!.last.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: hasGradient ? Colors.white : AppColors.textHi,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: hasGradient ? Colors.white70 : AppColors.textLow,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExtraButton extends StatelessWidget {
  const _ExtraButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassStroke),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHi,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasGradient
              ? LinearGradient(colors: gradient!, begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          color: hasGradient ? null : AppColors.glassFill,
          border: Border.all(color: hasGradient ? Colors.transparent : AppColors.glassStroke),
          boxShadow: hasGradient
              ? [
                  BoxShadow(
                    color: gradient!.last.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: hasGradient ? Colors.white : AppColors.textHi),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: hasGradient ? Colors.white : AppColors.textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
