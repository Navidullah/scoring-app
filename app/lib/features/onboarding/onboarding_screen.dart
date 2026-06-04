import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/ui_widgets.dart';

/// First-run intro. Shown once (gated by a Hive flag in the router) to explain
/// what the app does before dropping the user on Home.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.icon, this.gradient, this.title, this.body);
  final IconData icon;
  final List<Color> gradient;
  final String title;
  final String body;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      Icons.sports_cricket_rounded,
      AppColors.brand,
      'Score ball by ball',
      'Live scoring with extras, wickets, free hits and strike rotation — full batting and bowling stats, the moment it happens.',
    ),
    _Slide(
      Icons.emoji_events_rounded,
      AppColors.trophy,
      'Tournaments & leaderboards',
      'Run round-robin or knockout tournaments with points tables and NRR, and track top run-scorers and wicket-takers.',
    ),
    _Slide(
      Icons.ios_share_rounded,
      AppColors.sixGrad,
      'Share & never lose data',
      'Works fully offline, then syncs to the cloud. Share a polished scorecard as an image or PDF in one tap.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Hive.box<dynamic>(HiveBoxes.settings).put('onboardingDone', true);
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeonIconBadge(icon: s.icon, gradient: s.gradient, size: 110, iconSize: 56),
                        const SizedBox(height: 36),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: context.txMid, height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : context.txLow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: GradientButton(
                label: last ? 'Get Started' : 'Next',
                icon: last ? Icons.check_rounded : Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
