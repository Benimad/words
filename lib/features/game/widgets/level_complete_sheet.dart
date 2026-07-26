import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/celebration_overlay.dart';
import '../../../shared/widgets/coin_chip.dart';
import '../../../shared/widgets/entrance.dart';
import '../../../shared/widgets/wq_button.dart';
import '../../../shared/widgets/wq_surfaces.dart';
import '../../../state/progress_controller.dart';

/// What the player chose on the results screen.
enum LevelCompleteAction { nextLevel, replay, home }

/// The celebration screen shown after a level is cleared.
///
/// The sequence is choreographed rather than shown all at once:
/// confetti → medal pops → stars land one by one → reward rows count up →
/// buttons fade in last. Roughly 1.6s end to end, which is long enough to feel
/// like a reward and short enough that a player grinding levels is not held up.
class LevelCompleteSheet extends StatelessWidget {
  const LevelCompleteSheet({
    super.key,
    required this.completion,
    required this.accent,
    required this.hasNextLevel,
    required this.onAction,
  });

  final LevelCompletion completion;
  final Color accent;
  final bool hasNextLevel;
  final ValueChanged<LevelCompleteAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = completion.score;

    return Stack(
      children: [
        // Confetti sits behind the card so it never obscures the numbers.
        Positioned.fill(
          child: CelebrationOverlay(
            play: true,
            particleCount: score.stars >= 3 ? 120 : 80,
          ),
        ),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Medal --------------------------------------------
                    PopIn(
                      delay: const Duration(milliseconds: 120),
                      child: PulseRing(
                        color: accent,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: AppGradients.fromAccent(accent),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 34,
                                spreadRadius: -6,
                              ),
                            ],
                          ),
                          child: Icon(
                            score.stars >= 3
                                ? Icons.emoji_events_rounded
                                : Icons.check_rounded,
                            size: 46,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // --- Title --------------------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: Text(
                        _title(score.stars),
                        style: theme.textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 320),
                      child: Text(
                        '${completion.level.theme} · '
                        '${completion.level.displayNumber}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // --- Stars --------------------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 380),
                      child: StarRow(
                        stars: score.stars,
                        size: 42,
                        animate: true,
                        color: AppPalette.amber,
                      ),
                    ),

                    if (completion.isNewBest) ...[
                      const SizedBox(height: AppSpacing.sm),
                      PopIn(
                        delay: const Duration(milliseconds: 700),
                        child: _Badge(
                          label: 'New personal best',
                          icon: Icons.trending_up_rounded,
                          color: AppPalette.mint,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // --- Reward breakdown ---------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 520),
                      child: WqCard(
                        elevated: true,
                        child: Column(
                          children: [
                            _RewardRow(
                              label: 'Level reward',
                              value: score.baseCoins,
                              icon: Icons.flag_rounded,
                            ),
                            if (score.speedBonus > 0)
                              _RewardRow(
                                label: 'Speed bonus',
                                value: score.speedBonus,
                                icon: Icons.bolt_rounded,
                              ),
                            if (score.noHintBonus > 0)
                              _RewardRow(
                                label: 'No hints used',
                                value: score.noHintBonus,
                                icon: Icons.psychology_rounded,
                              ),
                            if (score.streakBonus > 0)
                              _RewardRow(
                                label: 'Streak bonus',
                                value: score.streakBonus,
                                icon: Icons.local_fire_department_rounded,
                              ),
                            if (!completion.isFirstClear)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.sm),
                                child: Text(
                                  'Replays pay a reduced reward.',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              child: Divider(height: 1),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Total earned',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Icon(
                                  Icons.monetization_on_rounded,
                                  size: 20,
                                  color: AppPalette.amber,
                                ),
                                const SizedBox(width: 5),
                                AnimatedCounter(
                                  value: completion.isFirstClear
                                      ? score.totalCoins
                                      : score.baseCoins ~/ 3,
                                  duration:
                                      const Duration(milliseconds: 900),
                                  style: AppTypography.numeric(
                                    22,
                                    AppPalette.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Achievements unlocked ----------------------------
                    if (completion.unlockedAchievements.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      for (final achievement
                          in completion.unlockedAchievements)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: PopIn(
                            delay: const Duration(milliseconds: 820),
                            child: WqCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              borderColor:
                                  AppPalette.amber.withValues(alpha: 0.5),
                              child: Row(
                                children: [
                                  Icon(
                                    achievement.icon,
                                    color: AppPalette.amber,
                                    size: 22,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Achievement unlocked',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: AppPalette.amber,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Text(
                                          achievement.title,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${achievement.coinReward}',
                                    style: AppTypography.numeric(
                                      15,
                                      AppPalette.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],

                    // --- World unlocked -----------------------------------
                    if (completion.unlockedWorld != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      PopIn(
                        delay: const Duration(milliseconds: 900),
                        child: WqCard(
                          gradient: AppGradients.fromAccent(
                            AppPalette.worldAccents[
                                completion.unlockedWorld!.paletteIndex],
                          ),
                          child: Row(
                            children: [
                              Text(
                                completion.unlockedWorld!.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEW WORLD UNLOCKED',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    Text(
                                      completion.unlockedWorld!.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // --- Actions ------------------------------------------
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 980),
                      child: Column(
                        children: [
                          if (hasNextLevel)
                            WqButton(
                              label: 'Next level',
                              icon: Icons.arrow_forward_rounded,
                              gradient: AppGradients.fromAccent(accent),
                              onPressed: () =>
                                  onAction(LevelCompleteAction.nextLevel),
                            )
                          else
                            WqButton(
                              label: 'Back to map',
                              icon: Icons.map_rounded,
                              gradient: AppGradients.fromAccent(accent),
                              onPressed: () =>
                                  onAction(LevelCompleteAction.home),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: WqButton.outlined(
                                  label: 'Replay',
                                  icon: Icons.refresh_rounded,
                                  height: 50,
                                  onPressed: () =>
                                      onAction(LevelCompleteAction.replay),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: WqButton.outlined(
                                  label: 'Home',
                                  icon: Icons.home_rounded,
                                  height: 50,
                                  onPressed: () =>
                                      onAction(LevelCompleteAction.home),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _title(int stars) => switch (stars) {
        3 => 'Flawless!',
        2 => 'Well done!',
        _ => 'Level complete',
      };
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '+$value',
            style: AppTypography.numeric(
              14,
              theme.colorScheme.onSurface,
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
