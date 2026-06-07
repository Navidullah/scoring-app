import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/cricket_match.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/ui_widgets.dart';
import '../history/scorecard_screen.dart';

/// Fetches a finished match snapshot from the cloud and shows its full scorecard.
/// Reuses [ScorecardScreen] by handing it the downloaded match directly.
class ResultViewScreen extends ConsumerStatefulWidget {
  const ResultViewScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<ResultViewScreen> createState() => _ResultViewScreenState();
}

class _ResultViewScreenState extends ConsumerState<ResultViewScreen> {
  CricketMatch? _match;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final json = await ref.read(liveApiProvider).getMatch(widget.matchId);
      if (!mounted) return;
      setState(() {
        _match = json == null ? null : CricketMatch.fromJson(json);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    if (match != null) {
      return ScorecardScreen(match: match);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/results'),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 18),
                  Text('Loading scorecard…',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text('The server may take a few seconds to wake up.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Result not available',
                    subtitle: 'It may have expired (results are kept for 24h) or the server is waking up. Pull down to retry.',
                    gradient: [Color(0xFF64748B), Color(0xFF475569)],
                  ),
                ],
              ),
            ),
    );
  }
}
