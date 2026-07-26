import 'package:flutter/foundation.dart';

import '../data/content/achievements.dart';
import '../data/content/level_catalog.dart';
import '../data/models/level.dart';
import '../data/models/level_result.dart';
import '../data/models/player_progress.dart';
import '../data/models/world.dart';
import '../data/repositories/progress_repository.dart';
import '../data/services/ad_service.dart';
import '../game/logic/scoring.dart';

/// Everything the level-complete screen needs to celebrate correctly.
class LevelCompletion {
  const LevelCompletion({
    required this.level,
    required this.score,
    required this.isFirstClear,
    required this.isNewBest,
    required this.previousStars,
    required this.unlockedWorld,
    required this.unlockedAchievements,
    required this.isCampaignComplete,
  });

  final Level level;
  final LevelScore score;

  /// True the first time this level is cleared (drives the biggest animation).
  final bool isFirstClear;

  /// True when this run beat the stored star rating or time.
  final bool isNewBest;
  final int previousStars;

  /// Non-null when clearing this level opened a new world.
  final World? unlockedWorld;

  final List<Achievement> unlockedAchievements;
  final bool isCampaignComplete;
}

/// The single source of truth for player progression: coins, unlocks, results,
/// streaks and achievements.
///
/// All mutations funnel through [_commit] so persistence and change
/// notification can never be forgotten.
class ProgressController extends ChangeNotifier {
  ProgressController({
    required ProgressRepository repository,
    required AdService ads,
  })  : _repository = repository,
        _ads = ads {
    _progress = _repository.load();
    _ads.setAdsRemoved(_progress.isPremium);
  }

  final ProgressRepository _repository;
  final AdService _ads;

  late PlayerProgress _progress;
  PlayerProgress get progress => _progress;

  int get coins => _progress.coins;
  bool get isPremium => _progress.isPremium;

  void _commit(PlayerProgress next) {
    _progress = next;
    _repository.save(next);
    notifyListeners();
  }

  /// Persists immediately — call when the app is backgrounded.
  Future<void> flush() => _repository.flush();

  // --- Onboarding -------------------------------------------------------

  void completeOnboarding() =>
      _commit(_progress.copyWith(hasCompletedOnboarding: true));

  // --- Currency ---------------------------------------------------------

  void addCoins(int amount) {
    if (amount <= 0) return;
    _commit(_progress.copyWith(coins: _progress.coins + amount));
  }

