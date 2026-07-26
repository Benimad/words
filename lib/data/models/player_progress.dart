import 'package:flutter/foundation.dart';

import 'level_result.dart';

/// Everything the game remembers about a player between sessions.
///
/// Immutable with [copyWith] so state updates are explicit and easy to reason
/// about; the repository serialises the whole object to a single JSON blob.
@immutable
class PlayerProgress {
  const PlayerProgress({
    this.coins = kStartingCoins,
    this.highestUnlockedIndex = 0,
    this.results = const {},
    this.dailyStreak = 0,
    this.longestStreak = 0,
    this.lastDailyDate,
    this.completedDailyDates = const {},
    this.totalWordsFound = 0,
    this.totalPlaySeconds = 0,
    this.hintsUsedLifetime = 0,
    this.isPremium = false,
    this.hasCompletedOnboarding = false,
    this.unlockedAchievements = const {},
    this.lastSeenWorldUnlock = 0,
    this.experience = 0,
  });

  /// A small starting purse so a new player can try hints immediately.
  static const kStartingCoins = 150;

  final int coins;

  /// Global index of the furthest level the player may enter. Every level with
  /// `globalIndex <= highestUnlockedIndex` is playable.
  final int highestUnlockedIndex;

  /// Best result per level id.
  final Map<String, LevelResult> results;

  final int dailyStreak;
  final int longestStreak;

  /// Date-only (midnight local) of the most recent completed daily challenge.
  final DateTime? lastDailyDate;

  /// `yyyy-MM-dd` keys of every completed daily, for the calendar view.
  final Set<String> completedDailyDates;

  final int totalWordsFound;
  final int totalPlaySeconds;
  final int hintsUsedLifetime;

  /// True once the "remove ads" purchase has been made.
  final bool isPremium;
  final bool hasCompletedOnboarding;

  final Set<String> unlockedAchievements;

  /// Highest world order for which the unlock celebration has been shown, so
  /// the animation plays exactly once.
  final int lastSeenWorldUnlock;

  /// Drives the player level / rank shown on the profile.
  final int experience;

  int get levelsCompleted => results.length;

  int get totalStars =>
      results.values.fold(0, (sum, result) => sum + result.stars);

  int get perfectLevels => results.values.where((r) => r.isPerfect).length;

  /// Player rank derived from XP with a gently increasing curve, so early ranks
  /// come quickly and later ones feel earned.
  int get playerLevel {
    var level = 1;
    var required = 100;
    var remaining = experience;
    while (remaining >= required && level < 999) {
      remaining -= required;
      level++;
      required = (required * 1.18).round();
    }
    return level;
  }

  /// Progress (0-1) toward the next rank.
  double get levelProgress {
    var level = 1;
    var required = 100;
    var remaining = experience;
    while (remaining >= required && level < 999) {
      remaining -= required;
      level++;
      required = (required * 1.18).round();
    }
    return required == 0 ? 0 : (remaining / required).clamp(0.0, 1.0);
  }

  bool isLevelUnlocked(int globalIndex) => globalIndex <= highestUnlockedIndex;

  bool isLevelCompleted(String levelId) => results.containsKey(levelId);

  LevelResult? resultFor(String levelId) => results[levelId];

  PlayerProgress copyWith({
    int? coins,
    int? highestUnlockedIndex,
    Map<String, LevelResult>? results,
    int? dailyStreak,
    int? longestStreak,
    DateTime? lastDailyDate,
    Set<String>? completedDailyDates,
    int? totalWordsFound,
    int? totalPlaySeconds,
    int? hintsUsedLifetime,
    bool? isPremium,
    bool? hasCompletedOnboarding,
    Set<String>? unlockedAchievements,
    int? lastSeenWorldUnlock,
    int? experience,
  }) =>
      PlayerProgress(
        coins: coins ?? this.coins,
        highestUnlockedIndex: highestUnlockedIndex ?? this.highestUnlockedIndex,
        results: results ?? this.results,
        dailyStreak: dailyStreak ?? this.dailyStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastDailyDate: lastDailyDate ?? this.lastDailyDate,
        completedDailyDates: completedDailyDates ?? this.completedDailyDates,
        totalWordsFound: totalWordsFound ?? this.totalWordsFound,
        totalPlaySeconds: totalPlaySeconds ?? this.totalPlaySeconds,
        hintsUsedLifetime: hintsUsedLifetime ?? this.hintsUsedLifetime,
        isPremium: isPremium ?? this.isPremium,
        hasCompletedOnboarding:
            hasCompletedOnboarding ?? this.hasCompletedOnboarding,
        unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
        lastSeenWorldUnlock: lastSeenWorldUnlock ?? this.lastSeenWorldUnlock,
        experience: experience ?? this.experience,
      );

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'unlocked': highestUnlockedIndex,
        'results': results.map((k, v) => MapEntry(k, v.toJson())),
        'streak': dailyStreak,
        'longestStreak': longestStreak,
        'lastDaily': lastDailyDate?.toIso8601String(),
        'dailyDates': completedDailyDates.toList(),
        'words': totalWordsFound,
        'seconds': totalPlaySeconds,
        'hints': hintsUsedLifetime,
        'premium': isPremium,
        'onboarded': hasCompletedOnboarding,
        'achievements': unlockedAchievements.toList(),
        'worldUnlock': lastSeenWorldUnlock,
        'xp': experience,
      };

  factory PlayerProgress.fromJson(Map<String, dynamic> json) => PlayerProgress(
        coins: json['coins'] as int? ?? kStartingCoins,
        highestUnlockedIndex: json['unlocked'] as int? ?? 0,
        results: ((json['results'] as Map?) ?? {}).map(
          (k, v) => MapEntry(
            k as String,
            LevelResult.fromJson(Map<String, dynamic>.from(v as Map)),
          ),
        ),
        dailyStreak: json['streak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastDailyDate: json['lastDaily'] == null
            ? null
            : DateTime.tryParse(json['lastDaily'] as String),
        completedDailyDates: ((json['dailyDates'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        totalWordsFound: json['words'] as int? ?? 0,
        totalPlaySeconds: json['seconds'] as int? ?? 0,
        hintsUsedLifetime: json['hints'] as int? ?? 0,
        isPremium: json['premium'] as bool? ?? false,
        hasCompletedOnboarding: json['onboarded'] as bool? ?? false,
        unlockedAchievements: ((json['achievements'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        lastSeenWorldUnlock: json['worldUnlock'] as int? ?? 0,
        experience: json['xp'] as int? ?? 0,
      );
}
