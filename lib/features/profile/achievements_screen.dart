import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/content/achievements.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// Full achievements list.
///
/// Locked entries show *live progress* rather than a bare padlock — "18/25
/// levels" is a far stronger pull than "locked", because the player can see
/// exactly how close they are.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = context.watch<ProgressController>().progress;

    // Unlocked first, then in-progress by how close they are — the list
    // effectively sorts itself into "what to chase next".
    final sorted = [...Achievements.all]..sort((a, b) {
        final aDone = player.unlockedAchievements.contains(a.id);
        final bDone = player.unlockedAchievements.contains(b.id);
        if (aDone != bDone) return aDone ? -1 : 1;
        return b.progress(player).compareTo(a.progress(player));
      });

    final unlockedCount = Achievements.all
        .where((a) => player.unlockedAchievements.contains(a.id))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    WqIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievements',
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text(
                            '$unlockedCount of ${Achievements.all.length} '
                            'unlocked',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: WqProgressBar(
                  value: unlockedCount / Achievements.all.length,
                  height: 8,
                  gradient: AppGradients.reward,
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final achievement = sorted[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: (index * 35).clamp(0, 420)),
                      child: _AchievementTile(
                        achievement: achievement,
                        unlocked: player.unlockedAchievements
                            .contains(achievement.id),
                        progress: achievement.progress(player),
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

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  final Achievement achievement;
  final bool unlocked;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WqCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: unlocked ? AppPalette.amber.withValues(alpha: 0.45) : null,
      opacity: unlocked ? 0.78 : 0.5,
      child: Row(
        children: [
          WqProgressRing(
            value: unlocked ? 1 : progress,
            size: 50,
            strokeWidth: 4,
            color: unlocked ? AppPalette.amber : theme.colorScheme.primary,
            child: Icon(
              achievement.icon,
              size: 21,
              color: unlocked
                  ? AppPalette.amber
                  : theme.colorScheme.onSurfaceVariant,
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
                        achievement.title,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppPalette.mint,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall,
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${(progress * 100).round()}% complete',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 15,
                color: AppPalette.amber,
              ),
              const SizedBox(height: 2),
              Text(
                '${achievement.coinReward}',
                style: AppTypography.numeric(
                  12.5,
                  AppPalette.amber,
                  FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
