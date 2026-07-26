import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/content/level_catalog.dart';
import '../../data/models/game_settings.dart';
import '../../data/models/hint.dart';
import '../../data/models/level.dart';
import '../../data/services/ad_service.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/coin_chip.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/game_session_controller.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import 'widgets/hint_bar.dart';
import 'widgets/level_complete_sheet.dart';
import 'widgets/puzzle_board.dart';
import 'widgets/word_list_panel.dart';

/// The gameplay screen.
///
/// Owns a [GameSessionController] for the lifetime of one level and wires it to
/// the app-wide services: sound and haptics on every gesture outcome, coins for
/// hints, and progress/ads when the level ends.
///
/// Layout is height-driven rather than fixed: the board takes whatever space is
/// left after the HUD, word list and hint bar, so it fills a tall phone without
/// overflowing a short one.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level, this.isDaily = false});

  final Level level;
  final bool isDaily;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final GameSessionController _session = GameSessionController(
    level: widget.level,
    isDailyChallenge: widget.isDaily,
  );

  /// Set once the completion has been recorded, so the reward is never granted
  /// twice (e.g. if the controller notifies again during the transition).
  LevelCompletion? _completion;
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_onSessionChanged);
    _session.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause the clock when the player leaves — a backgrounded app should not
    // burn through a timed level.
    if (state != AppLifecycleState.resumed &&
        _session.status == GameStatus.playing) {
      _session.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  // --- Session events ---------------------------------------------------

  void _onSessionChanged() {
    if (_session.status == GameStatus.completed && !_resultShown) {
      _resultShown = true;
      _handleLevelComplete();
    }
  }

  Future<void> _handleLevelComplete() async {
    final audio = context.read<AudioService>();
    final haptics = context.read<HapticService>();
    final progress = context.read<ProgressController>();

    audio.play(Sfx.levelComplete);
    haptics.celebrate();

    if (widget.isDaily) {
      // The daily challenge scores separately (streaks, not stars).
      final result = progress.completeDailyChallenge(
        wordsFound: _session.foundWords.length,
        elapsed: _session.elapsed,
      );
      if (!mounted) return;
      await _showDailyResult(result);
      return;
    }

    final completion = progress.completeLevel(
      level: widget.level,
      elapsed: _session.elapsed,
      hintsUsed: _session.hintsUsed,
      wordsFound: _session.foundWords.length,
    );

    if (!mounted) return;
    setState(() => _completion = completion);
  }

  /// Called when the player leaves the results screen. Interstitials are shown
  /// **here** — after the reward, on the way out — so an ad never interrupts a
  /// celebration.
  Future<void> _showInterstitialThen(VoidCallback action) async {
    final ads = context.read<AdService>();
    await ads.maybeShowInterstitial();
    if (!mounted) return;
    action();
  }

  // --- Gestures ---------------------------------------------------------

  void _onCellEntered() {
    context.read<AudioService>().play(Sfx.tap);
    context.read<HapticService>().selectionTick();
  }

  void _onSelectionEnd() {
    final result = _session.endSelection();
    final audio = context.read<AudioService>();
    final haptics = context.read<HapticService>();

    switch (result) {
      case SelectionResult.accepted:
        audio.play(Sfx.wordFound);
        haptics.success();
      case SelectionResult.rejected:
        audio.play(Sfx.invalid);
        haptics.error();
      case SelectionResult.alreadyFound:
      case SelectionResult.none:
        break;
    }
  }

  // --- Hints ------------------------------------------------------------

  Future<void> _useHint(HintType type) async {
    final progress = context.read<ProgressController>();
    final audio = context.read<AudioService>();
    final haptics = context.read<HapticService>();

    if (progress.coins < type.cost) {
      _showNotEnoughCoins(type);
      return;
    }

    // Apply first, charge second: a hint with nothing left to reveal must not
    // cost anything.
    final outcome = _session.applyHint(type);

    switch (outcome) {
      case HintOutcome.applied:
        progress.spendCoins(type.cost);
        progress.registerHintUsed();
        audio.play(Sfx.hint);
        haptics.success();
      case HintOutcome.nothingToReveal:
        _toast('Nothing left for that hint to reveal.');
      case HintOutcome.notEnoughCoins:
        _showNotEnoughCoins(type);
    }
  }

  void _showNotEnoughCoins(HintType type) {
    final ads = context.read<AdService>();
    context.read<HapticService>().error();

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _NotEnoughCoinsSheet(
        type: type,
        canWatchAd: ads.isRewardedReady,
        onWatchAd: () {
          Navigator.of(sheetContext).pop();
          _watchRewardedAd();
        },
        onShop: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pushNamed(Routes.shop);
        },
      ),
    );
  }

  Future<void> _watchRewardedAd() async {
    final ads = context.read<AdService>();
    final progress = context.read<ProgressController>();
    final audio = context.read<AudioService>();

    // Pause so a timed level does not tick away behind the ad.
    final wasPlaying = _session.status == GameStatus.playing;
    if (wasPlaying) _session.pause();

    final earned = await ads.showRewarded();
    if (!mounted) return;

    if (earned) {
      const reward = 75;
      progress.addCoins(reward);
      audio.play(Sfx.coin);
      _toast('+$reward coins. Thanks for watching!');
    } else {
      _toast('No ad available right now — try again shortly.');
    }

    if (wasPlaying) _session.resume();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Navigation -------------------------------------------------------

  Future<bool> _confirmExit() async {
    if (_session.status == GameStatus.completed) return true;
    if (_session.foundWords.isEmpty) return true;

    _session.pause();

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this level?'),
        content: const Text(
          'Your progress on this board will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep playing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (leave != true) {
      _session.resume();
      return false;
    }
    return true;
  }

  /// Asks for confirmation, then pops. Centralised so every exit path (system
  /// back gesture, HUD button, pause sheet) behaves identically and uses the
  /// State's own context — never one captured inside a builder closure.
  Future<void> _exitLevel() async {
    final shouldLeave = await _confirmExit();
    if (!mounted || !shouldLeave) return;
    Navigator.of(context).pop();
  }

  void _goToNextLevel() {
    final next = LevelCatalog.levelByGlobalIndex(
      widget.level.globalIndex + 1,
    );
    if (next == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    // Replace rather than push, so the back stack does not grow one entry per
    // level during a long session.
    Navigator.of(context).pushReplacementNamed(
      Routes.game,
      arguments: GameArgs(level: next),
    );
  }

  void _replay() {
    setState(() {
      _completion = null;
      _resultShown = false;
    });
    _session.restart();
  }

  Future<void> _showDailyResult(
    ({int coinsAwarded, bool isNewRecord, int streak}) result,
  ) async {
    context.read<AudioService>().play(Sfx.streak);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DailyResultDialog(
        streak: result.streak,
        coins: result.coinsAwarded,
        isNewRecord: result.isNewRecord,
        elapsed: _session.elapsed,
        onDone: () {
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // --- Build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>().settings;
    final world = widget.isDaily
        ? null
        : LevelCatalog.worldById(widget.level.worldId);
    final accent = world == null
        ? AppPalette.amber
        : AppPalette.worldAccents[world.paletteIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitLevel();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AuroraBackground(
          accents: [accent, Color.lerp(accent, AppPalette.violet, 0.5)!],
          // Dial the backdrop down so board contrast stays high.
          intensity: 0.55,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _session,
              builder: (context, _) => _buildBody(accent, settings),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Color accent, GameSettings settings) {
    // Results screen replaces the board entirely once the level is scored.
    final completion = _completion;
    if (completion != null) {
      return LevelCompleteSheet(
        completion: completion,
        accent: accent,
        hasNextLevel:
            LevelCatalog.levelByGlobalIndex(widget.level.globalIndex + 1) !=
                null,
        onAction: (action) {
          switch (action) {
            case LevelCompleteAction.nextLevel:
              _showInterstitialThen(_goToNextLevel);
            case LevelCompleteAction.replay:
              _replay();
            case LevelCompleteAction.home:
              _showInterstitialThen(
                () => Navigator.of(context).popUntil((r) => r.isFirst),
              );
          }
        },
      );
    }

    switch (_session.status) {
      case GameStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case GameStatus.error:
        return WqEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load this puzzle',
          message: _session.errorMessage ?? 'Please try another level.',
          action: WqButton(
            label: 'Go back',
            expand: false,
            onPressed: () => Navigator.of(context).pop(),
          ),
        );

      case GameStatus.failed:
        return _TimeUpView(
          onRetry: _replay,
          onExit: () => Navigator.of(context).pop(),
          onAddTime: () {
            // A rewarded ad buys 30 extra seconds — optional, never required.
            _watchRewardedAdForTime();
          },
          canWatchAd: context.read<AdService>().isRewardedReady,
        );

      case GameStatus.playing || GameStatus.paused || GameStatus.completed:
        return _buildPlayfield(accent, settings);
    }
  }

  Future<void> _watchRewardedAdForTime() async {
    final ads = context.read<AdService>();
    final earned = await ads.showRewarded();
    if (!mounted) return;
    if (earned) {
      _session.addTime(const Duration(seconds: 30));
      _toast('+30 seconds. Go!');
    } else {
      _toast('No ad available right now.');
    }
  }

  Widget _buildPlayfield(Color accent, GameSettings settings) {
    final progress = context.watch<ProgressController>();
    final ads = context.read<AdService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve space for the chrome, then give the rest to the board.
        final wordListHeight = (constraints.maxHeight * 0.16).clamp(60.0, 118.0);

        return Column(
          children: [
            _GameHud(
              session: _session,
              level: widget.level,
              isDaily: widget.isDaily,
              accent: accent,
              showTimer: settings.showTimer,
              onBack: _exitLevel,
              onPause: () {
                _session.pause();
                _showPauseSheet();
              },
            ),

            // Word list.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: WordListPanel(
                controller: _session,
                maxHeight: wordListHeight,
              ),
            ),

            FoundWordToast(found: _session.lastFound),

            // Board — takes the remaining vertical space.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: ShakeOnChange(
                  trigger: _session.rejectionCounter,
                  child: _session.isReady
                      ? PuzzleBoard(
                          controller: _session,
                          accent: accent,
                          highContrast: settings.highContrastGrid,
                          largeLetters: settings.largeLetters,
                          onCellEntered: _onCellEntered,
                          onSelectionEnd: _onSelectionEnd,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // Hint bar.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: HintBar(
                coins: progress.coins,
                enabled: _session.status == GameStatus.playing,
                rewardedAvailable: ads.isRewardedReady,
                onHint: _useHint,
                onWatchAd: _watchRewardedAd,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPauseSheet() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _PauseSheet(
        onResume: () {
          Navigator.of(sheetContext).pop();
          _session.resume();
        },
        onRestart: () {
          Navigator.of(sheetContext).pop();
          _replay();
        },
        onQuit: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ===== HUD ================================================================

class _GameHud extends StatelessWidget {
  const _GameHud({
    required this.session,
    required this.level,
    required this.isDaily,
    required this.accent,
    required this.showTimer,
    required this.onBack,
    required this.onPause,
  });

  final GameSessionController session;
  final Level level;
  final bool isDaily;
  final Color accent;
  final bool showTimer;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();
    final remaining = session.remaining;

    // Countdown turns red in the last 15 seconds — the only alarming colour on
    // this screen, so it reads instantly.
    final timerColor = remaining != null && remaining.inSeconds <= 15
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              WqIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                size: 40,
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isDaily ? 'Daily Challenge' : level.displayNumber,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      level.theme,
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CoinChip(coins: progress.coins, compact: true),
              const SizedBox(width: 6),
              WqIconButton(
                icon: Icons.pause_rounded,
                tooltip: 'Pause',
                size: 40,
                onPressed: onPause,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Progress + timer strip.
          Row(
            children: [
              Text(
                '${session.foundWords.length}/'
                '${session.isReady ? session.puzzle.placedWords.length : 0}',
                style: AppTypography.numeric(
                  13,
                  theme.colorScheme.onSurfaceVariant,
                  FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: WqProgressBar(
                  value: session.completionRatio,
                  height: 7,
                  gradient: AppGradients.fromAccent(accent),
                ),
              ),
              if (showTimer) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  remaining != null
                      ? Icons.timer_rounded
                      : Icons.schedule_rounded,
                  size: 14,
                  color: timerColor,
                ),
                const SizedBox(width: 3),
                TimeReadout(
                  duration: remaining ?? session.elapsed,
                  color: timerColor,
                  size: 13,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Sheets & dialogs ===================================================

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Paused', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xl),
          WqButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
          ),
          const SizedBox(height: AppSpacing.md),
          WqButton.outlined(
            label: 'Restart level',
            icon: Icons.refresh_rounded,
            onPressed: onRestart,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onQuit,
            child: const Text('Quit to map'),
          ),
        ],
      ),
    );
  }
}

class _NotEnoughCoinsSheet extends StatelessWidget {
  const _NotEnoughCoinsSheet({
    required this.type,
    required this.canWatchAd,
    required this.onWatchAd,
    required this.onShop,
  });

  final HintType type;
  final bool canWatchAd;
  final VoidCallback onWatchAd;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(type.icon, size: 34, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You need ${type.cost} coins',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            type.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (canWatchAd) ...[
            WqButton(
              label: 'Watch an ad for 75 coins',
              icon: Icons.play_circle_fill_rounded,
              gradient: AppGradients.reward,
              onPressed: onWatchAd,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          WqButton.outlined(
            label: 'Open shop',
            icon: Icons.storefront_rounded,
            onPressed: onShop,
          ),
        ],
      ),
    );
  }
}

class _TimeUpView extends StatelessWidget {
  const _TimeUpView({
    required this.onRetry,
    required this.onExit,
    required this.onAddTime,
    required this.canWatchAd,
  });

  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback onAddTime;
  final bool canWatchAd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIn(
              child: Icon(
                Icons.timer_off_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("Time's up", style: theme.textTheme.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This one was a sprint. Want another go?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (canWatchAd) ...[
              WqButton(
                label: 'Watch ad for +30 seconds',
                icon: Icons.play_circle_fill_rounded,
                gradient: AppGradients.reward,
                expand: false,
                onPressed: onAddTime,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            WqButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: onRetry,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onExit, child: const Text('Back to map')),
          ],
        ),
      ),
    );
  }
}

class _DailyResultDialog extends StatelessWidget {
  const _DailyResultDialog({
    required this.streak,
    required this.coins,
    required this.isNewRecord,
    required this.elapsed,
    required this.onDone,
  });

  final int streak;
  final int coins;
  final bool isNewRecord;
  final Duration elapsed;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopIn(
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 58,
                color: AppPalette.orange,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Daily complete!', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              streak == 1
                  ? 'Streak started. Come back tomorrow to keep it going.'
                  : '$streak days in a row.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (isNewRecord) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'That is your longest streak yet!',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppPalette.mint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: AppPalette.amber,
                ),
                const SizedBox(width: 6),
                AnimatedCounter(
                  value: coins,
                  prefix: '+',
                  style: AppTypography.numeric(26, AppPalette.amber),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            WqButton(label: 'Nice!', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
