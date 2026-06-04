import 'package:flutter/material.dart';

import '../../../domain/enums/cricket_enums.dart';

const Map<WicketType, String> wicketLabels = {
  WicketType.bowled: 'Bowled',
  WicketType.caught: 'Caught',
  WicketType.lbw: 'LBW',
  WicketType.runOut: 'Run out',
  WicketType.stumped: 'Stumped',
  WicketType.hitWicket: 'Hit wicket',
  WicketType.retired: 'Retired',
};

/// Prompts for the two opening batsmen. Non-dismissible — names are required.
Future<List<String>?> showOpenersDialog(BuildContext context, {required String teamName}) {
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _OpenersDialog(teamName: teamName),
  );
}

/// Prompts for a single player name (e.g. new bowler / incoming batsman).
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String label,
  bool dismissible = false,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: dismissible,
    builder: (_) => _NameDialog(title: title, label: label),
  );
}

/// Prompts for the next bowler. Shows already-used bowlers as quick-pick chips
/// (the one who just bowled is disabled — no consecutive overs) and a field to
/// enter a brand-new bowler. Returns the chosen/entered name.
Future<String?> showBowlerDialog(
  BuildContext context, {
  required List<String> previousBowlers,
  String? disabledBowler,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BowlerDialog(
      previousBowlers: previousBowlers,
      disabledBowler: disabledBowler,
    ),
  );
}

/// Prompts for a run count (used for byes / leg-byes). Returns 1..4.
Future<int?> showRunCountDialog(BuildContext context, {required String title}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Wrap(
        spacing: 8,
        children: [1, 2, 3, 4]
            .map((n) => ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(n),
                  child: Text('$n'),
                ))
            .toList(),
      ),
    ),
  );
}

/// Outcome of the wicket dialog: how out, who's the new batsman, the fielder
/// (for caught/stumped/run-out), and whether the non-striker was the one out
/// (run-out only).
typedef WicketEntry = ({WicketType type, String batsman, String? fielder, bool nonStrikerOut});

/// Prompts for the wicket type, the fielder (when relevant), the incoming
/// batsman's name, and — for a run-out — which batsman was out.
/// [lbwAllowed] hides LBW (e.g. tennis-ball matches). [runOutOnly] restricts
/// dismissals to run-out (used on a free hit).
Future<WicketEntry?> showWicketDialog(
  BuildContext context, {
  required String striker,
  required String nonStriker,
  bool lbwAllowed = true,
  bool runOutOnly = false,
}) {
  return showDialog<WicketEntry>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WicketDialog(
      striker: striker,
      nonStriker: nonStriker,
      lbwAllowed: lbwAllowed,
      runOutOnly: runOutOnly,
    ),
  );
}

/// Outcome of the retire dialog.
typedef RetireEntry = ({bool nonStriker, String replacement});

/// Prompts for which batsman is retiring and who replaces them.
Future<RetireEntry?> showRetireDialog(
  BuildContext context, {
  required String striker,
  required String nonStriker,
}) {
  return showDialog<RetireEntry>(
    context: context,
    builder: (_) => _RetireDialog(striker: striker, nonStriker: nonStriker),
  );
}

/// Dismissals that involve a fielder, and the label for that field.
const Map<WicketType, String> _fielderLabel = {
  WicketType.caught: 'Caught by',
  WicketType.stumped: 'Stumped by',
  WicketType.runOut: 'Run out by',
};

class _OpenersDialog extends StatefulWidget {
  const _OpenersDialog({required this.teamName});
  final String teamName;

  @override
  State<_OpenersDialog> createState() => _OpenersDialogState();
}

class _OpenersDialogState extends State<_OpenersDialog> {
  final _striker = TextEditingController();
  final _nonStriker = TextEditingController();

  @override
  void dispose() {
    _striker.dispose();
    _nonStriker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.teamName} — opening batsmen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _striker,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Striker'),
          ),
          TextField(
            controller: _nonStriker,
            decoration: const InputDecoration(labelText: 'Non-striker'),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            final s = _striker.text.trim();
            final n = _nonStriker.text.trim();
            if (s.isEmpty || n.isEmpty) return;
            Navigator.of(context).pop([s, n]);
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label});
  final String title;
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        FilledButton(onPressed: _submit, child: const Text('Confirm')),
      ],
    );
  }

  void _submit() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(v);
  }
}

