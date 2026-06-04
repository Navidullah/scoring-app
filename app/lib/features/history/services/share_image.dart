import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/cricket_match.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../widgets/match_share_card.dart';

/// Shows a preview of the shareable match card and lets the user share it as a
/// PNG image (great for WhatsApp / Instagram). Captures the rendered card via a
/// [RepaintBoundary] at high resolution.
Future<void> shareMatchImage(BuildContext context, CricketMatch match) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ShareImageDialog(match: match),
  );
}

class _ShareImageDialog extends StatefulWidget {
  const _ShareImageDialog({required this.match});
  final CricketMatch match;

  @override
  State<_ShareImageDialog> createState() => _ShareImageDialogState();
}

class _ShareImageDialogState extends State<_ShareImageDialog> {
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
      final safe = '${widget.match.team1}_vs_${widget.match.team2}'
          .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
      final file = await File('${dir.path}/$safe.png').writeAsBytes(bytes);

      if (mounted) Navigator.of(context).pop();
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '${widget.match.team1} vs ${widget.match.team2}'
            '${widget.match.resultText != null ? ' — ${widget.match.resultText}' : ''}',
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
              child: MatchShareCard(match: widget.match),
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
