import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/level.dart';
import '../../data/models/world.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/coin_chip.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// Level select for one world.
///
/// Uses a staggered grid of level tiles rather than a list: 30 levels fit on
/// roughly one and a half screens, so the player can see the whole region at a
/// glance and jump to any cleared level to improve their stars.
class WorldLevelsScreen extends StatelessWidget {
  const WorldLevelsScreen({super.key, required this.world});

  final World world;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();
    final accent = AppPalette.worldAccents[world.paletteIndex];

    final completed = progress.completedInWorld(world);
    final stars = progress.starsInWorld(world);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        accents: [accent, Color.lerp(accent, AppPalette.violet, 0.45)!],
        child: SafeArea(
          child: Column(
            children: [
              // --- Header ------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    WqIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      size: 42,
                      onPressed: () {
                        context.read<AudioService>().play(Sfx.button);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                world.emoji,
                                style: const TextStyle(fontSize: 19),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  world.name,
                                  style: theme.textTheme.headlineSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '$completed of ${world.levelCount} cleared · '
                            '$stars ★',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    CoinChip(
                      coins: progress.coins,
                      compact: true,
                      onTap: () =>
                          Navigator.of(context).pushNamed(Routes.shop),
                    ),
                  ],
                ),
              ),

              // --- Progress ----------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: WqProgressBar(
                  value: progress.worldProgress(world),
                  height: 8,
                  gradient: AppGradients.fromAccent(accent),
                ),
              ),

              // --- Level grid --------------------------------------------
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.huge,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.86,
                  ),
                  itemCount: world.levels.length,
                  itemBuilder: (context, index) {
                    final level = world.levels[index];
                    return FadeSlideIn(
                      // Cap the stagger so late tiles are not left waiting.
                      delay: Duration(milliseconds: (index * 22).clamp(0, 420)),
                      offset: const Offset(0, 0.18),
                      child: _LevelTile(level: level, accent: accent),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single level tile: number, stars, and lock/timed indicators.
class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.accent});

  final Level level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();

    final unlocked = progress.isLevelUnlocked(level);
    final result = progress.progress.resultFor(level.id);
    final isDone = result != null;
    // The next level to play gets a highlighted ring.
    final isCurrent = unlocked &&
        !isDone &&
        progress.progress.highestUnlockedIndex == level.globalIndex;

    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          context.read<HapticService>().error();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Clear the earlier levels first.')),
            );
          return;
        }
        context.read<AudioService>().play(Sfx.button);
        context.read<HapticService>().light();
        Navigator.of(context).pushNamed(
          Routes.game,
          arguments: GameArgs(level: level),
        );
      },
      child: AnimatedContainer(
        duration: AppDurations.normal,
        decoration: BoxDecoration(
          gradient: isDone ? AppGradients.fromAccent(accent) : null,
          color: isDone
              ? null
              : unlocked
                  ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.8)
                  : theme.colorScheme.surfaceContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isCurrent
                ? accent
                : isDone
                    ? Colors.transparent
                    : theme.colorScheme.outline,
            width: isCurrent ? 2.2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!unlocked)
                    Icon(
                      Icons.lock_rounded,
                      size: 19,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    )
                  else
                    Text(
                      '${level.indexInWorld + 1}',
                      style: AppTypography.numeric(
                        20,
                        isDone ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  if (unlocked) ...[
                    const SizedBox(height: 4),
                    StarRow(
                      stars: result?.stars ?? 0,
                      size: 11,
                      color: isDone ? Colors.white : null,
                    ),
                  ],
                ],
              ),
            ),

            // Timed-level marker.
            if (level.isTimed && unlocked)
              Positioned(
                top: 5,
                right: 5,
                child: Icon(
                  Icons.timer_rounded,
                  size: 12,
                  color: isDone
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppPalette.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