class _WicketDialog extends StatefulWidget {
  const _WicketDialog({
    required this.striker,
    required this.nonStriker,
    this.lbwAllowed = true,
    this.runOutOnly = false,
  });
  final String striker;
  final String nonStriker;
  final bool lbwAllowed;
  final bool runOutOnly;

  @override
  State<_WicketDialog> createState() => _WicketDialogState();
}

class _WicketDialogState extends State<_WicketDialog> {
  late WicketType _type = widget.runOutOnly ? WicketType.runOut : WicketType.bowled;
  bool _nonStrikerOut = false;
  final _batsman = TextEditingController();
  final _fielder = TextEditingController();

  @override
  void dispose() {
    _batsman.dispose();
    _fielder.dispose();
    super.dispose();
  }

  /// Dismissal options: on a free hit only run-out is allowed; otherwise LBW is
  /// hidden when not allowed and "Retired" is excluded (it's a separate action).
  List<WicketType> get _options {
    if (widget.runOutOnly) return [WicketType.runOut];
    return wicketLabels.keys.where((w) {
      if (w == WicketType.retired) return false;
      if (w == WicketType.lbw && !widget.lbwAllowed) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fielderLabel = _fielderLabel[_type];
    final needsFielder = fielderLabel != null;
    return AlertDialog(
      title: Text(widget.runOutOnly ? 'Run out (free hit)' : 'Wicket!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<WicketType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'How out?'),
            items: _options
                .map((w) => DropdownMenuItem(value: w, child: Text(wicketLabels[w]!)))
                .toList(),
            onChanged: widget.runOutOnly ? null : (v) => setState(() => _type = v ?? _type),
          ),
          if (_type == WicketType.runOut) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Who is out?', style: Theme.of(context).textTheme.labelMedium),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(widget.striker)),
                  ButtonSegment(value: true, label: Text(widget.nonStriker)),
                ],
                selected: {_nonStrikerOut},
                onSelectionChanged: (s) => setState(() => _nonStrikerOut = s.first),
              ),
            ),
          ],
          if (needsFielder)
            TextField(
              controller: _fielder,
              decoration: InputDecoration(labelText: fielderLabel),
            ),
          TextField(
            controller: _batsman,
            decoration: const InputDecoration(labelText: 'New batsman'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _batsman.text.trim();
            if (name.isEmpty) return;
            final fielder = _fielder.text.trim();
            Navigator.of(context).pop((
              type: _type,
              batsman: name,
              fielder: needsFielder && fielder.isNotEmpty ? fielder : null,
              nonStrikerOut: _type == WicketType.runOut && _nonStrikerOut,
            ));
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _BowlerDialog extends StatefulWidget {
  const _BowlerDialog({required this.previousBowlers, this.disabledBowler});
  final List<String> previousBowlers;
  final String? disabledBowler;

  @override
  State<_BowlerDialog> createState() => _BowlerDialogState();
}

class _BowlerDialogState extends State<_BowlerDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitNew() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final hasPrevious = widget.previousBowlers.isNotEmpty;
    return AlertDialog(
      title: const Text('Next bowler'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPrevious) ...[
            Text('Choose bowler', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.previousBowlers.map((name) {
                final disabled = name == widget.disabledBowler;
                return ActionChip(
                  label: Text(name),
                  // A bowler can't bowl two overs in a row → disabled chip.
                  onPressed: disabled ? null : () => Navigator.of(context).pop(name),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text('or add new', style: Theme.of(context).textTheme.labelMedium),
          ],
          TextField(
            controller: _controller,
            autofocus: !hasPrevious,
            decoration: const InputDecoration(labelText: 'New bowler'),
            onSubmitted: (_) => _submitNew(),
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: _submitNew, child: const Text('Add')),
      ],
    );
  }
}

class _RetireDialog extends StatefulWidget {
  const _RetireDialog({required this.striker, required this.nonStriker});
  final String striker;
  final String nonStriker;

  @override
  State<_RetireDialog> createState() => _RetireDialogState();
}

class _RetireDialogState extends State<_RetireDialog> {
  bool _nonStriker = false;
  final _replacement = TextEditingController();

  @override
  void dispose() {
    _replacement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Retire batsman'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who is retiring?', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(widget.striker)),
                ButtonSegment(value: true, label: Text(widget.nonStriker)),
              ],
              selected: {_nonStriker},
              onSelectionChanged: (s) => setState(() => _nonStriker = s.first),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _replacement,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'New batsman'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Retire')),
      ],
    );
  }

  void _submit() {
    final name = _replacement.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((nonStriker: _nonStriker, replacement: name));
  }
}
