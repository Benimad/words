import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/content/daily_challenge.dart';
import '../../data/content/level_catalog.dart';
import '../../data/models/level.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/coin_chip.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// The hub screen.
///
/// Information hierarchy, top to bottom:
///  1. **Continue** — the single most likely action, as a big hero card.
///  2. **Daily challenge** — the return-tomorrow hook.
///  3. **Journey progress** — a sense of the long arc.
///  4. **Stats** — the numbers that make progress feel owned.
///
/// Nothing here requires a decision to start playing: one tap on the hero card
/// resumes exactly where the player left off.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Lets cards jump to a sibling tab in [HomeShell].
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final theme = Theme.of(context);
    final nextLevel = progress.nextLevel;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(progress: progress)),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  120, // clears the nav bar + banner
                ),
                sliver: SliverList.list(
                  children: [
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: _ContinueCard(
                        level: nextLevel,
                        progress: progress,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: _DailyCard(onOpen: () => onNavigate(2)),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    FadeSlideIn(
                      delay: const Duration(milliseconds: 220),
                      child: _JourneyCard(onOpen: () => onNavigate(1)),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: SectionHeader(
                        title: 'Your record',
                        subtitle: 'Everything you have found so far',
                        icon: Icons.insights_rounded,
                        action: TextButton(
                          onPressed: () => onNavigate(3),
                          child: const Text('Details'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 360),
                      child: _StatsRow(progress: progress),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 420),
                      child: _TipCard(theme: theme),
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

/// Greeting, player rank and the coin balance.
class _Header extends StatelessWidget {
  const _Header({required this.progress});

  final ProgressController progress;

  /// Time-of-day greeting — a small touch that makes the app feel aware of
  /// the player rather than static.
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up?';
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = progress.progress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Explorer', style: theme.textTheme.headlineMedium),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        'Lv ${player.playerLevel}',
                        style: AppTypography.numeric(11.5, Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CoinChip(
            coins: progress.coins,
            onTap: () {
              context.read<AudioService>().play(Sfx.button);
              Navigator.of(context).pushNamed(Routes.shop);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          WqIconButton(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            size: 40,
            onPressed: () {
              context.read<AudioService>().play(Sfx.button);
              Navigator.of(context).pushNamed(Routes.settings);
            },
          ),
        ],
      ),
    );
  }
}

/// The hero "keep playing" card.
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.level, required this.progress});

  final Level? level;
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Campaign finished — celebrate instead of showing a dead card.
    if (level == null) {
      return WqCard(
        gradient: AppGradients.reward,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 34)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Campaign complete',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have cleared all 240 levels. The Daily Challenge is '
              'still waiting for you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      );
    }

    final world = LevelCatalog.worldForLevel(level!);
    final accent = AppPalette.worldAccents[world.paletteIndex];
    final isNewPlayer = progress.progress.levelsCompleted == 0;

    return WqCard(
      padding: EdgeInsets.zero,
      elevated: true,
      borderColor: accent.withValues(alpha: 0.35),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Stack(
          children: [
            // Accent wash behind the content.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.26),
                      accent.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        world.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              world.name.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              isNewPlayer
                                  ? 'Start your journey'
                                  : level!.displayNumber,
                              style: theme.textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                      _DifficultyBadge(level: level!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.category_rounded,
                        label: level!.theme,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _MetaChip(
                        icon: Icons.grid_4x4_rounded,
                        label: '${level!.rows}×${level!.cols}',
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _MetaChip(
                        icon: Icons.search_rounded,
                        label: '${level!.wordCount} words',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Breathing draws the eye to the primary action without
                  // resorting to a flashing colour.
                  Breathe(
                    child: WqButton(
                      label: isNewPlayer ? 'Play level 1' : 'Continue',
                      icon: Icons.play_arrow_rounded,
                      gradient: AppGradients.fromAccent(accent),
                      onPressed: () {
                        context.read<AudioService>().play(Sfx.button);
                        context.read<HapticService>().light();
                        Navigator.of(context).pushNamed(
                          Routes.game,
                          arguments: GameArgs(level: level!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.level});
  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        level.difficulty.label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily challenge teaser with the current streak.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();
    final done = progress.hasCompletedTodaysDaily;
    final streak = progress.displayStreak;
    final level = DailyChallenge.today;

    return WqCard(
      onTap: onOpen,
      gradient: done
          ? null
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9A3C), Color(0xFFFF6B6B)],
            ),
      borderColor: done ? null : Colors.transparent,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: done
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.local_fire_department_rounded,
              color: done ? AppPalette.mint : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Daily complete' : 'Daily Challenge',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: done ? null : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? streak > 0
                          ? '$streak day streak — come back tomorrow'
                          : 'See you tomorrow'
                      : 'Today: ${level.theme}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: done
                        ? null
                        : Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: done
                    ? AppPalette.amber.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 14,
                    color: done ? AppPalette.amber : Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$streak',
                    style: AppTypography.numeric(
                      13,
                      done ? AppPalette.amber : Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            Icon(
              Icons.chevron_right_rounded,
              color: done
                  ? theme.colorScheme.onSurfaceVariant
                  : Colors.white,
            ),
        ],
      ),
    );
  }
}

/// Campaign-wide progress summary.
class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();
    final completed = progress.progress.levelsCompleted;
    final currentWorld = LevelCatalog.worlds[
        (progress.progress.highestUnlockedIndex ~/ LevelCatalog.levelsPerWorld)
            .clamp(0, LevelCatalog.worlds.length - 1)];

    return WqCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Your journey', style: theme.textTheme.titleLarge),
              ),
              Text(
                '$completed / ${LevelCatalog.totalLevels}',
                style: AppTypography.numeric(
                  14,
                  theme.colorScheme.onSurfaceVariant,
                  FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WqProgressBar(value: progress.campaignProgress, height: 9),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(currentWorld.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Currently exploring ${currentWorld.name}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'View map',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.progress});
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final player = progress.progress;
    return Row(
      children: [
        Expanded(
          child: StatPill(
            icon: Icons.star_rounded,
            value: '${player.totalStars}',
            label: 'Stars',
            color: AppPalette.amber,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatPill(
            icon: Icons.search_rounded,
            value: '${player.totalWordsFound}',
            label: 'Words found',
            color: AppPalette.teal,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatPill(
            icon: Icons.local_fire_department_rounded,
            value: '${player.longestStreak}',
            label: 'Best streak',
            color: AppPalette.orange,
          ),
        ),
      ],
    );
  }
}

/// A rotating gameplay tip. Changes daily rather than per build, so it does not
/// flicker between rebuilds but still feels fresh over time.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.theme});
  final ThemeData theme;

  static const _tips = [
    'Words can run backwards — try swiping right-to-left when you are stuck.',
    'Scan for unusual letters first: J, Q, X and Z narrow things down fast.',
    'You only need to touch the first and last letter — the line fills itself.',
    'Clear Clutter is the best value hint on a big, crowded board.',
    'Three stars means no hints and a finish inside par time.',
    'Long words are easiest to spot: look along the diagonals first.',
    'Keep your daily streak alive — the bonus grows every single day.',
  ];

  @override
  Widget build(BuildContext context) {
    final tip = _tips[DateTime.now().day % _tips.length];

    return WqCard(
      opacity: 0.45,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_rounded,
            size: 19,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIP OF THE DAY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(tip, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
