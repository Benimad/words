import 'package:flutter/material.dart';

import '../models/player_progress.dart';

/// A long-term goal shown on the profile screen.
///
/// Achievements exist to give players a reason to return beyond "the next
/// level": they reward breadth (many worlds), depth (perfect runs) and habit
/// (streaks), so different play styles all have something to chase.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.coinReward,
    required this.isUnlocked,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int coinReward;

  /// Predicate evaluated against the player's saved progress.
  final bool Function(PlayerProgress) isUnlocked;

  /// 0-1 completion, used to draw the progress ring.
  final double Function(PlayerProgress) progress;
}

abstract final class Achievements {
  static double _ratio(num value, num target) =>
      target == 0 ? 0 : (value / target).clamp(0.0, 1.0);

  static final List<Achievement> all = [
    Achievement(
      id: 'first-steps',
      title: 'First Steps',
      description: 'Complete your first level.',
      icon: Icons.flag_rounded,
      coinReward: 25,
      isUnlocked: (p) => p.levelsCompleted >= 1,
      progress: (p) => _ratio(p.levelsCompleted, 1),
    ),
    Achievement(
      id: 'word-hunter',
      title: 'Word Hunter',
      description: 'Find 100 words in total.',
      icon: Icons.search_rounded,
      coinReward: 50,
      isUnlocked: (p) => p.totalWordsFound >= 100,
      progress: (p) => _ratio(p.totalWordsFound, 100),
    ),
    Achievement(
      id: 'lexicon',
      title: 'Living Lexicon',
      description: 'Find 1,000 words in total.',
      icon: Icons.menu_book_rounded,
      coinReward: 200,
      isUnlocked: (p) => p.totalWordsFound >= 1000,
      progress: (p) => _ratio(p.totalWordsFound, 1000),
    ),
    Achievement(
      id: 'explorer',
      title: 'Explorer',
      description: 'Complete 25 levels.',
      icon: Icons.explore_rounded,
      coinReward: 75,
      isUnlocked: (p) => p.levelsCompleted >= 25,
      progress: (p) => _ratio(p.levelsCompleted, 25),
    ),
    Achievement(
      id: 'cartographer',
      title: 'Cartographer',
      description: 'Complete 100 levels.',
      icon: Icons.map_rounded,
      coinReward: 250,
      isUnlocked: (p) => p.levelsCompleted >= 100,
      progress: (p) => _ratio(p.levelsCompleted, 100),
    ),
    Achievement(
      id: 'flawless',
      title: 'Flawless',
      description: 'Earn 3 stars on 10 levels.',
      icon: Icons.star_rounded,
      coinReward: 100,
      isUnlocked: (p) => p.perfectLevels >= 10,
      progress: (p) => _ratio(p.perfectLevels, 10),
    ),
    Achievement(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Earn 3 stars on 50 levels.',
      icon: Icons.workspace_premium_rounded,
      coinReward: 300,
      isUnlocked: (p) => p.perfectLevels >= 50,
      progress: (p) => _ratio(p.perfectLevels, 50),
    ),
    Achievement(
      id: 'streak-3',
      title: 'Getting Into It',
      description: 'Reach a 3-day daily streak.',
      icon: Icons.local_fire_department_rounded,
      coinReward: 50,
      isUnlocked: (p) => p.longestStreak >= 3,
      progress: (p) => _ratio(p.longestStreak, 3),
    ),
    Achievement(
      id: 'streak-7',
      title: 'Week Warrior',
      description: 'Reach a 7-day daily streak.',
      icon: Icons.whatshot_rounded,
      coinReward: 150,
      isUnlocked: (p) => p.longestStreak >= 7,
      progress: (p) => _ratio(p.longestStreak, 7),
    ),
    Achievement(
      id: 'streak-30',
      title: 'Unbreakable',
      description: 'Reach a 30-day daily streak.',
      icon: Icons.military_tech_rounded,
      coinReward: 500,
      isUnlocked: (p) => p.longestStreak >= 30,
      progress: (p) => _ratio(p.longestStreak, 30),
    ),
    Achievement(
      id: 'self-reliant',
      title: 'Self-Reliant',
      description: 'Complete 20 levels without using a single hint.',
      icon: Icons.psychology_rounded,
      coinReward: 150,
      isUnlocked: (p) =>
          p.results.values.where((r) => r.hintsUsed == 0).length >= 20,
      progress: (p) => _ratio(
        p.results.values.where((r) => r.hintsUsed == 0).length,
        20,
      ),
    ),
    Achievement(
      id: 'star-collector',
      title: 'Star Collector',
      description: 'Collect 150 stars.',
      icon: Icons.auto_awesome_rounded,
      coinReward: 250,
      isUnlocked: (p) => p.totalStars >= 150,
      progress: (p) => _ratio(p.totalStars, 150),
    ),
    Achievement(
      id: 'world-traveller',
      title: 'World Traveller',
      description: 'Reach Starfall Rift.',
      icon: Icons.travel_explore_rounded,
      coinReward: 200,
      isUnlocked: (p) => p.highestUnlockedIndex >= 180,
      progress: (p) => _ratio(p.highestUnlockedIndex, 180),
    ),
    Achievement(
      id: 'chronicler',
      title: 'Chronicler',
      description: 'Complete every level in the campaign.',
      icon: Icons.emoji_events_rounded,
      coinReward: 1000,
      isUnlocked: (p) => p.levelsCompleted >= 240,
      progress: (p) => _ratio(p.levelsCompleted, 240),
    ),
  ];

  /// Achievements that [progress] satisfies but which have not yet been
  /// awarded. The controller uses this to grant coins exactly once.
  static List<Achievement> newlyUnlocked(PlayerProgress progress) => all
      .where((a) =>
          a.isUnlocked(progress) && !progress.unlockedAchievements.contains(a.id))
      .toList();
}