  /// Attempts to spend [amount]. Returns false (and changes nothing) when the
  /// player cannot afford it.
  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (_progress.coins < amount) return false;
    _commit(_progress.copyWith(
      coins: _progress.coins - amount,
      hintsUsedLifetime: _progress.hintsUsedLifetime,
    ));
    return true;
  }

  void registerHintUsed() => _commit(
        _progress.copyWith(hintsUsedLifetime: _progress.hintsUsedLifetime + 1),
      );

  // --- Premium ----------------------------------------------------------

  void setPremium(bool value) {
    _ads.setAdsRemoved(value);
    _commit(_progress.copyWith(isPremium: value));
  }

  // --- Level flow -------------------------------------------------------

  /// The next level the player should play — the first incomplete unlocked
  /// level, or the furthest unlocked one if everything so far is done.
  Level? get nextLevel {
    for (final level in LevelCatalog.allLevels) {
      if (!_progress.isLevelUnlocked(level.globalIndex)) break;
      if (!_progress.isLevelCompleted(level.id)) return level;
    }
    return LevelCatalog.levelByGlobalIndex(_progress.highestUnlockedIndex);
  }

  bool isLevelUnlocked(Level level) =>
      _progress.isLevelUnlocked(level.globalIndex);

  /// A world is enterable once the player has unlocked its first level.
  bool isWorldUnlocked(World world) =>
      _progress.highestUnlockedIndex >= world.firstGlobalIndex;

  int completedInWorld(World world) =>
      world.levels.where((l) => _progress.isLevelCompleted(l.id)).length;

  double worldProgress(World world) =>
      world.levelCount == 0 ? 0 : completedInWorld(world) / world.levelCount;

  int starsInWorld(World world) => world.levels
      .map((l) => _progress.resultFor(l.id)?.stars ?? 0)
      .fold(0, (a, b) => a + b);

  double get campaignProgress =>
      _progress.levelsCompleted / LevelCatalog.totalLevels;

  /// Records a completed level and returns everything needed to celebrate it.
  ///
  /// Safe to call for replays: rewards for a level already cleared are reduced
  /// (see [_replayReward]) so grinding an easy level is not the optimal way to
  /// earn coins, but a replay still pays something.
  LevelCompletion completeLevel({
    required Level level,
    required Duration elapsed,
    required int hintsUsed,
    required int wordsFound,
  }) {
    final existing = _progress.resultFor(level.id);
    final isFirstClear = existing == null;

    final score = Scoring.evaluate(
      level: level,
      elapsed: elapsed,
      hintsUsed: hintsUsed,
      dailyStreak: _progress.dailyStreak,
    );

    final attempt = LevelResult(
      levelId: level.id,
      stars: score.stars,
      bestTimeSeconds: elapsed.inSeconds,
      hintsUsed: hintsUsed,
      completedAt: DateTime.now(),
    );

    final merged = existing?.mergeWith(attempt) ?? attempt;
    final isNewBest = !isFirstClear &&
        (attempt.stars > existing.stars ||
            attempt.bestTimeSeconds < existing.bestTimeSeconds);

    final coinsAwarded =
        isFirstClear ? score.totalCoins : _replayReward(score, isNewBest);
    final xpAwarded = isFirstClear ? score.experience : score.experience ~/ 4;

    // Unlock the next level — but never move the marker backwards when an old
    // level is replayed.
    final unlockTarget = level.globalIndex + 1;
    final newHighest = unlockTarget > _progress.highestUnlockedIndex
        ? unlockTarget.clamp(0, LevelCatalog.totalLevels - 1)
        : _progress.highestUnlockedIndex;

    var next = _progress.copyWith(
      results: {..._progress.results, level.id: merged},
      coins: _progress.coins + coinsAwarded,
      experience: _progress.experience + xpAwarded,
      highestUnlockedIndex: newHighest,
      totalWordsFound: _progress.totalWordsFound + wordsFound,
      totalPlaySeconds: _progress.totalPlaySeconds + elapsed.inSeconds,
    );

    // Did this clear open a new world?
    World? unlockedWorld;
    if (isFirstClear) {
      final wasWorldIndex = level.globalIndex ~/ LevelCatalog.levelsPerWorld;
      final nowWorldIndex = newHighest ~/ LevelCatalog.levelsPerWorld;
      if (nowWorldIndex > wasWorldIndex &&
          nowWorldIndex < LevelCatalog.worlds.length &&
          nowWorldIndex > next.lastSeenWorldUnlock) {
        unlockedWorld = LevelCatalog.worlds[nowWorldIndex];
        next = next.copyWith(lastSeenWorldUnlock: nowWorldIndex);
      }
    }

    // Grant achievements against the *updated* progress.
    final newAchievements = Achievements.newlyUnlocked(next);
    if (newAchievements.isNotEmpty) {
      next = next.copyWith(
        unlockedAchievements: {
          ...next.unlockedAchievements,
          ...newAchievements.map((a) => a.id),
        },
        coins: next.coins +
            newAchievements.fold(0, (sum, a) => sum + a.coinReward),
      );
    }

    _commit(next);
    _ads.registerLevelCompleted();

    return LevelCompletion(
      level: level,
      score: score,
      isFirstClear: isFirstClear,
      isNewBest: isNewBest,
      previousStars: existing?.stars ?? 0,
      unlockedWorld: unlockedWorld,
      unlockedAchievements: newAchievements,
      isCampaignComplete: next.levelsCompleted >= LevelCatalog.totalLevels,
    );
  }

  /// Replays pay a flat third of base, plus the full bonus if a new best was
  /// set — enough to make improving a score feel worthwhile without turning
  /// replay into a coin farm.
  int _replayReward(LevelScore score, bool isNewBest) =>
      (score.baseCoins ~/ 3) + (isNewBest ? score.speedBonus : 0);

  // --- Daily challenge --------------------------------------------------

  /// Whether today's daily challenge has already been completed.
  bool get hasCompletedTodaysDaily {
    final last = _progress.lastDailyDate;
    if (last == null) return false;
    return _isSameDay(last, DateTime.now());
  }

  /// Records a daily challenge completion and advances/breaks the streak.
  ///
  /// The streak advances when the previous completion was *yesterday*, resets
  /// to 1 when it was longer ago, and is a no-op when today is already done.
  ({int streak, int coinsAwarded, bool isNewRecord}) completeDailyChallenge({
    required int wordsFound,
    required Duration elapsed,
  }) {
    final now = DateTime.now();
    if (hasCompletedTodaysDaily) {
      return (streak: _progress.dailyStreak, coinsAwarded: 0, isNewRecord: false);
    }

    final last = _progress.lastDailyDate;
    final continues = last != null &&
        _isSameDay(last, now.subtract(const Duration(days: 1)));
    final streak = continues ? _progress.dailyStreak + 1 : 1;

    // Reward grows with the streak but plateaus, so missing a day stings
    // without making a broken streak feel unrecoverable.
    final coins = 50 + (streak.clamp(1, 14) * 10);
    final isNewRecord = streak > _progress.longestStreak;

    var next = _progress.copyWith(
      dailyStreak: streak,
      longestStreak: isNewRecord ? streak : _progress.longestStreak,
      lastDailyDate: DateTime(now.year, now.month, now.day),
      completedDailyDates: {..._progress.completedDailyDates, _dateKey(now)},
      coins: _progress.coins + coins,
      experience: _progress.experience + 60,
      totalWordsFound: _progress.totalWordsFound + wordsFound,
      totalPlaySeconds: _progress.totalPlaySeconds + elapsed.inSeconds,
    );

    final newAchievements = Achievements.newlyUnlocked(next);
    if (newAchievements.isNotEmpty) {
      next = next.copyWith(
        unlockedAchievements: {
          ...next.unlockedAchievements,
          ...newAchievements.map((a) => a.id),
        },
        coins: next.coins +
            newAchievements.fold(0, (sum, a) => sum + a.coinReward),
      );
    }

    _commit(next);
    return (streak: streak, coinsAwarded: coins, isNewRecord: isNewRecord);
  }

  /// True when the streak is about to lapse — the last completion was
  /// yesterday and today is still open. Drives the home-screen nudge.
  bool get isStreakAtRisk {
    final last = _progress.lastDailyDate;
    if (last == null || _progress.dailyStreak == 0) return false;
    return _isSameDay(last, DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Effective streak for display: a streak that has already lapsed (last play
  /// was more than a day ago) shows as 0 rather than a stale number.
  int get displayStreak {
    final last = _progress.lastDailyDate;
    if (last == null) return 0;
    final now = DateTime.now();
    if (_isSameDay(last, now)) return _progress.dailyStreak;
    if (_isSameDay(last, now.subtract(const Duration(days: 1)))) {
      return _progress.dailyStreak;
    }
    return 0;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // --- Reset ------------------------------------------------------------

  Future<void> resetProgress() async {
    _progress = await _repository.reset();
    _ads.setAdsRemoved(false);
    notifyListeners();
  }
}
