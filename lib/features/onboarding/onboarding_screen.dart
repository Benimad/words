import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/wq_button.dart';
import '../../state/progress_controller.dart';
import 'widgets/onboarding_illustrations.dart';

/// Four-page animated intro.
///
/// Design intent: teach the *loop*, not the controls. Each page pairs one
/// animated illustration with one sentence, and the accent colour of the whole
/// screen (including the aurora behind it) morphs page to page — so swiping
/// feels like moving through the game's worlds rather than reading a manual.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      title: 'Swipe to discover',
      body: 'Drag across the letters in any direction — across, down, '
          'diagonally, even backwards — to claim a hidden word.',
      accent: AppPalette.violet,
      illustration: SwipeDemoIllustration(),
    ),
    _OnboardPage(
      title: 'Travel the map',
      body: 'Eight worlds. 240 handcrafted levels. Every puzzle you solve '
          'opens the path to the next destination.',
      accent: AppPalette.mint,
      illustration: JourneyIllustration(),
    ),
    _OnboardPage(
      title: 'Earn and spend',
      body: 'Collect coins for every level you finish, then spend them on '
          'hints whenever a board refuses to give up its secrets.',
      accent: AppPalette.amber,
      illustration: RewardsIllustration(),
    ),
    _OnboardPage(
      title: 'Come back daily',
      body: 'A fresh puzzle lands every day. Keep your streak alive for '
          'bigger and bigger bonuses.',
      accent: AppPalette.orange,
      illustration: StreakIllustration(),
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    context.read<AudioService>().play(Sfx.button);
    context.read<HapticService>().light();

    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppDurations.page,
      curve: AppCurves.emphasised,
    );
  }

  void _finish() {
    context.read<ProgressController>().completeOnboarding();
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _pages[_page].accent;

    return Scaffold(
      body: AuroraBackground(
        // The backdrop takes the current page's accent, so the whole screen
        // shifts hue as the player swipes.
        accents: [accent, Color.lerp(accent, AppPalette.violet, 0.5)!],
        child: SafeArea(
          child: Column(
            children: [
              // --- Skip -------------------------------------------------
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: AppSpacing.lg,
                    top: AppSpacing.sm,
                  ),
                  child: AnimatedOpacity(
                    duration: AppDurations.fast,
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: const Text('Skip'),
                    ),
                  ),
                ),
              ),

              // --- Pages ------------------------------------------------
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _page = index);
                    context.read<HapticService>().selectionTick();
                  },
                  itemBuilder: (context, index) => _OnboardPageView(
                    page: _pages[index],
                    // Pass the controller so each page can parallax against
                    // the scroll position.
                    controller: _pageController,
                    index: index,
                  ),
                ),
              ),

              // --- Indicator + CTA --------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _pages.length; i++)
                          AnimatedContainer(
                            duration: AppDurations.normal,
                            curve: AppCurves.enter,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            // The active dot stretches into a pill — clearer
                            // than a size-only change at a glance.
                            width: i == _page ? 26 : 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? accent
                                  : theme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    WqButton(
                      label: _isLast ? 'Start playing' : 'Continue',
                      icon: _isLast
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_forward_rounded,
                      gradient: AppGradients.fromAccent(accent),
                      onPressed: _next,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.title,
    required this.body,
    required this.accent,
    required this.illustration,
  });

  final String title;
  final String body;
  final Color accent;
  final Widget illustration;
}

/// A single onboarding page, with parallax tied to the page controller.
class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({
    required this.page,
    required this.controller,
    required this.index,
  });

  final _OnboardPage page;
  final PageController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // How far this page is from centre, in pages (-1..1 while adjacent).
        final offset = controller.position.haveDimensions
            ? (controller.page ?? controller.initialPage.toDouble()) - index
            : (controller.initialPage - index).toDouble();
        final clamped = offset.clamp(-1.0, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration moves faster than the text — the parallax that
              // gives the swipe depth.
              Transform.translate(
                offset: Offset(-clamped * 90, 0),
                child: Opacity(
                  opacity: (1 - clamped.abs()).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1 - clamped.abs() * 0.15,
                    child: page.illustration,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
              Transform.translate(
                offset: Offset(-clamped * 45, 0),
                child: Opacity(
                  opacity: (1 - clamped.abs() * 1.4).clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        page.body,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
