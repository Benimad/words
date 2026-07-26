import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../state/progress_controller.dart';
import 'widgets/quest_logo.dart';

/// Animated launch screen.
///
/// It does real work — it holds the first frame while fonts warm up and the
/// route decision is made — but it is timed to the *animation*, not to a
/// contrived delay: the logo assembles over ~1.5s, the wordmark and tagline
/// follow, and the app moves on. Total ≈2.2s, which is long enough to register
/// as branding and short enough not to annoy a returning player.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  );

  /// Exit animation — the logo lifts and fades as the app hands over.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: AppDurations.normal,
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    _logo.forward();
    await Future<void>.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    _text.forward();

    await Future<void>.delayed(const Duration(milliseconds: 1150));
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;

    _goNext();
  }

  void _goNext() {
    final progress = context.read<ProgressController>().progress;
    Navigator.of(context).pushReplacementNamed(
      progress.hasCompletedOnboarding ? Routes.home : Routes.onboarding,
    );
  }

  @override
  void dispose() {
    _logo.dispose();
    _text.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AuroraBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_logo, _text, _exit]),
            builder: (context, _) {
              final exitT = AppCurves.exit.transform(_exit.value);
              return Opacity(
                opacity: 1 - exitT,
                child: Transform.translate(
                  offset: Offset(0, -40 * exitT),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QuestLogo(
                        size: 148,
                        progress: AppCurves.enter.transform(_logo.value),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _wordmark(theme),
                      const SizedBox(height: AppSpacing.sm),
                      _tagline(theme),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// The wordmark animates letter by letter — each glyph rises and fades in on
  /// its own short stagger, which is what makes the title feel "typed out"
  /// rather than simply faded up.
  Widget _wordmark(ThemeData theme) {
    const word = 'WordQuest';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < word.length; i++)
          Builder(
            builder: (context) {
              final start = i / (word.length * 1.8);
              final t = ((_text.value - start) / 0.45).clamp(0.0, 1.0);
              final eased = AppCurves.enter.transform(t);
              return Opacity(
                opacity: eased,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - eased)),
                  child: Text(
                    word[i],
                    style: TextStyle(
                      fontFamily: AppTypography.display,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      // "Word" in the ink colour, "Quest" in brand violet —
                      // the two halves of the name, visually.
                      color: i < 4
                          ? theme.colorScheme.onSurface
                          : (theme.brightness == Brightness.dark
                              ? AppPalette.violetLight
                              : AppPalette.violet),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _tagline(ThemeData theme) {
    final t = ((_text.value - 0.5) / 0.5).clamp(0.0, 1.0);
    return Opacity(
      opacity: AppCurves.enter.transform(t),
      child: Text(
        'Find the words. Follow the map.',
        style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 0.3),
      ),
    );
  }
}
