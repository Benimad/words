import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/content/achievements.dart';
import '../../data/content/level_catalog.dart';
import '../../data/models/world.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/coin_chip.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// Player profile: rank, lifetime stats, per-world completion and a preview of
/// achievements.
///
/// This screen exists purely for retention. Numbers that only ever go up give
/// players a reason to keep the app installed even when they are not chasing
/// the next level.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ProgressController>();
    final player = controller.progress;

    final unlockedAchievements = Achievements.all
        .where((a) => player.unlockedAchievements.contains(a.id))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              120,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  CoinChip(
                    coins: controller.coins,
                    onTap: () =>
                        Navigator.of(context).pushNamed(Routes.shop),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  WqIconButton(
                    icon: Icons.settings_rounded,
                    size: 40,
                    tooltip: 'Settings',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.settings),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- Rank card --------------------------------------------
              FadeSlideIn(
                child: WqCard(
                  elevated: true,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              gradient: AppGradients.brand,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${player.playerLevel}',
                              style: AppTypography.numeric(26, Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rankTitle(player.playerLevel),
                                  style: theme.textTheme.headlineSmall,
                                ),
                                Text(
                                  'Level ${player.playerLevel} explorer',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      WqProgressBar(value: player.levelProgress, height: 8),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(player.levelProgress * 100).round()}% to next '
                          'rank',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // --- Lifetime stats ---------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: const SectionHeader(
                  title: 'Lifetime stats',
                  icon: Icons.query_stats_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.92,
                  children: [
                    StatPill(
                      icon: Icons.check_circle_rounded,
                      value: '${player.levelsCompleted}',
                      label: 'Levels',
                      color: AppPalette.mint,
                    ),
                    StatPill(
                      icon: Icons.star_rounded,
                      value: '${player.totalStars}',
                      label: 'Stars',
                      color: AppPalette.amber,
                    ),
                    StatPill(
                      icon: Icons.search_rounded,
                      value: '${player.totalWordsFound}',
                      label: 'Words',
                      color: AppPalette.teal,
                    ),
                    StatPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '${player.longestStreak}',
                      label: 'Best streak',
                      color: AppPalette.orange,
                    ),
                    StatPill(
                      icon: Icons.workspace_premium_rounded,
                      value: '${player.perfectLevels}',
                      label: '3-star runs',
                      color: AppPalette.violetLight,
                    ),
                    StatPill(
                      icon: Icons.schedule_rounded,
                      value: _formatPlayTime(player.totalPlaySeconds),
                      label: 'Time played',
                      color: AppPalette.sky,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // --- Achievements preview ---------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: SectionHeader(
                  title: 'Achievements',
                  subtitle:
                      '$unlockedAchievements of ${Achievements.all.length} '
                      'unlocked',
                  icon: Icons.emoji_events_rounded,
                  action: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.achievements),
                    child: const Text('See all'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: Achievements.all.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final achievement = Achievements.all[index];
                      final unlocked = player.unlockedAchievements
                          .contains(achievement.id);
                      return _AchievementBadge(
                        icon: achievement.icon,
                        title: achievement.title,
                        unlocked: unlocked,
                        progress: achievement.progress(player),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // --- Worlds -----------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: const SectionHeader(
                  title: 'World completion',
                  icon: Icons.public_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < LevelCatalog.worlds.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 300 + i * 40),
                    child: _WorldProgressRow(
                      world: LevelCatalog.worlds[i],
                      controller: controller,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A flavour title that changes as the player ranks up — cheap to implement,
  /// and it gives XP a meaning beyond a number.
  static String _rankTitle(int level) {
    if (level >= 40) return 'Grand Lexicographer';
    if (level >= 30) return 'Master Cartographer';
    if (level >= 22) return 'Word Sage';
    if (level >= 15) return 'Pathfinder';
    if (level >= 10) return 'Seasoned Seeker';
    if (level >= 5) return 'Trail Scout';
    return 'Novice Explorer';
  }

  static String _formatPlayTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h ${minutes % 60}m';
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.icon,
    required this.title,
    required this.unlocked,
    required this.progress,
  });

  final IconData icon;
  final String title;
  final bool unlocked;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 86,
      child: Column(
        children: [
          WqProgressRing(
            value: unlocked ? 1 : progress,
            size: 58,
            strokeWidth: 4,
            color: unlocked ? AppPalette.amber : theme.colorScheme.primary,
            child: Icon(
              icon,
              size: 24,
              color: unlocked
                  ? AppPalette.amber
                  : theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: unlocked ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldProgressRow extends StatelessWidget {
  const _WorldProgressRow({required this.world, required this.controller});

  final World world;
  final ProgressController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppPalette.worldAccents[world.paletteIndex];
    final completed = controller.completedInWorld(world);
    final unlocked = controller.isWorldUnlocked(world);

    return WqCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      opacity: unlocked ? 0.7 : 0.35,
      child: Row(
        children: [
          Text(
            unlocked ? world.emoji : '🔒',
            style: const TextStyle(fontSize: 19),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  world.name,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 5),
                WqProgressBar(
                  value: controller.worldProgress(world),
                  height: 6,
                  gradient: AppGradients.fromAccent(accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$completed/${world.levelCount}',
            style: AppTypography.numeric(
              12.5,
              theme.colorScheme.onSurfaceVariant,
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
