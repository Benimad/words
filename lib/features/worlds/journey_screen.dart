import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/content/level_catalog.dart';
import '../../data/models/world.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// The world map: eight regions connected by a winding trail.
///
/// The list is deliberately vertical and scrolls *upward* through the worlds,
/// with a connector drawn between cards. That gives the campaign a physical
/// shape — you can see how far you have come and how far is left, which a plain
/// grid of levels cannot convey.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Journey', style: theme.textTheme.displaySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Eight worlds, ${LevelCatalog.totalLevels} levels.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _OverallProgress(progress: progress),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  120,
                ),
                sliver: SliverList.builder(
                  itemCount: LevelCatalog.worlds.length,
                  itemBuilder: (context, index) {
                    final world = LevelCatalog.worlds[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 * index),
                      child: _WorldCard(
                        world: world,
                        isLast: index == LevelCatalog.worlds.length - 1,
                      ),
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

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.progress});
  final ProgressController progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = progress.progress;

    return WqCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          WqProgressRing(
            value: progress.campaignProgress,
            size: 54,
            color: theme.colorScheme.primary,
            strokeWidth: 5,
            child: Text(
              '${(progress.campaignProgress * 100).round()}%',
              style: AppTypography.numeric(13, theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player.levelsCompleted} levels cleared',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.totalStars} of ${LevelCatalog.totalLevels * 3} '
                  'stars collected',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One world, plus the trail connector beneath it.
class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world, required this.isLast});

  final World world;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();

    final unlocked = progress.isWorldUnlocked(world);
    final completed = progress.completedInWorld(world);
    final ratio = progress.worldProgress(world);
    final accent = AppPalette.worldAccents[world.paletteIndex];
    final isComplete = completed == world.levelCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WqCard(
          padding: EdgeInsets.zero,
          borderColor: unlocked
              ? accent.withValues(alpha: 0.4)
              : theme.colorScheme.outline,
          elevated: unlocked,
          onTap: unlocked
              ? () {
                  context.read<AudioService>().play(Sfx.button);
                  context.read<HapticService>().light();
                  Navigator.of(context).pushNamed(
                    Routes.worldLevels,
                    arguments: world,
                  );
                }
              : () {
                  // Locked worlds still respond — silence would read as a bug.
                  context.read<HapticService>().error();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Finish ${LevelCatalog.worlds[world.order - 1].name}'
                          ' to unlock ${world.name}.',
                        ),
                      ),
                    );
                },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Stack(
              children: [
                if (unlocked)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.22),
                            accent.withValues(alpha: 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // World marker.
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: unlocked
                              ? AppGradients.fromAccent(accent)
                              : null,
                          color: unlocked
                              ? null
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          boxShadow: unlocked
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                    spreadRadius: -4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: unlocked
                            ? Text(
                                world.emoji,
                                style: const TextStyle(fontSize: 26),
                              )
                            : Icon(
                                Icons.lock_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    world.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: unlocked
                                          ? null
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isComplete) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: accent,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unlocked
                                  ? world.tagline
                                  : 'Locked — keep going to reach it',
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (unlocked) ...[
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: WqProgressBar(
                                      value: ratio,
                                      height: 7,
                                      gradient:
                                          AppGradients.fromAccent(accent),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '$completed/${world.levelCount}',
                                    style: AppTypography.numeric(
                                      12,
                                      theme.colorScheme.onSurfaceVariant,
                                      FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (unlocked)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Trail connector to the next world.
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 45),
            child: SizedBox(
              height: 34,
              child: CustomPaint(
                painter: _TrailPainter(
                  color: unlocked && isComplete
                      ? accent
                      : theme.colorScheme.outline,
                  solid: unlocked && isComplete,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Dotted (locked) or solid (cleared) connector between world cards.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.color, required this.solid});

  final Color color;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (solid) {
      canvas.drawLine(Offset(0, 0), Offset(0, size.height), paint);
      return;
    }

    // Manual dashes — Flutter has no dashed-stroke primitive.
    const dash = 5.0;
    const gap = 5.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(0, (y + dash).clamp(0, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.color != color || old.solid != solid;
}
