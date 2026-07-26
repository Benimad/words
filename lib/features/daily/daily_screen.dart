import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../data/content/daily_challenge.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/haptic_service.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/entrance.dart';
import '../../shared/widgets/wq_button.dart';
import '../../shared/widgets/wq_surfaces.dart';
import '../../state/progress_controller.dart';

/// The Daily Challenge tab.
///
/// The screen's whole job is to make *tomorrow* feel worth showing up for, so
/// the streak is the hero element and the reward ladder is visible before the
/// player has earned any of it.
class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key, this.embedded = false});

  /// True when hosted inside [HomeShell] (no back button, extra bottom pad).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = context.watch<ProgressController>();

    final level = DailyChallenge.today;
    final done = progress.hasCompletedTodaysDaily;
    final streak = progress.displayStreak;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        accents: const [AppPalette.orange, AppPalette.amber, AppPalette.rose],
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              embedded ? 120 : AppSpacing.xl,
            ),
            children: [
              if (!embedded)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: WqIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

              FadeSlideIn(
                child: Text(
                  'Daily Challenge',
                  style: theme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 4),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: Text(
                  'One fresh puzzle every day. Same board for everyone.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Streak hero ------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: _StreakHero(
                  streak: streak,
                  longest: progress.progress.longestStreak,
                  atRisk: progress.isStreakAtRisk && !done,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- Week strip -------------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _WeekStrip(
                  completedDates: progress.progress.completedDailyDates,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // --- Today's puzzle ---------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: WqCard(
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.orange.withValues(alpha: 0.16),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Text(
                              _formattedDate(DateTime.now()),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppPalette.orange,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (done)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppPalette.mint,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(level.theme, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        '${level.rows}×${level.cols} board · '
                        '${level.wordCount} words · all eight directions',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (done)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppPalette.mint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Solved for today',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppPalette.mint,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'The next challenge unlocks at midnight.',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Breathe(
                          child: WqButton(
                            label: 'Play today\'s puzzle',
                            icon: Icons.play_arrow_rounded,
                            gradient: const LinearGradient(
                              colors: [
                                AppPalette.orange,
                                AppPalette.coral,
                              ],
                            ),
                            onPressed: () {
                              context.read<AudioService>().play(Sfx.button);
                              context.read<HapticService>().light();
                              Navigator.of(context).pushNamed(
                                Routes.game,
                                arguments: GameArgs(
                                  level: level,
                                  isDaily: true,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // --- Reward ladder ----------------------------------------
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: const SectionHeader(
                  title: 'Streak rewards',
                  subtitle: 'The longer you keep it up, the more you earn',
                  icon: Icons.emoji_events_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: _RewardLadder(currentStreak: streak),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formattedDate(DateTime date) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.streak,
    required this.longest,
    required this.atRisk,
  });

  final int streak;
  final int longest;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WqCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8A3D), Color(0xFFFF5F6D)],
      ),
      borderColor: Colors.transparent,
      child: Row(
        children: [
          Breathe(
            scale: 0.06,
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 54,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streak',
                      style: AppTypography.numeric(42, Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      streak == 1 ? 'day' : 'days',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
                Text(
                  atRisk
                      ? 'Play today to keep your streak alive!'
                      : longest > 0
                          ? 'Your best: $longest days'
                          : 'Start a streak today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: atRisk ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven-day completion strip.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.completedDates});

  final Set<String> completedDates;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = DailyChallenge.recentWeek();
    final today = DateTime.now();

    return WqCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final day in days)
            Builder(
              builder: (context) {
                final done =
                    completedDates.contains(DailyChallenge.dateKey(day));
                final isToday = day.day == today.day &&
                    day.month == today.month &&
                    day.year == today.year;

                return Column(
                  children: [
                    Text(
                      _weekdayLabels[day.weekday - 1],
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: AppDurations.normal,
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done
                            ? AppPalette.orange
                            : theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Icon(
                        done
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 15,
                        color: done
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Shows what each streak milestone pays, with the current position marked.
class _RewardLadder extends StatelessWidget {
  const _RewardLadder({required this.currentStreak});

  final int currentStreak;

  /// Mirrors the formula in `ProgressController.completeDailyChallenge`:
  /// 50 + min(streak, 14) * 10.
  static const _milestones = [1, 3, 7, 14, 30];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WqCard(
      child: Column(
        children: [
          for (var i = 0; i < _milestones.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == _milestones.length - 1 ? 0 : AppSpacing.md,
              ),
              child: Builder(
                builder: (context) {
                  final milestone = _milestones[i];
                  final reached = currentStreak >= milestone;
                  final coins = 50 + milestone.clamp(1, 14) * 10;

                  return Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: reached
                              ? AppPalette.orange
                              : theme.colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: reached
                            ? const Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: Colors.white,
                              )
                            : Text(
                                '$milestone',
                                style: AppTypography.numeric(
                                  13,
                                  theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          milestone == 1
                              ? 'First day'
                              : '$milestone day streak',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: reached
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                reached ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            size: 15,
                            color: AppPalette.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$coins',
                            style: AppTypography.numeric(
                              14,
                              AppPalette.amber,
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
