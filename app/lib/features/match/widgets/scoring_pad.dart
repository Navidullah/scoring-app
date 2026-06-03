import 'package:flutter/material.dart';

import '../../../domain/enums/cricket_enums.dart';

/// The scorer's input pad: runs, extras, wicket, and undo.
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Run buttons.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0, 1, 2, 3, 4, 6]
                .map((r) => _RunButton(
                      label: '$r',
                      onTap: enabled ? () => onRuns(r) : null,
                      highlight: r == 4 || r == 6,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Extras.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExtraButton(label: 'Wide', onTap: enabled ? () => onExtra(ExtraType.wide) : null),
              _ExtraButton(label: 'No ball', onTap: enabled ? () => onExtra(ExtraType.noBall) : null),
              _ExtraButton(label: 'Bye', onTap: enabled ? () => onExtra(ExtraType.bye) : null),
              _ExtraButton(label: 'Leg bye', onTap: enabled ? () => onExtra(ExtraType.legBye) : null),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: enabled ? onWicket : null,
                  icon: const Icon(Icons.sports_cricket),
                  label: const Text('Wicket'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunButton extends StatelessWidget {
  const _RunButton({required this.label, required this.onTap, this.highlight = false});
  final String label;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 64,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: highlight ? scheme.secondary : scheme.primaryContainer,
          foregroundColor: highlight ? scheme.onSecondary : scheme.onPrimaryContainer,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
