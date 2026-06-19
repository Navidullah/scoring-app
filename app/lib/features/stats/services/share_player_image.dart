import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/gradient_button.dart';
import '../widgets/player_share_card.dart';
import 'player_stats.dart';

/// Shows a preview of the shareable player-stats card and lets the user share it
/// as a PNG (great for WhatsApp / Instagram). Captures the rendered card via a
/// [RepaintBoundary] at high resolution.
Future<void> sharePlayerImage(BuildContext context, PlayerCareer career) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SharePlayerDialog(career: career),
  );
}

class _SharePlayerDialog extends StatefulWidget {
  const _SharePlayerDialog({required this.career});
  final PlayerCareer career;

  @override
  State<_SharePlayerDialog> createState() => _SharePlayerDialogState();
}

class _SharePlayerDialogState extends State<_SharePlayerDialog> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final safe =
          widget.career.name.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
      final file = await File('${dir.path}/${safe}_stats.png').writeAsBytes(bytes);

      if (mounted) Navigator.of(context).pop();
      final c = widget.career;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '${c.name} — ${c.batting.runs} runs, ${c.bowling.wickets} wickets '
            'in ${c.matches} match${c.matches == 1 ? '' : 'es'} on CricLive',
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not share image: $e')));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _cardKey,
              child: PlayerShareCard(career: widget.career),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 340,
              child: GradientButton(
                label: _busy ? 'Preparing…' : 'Share image',
                icon: _busy ? null : Icons.share_rounded,
                onPressed: _busy ? null : _share,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
