import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordquest/data/content/daily_challenge.dart';
import 'package:wordquest/data/content/level_catalog.dart';
import 'package:wordquest/data/models/game_settings.dart';
import 'package:wordquest/data/models/player_progress.dart';
import 'package:wordquest/data/repositories/progress_repository.dart';
import 'package:wordquest/data/repositories/settings_repository.dart';
import 'package:wordquest/data/services/ad_service.dart';
import 'package:wordquest/data/services/storage_service.dart';
import 'package:wordquest/game/generator/puzzle_generator.dart';
import 'package:wordquest/state/progress_controller.dart';

Future<ProgressController> freshController() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.create();
  return ProgressController(
    repository: ProgressRepository(storage),
    // AdService is inert until `init()` runs, so it is safe in tests.
    ads: AdService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressController — unlocking', () {
    test('only the first level is unlocked for a new player', () async {
      final controller = await freshController();

      expect(controller.progress.highestUnlockedIndex, 0);
      expect(controller.isLevelUnlocked(LevelCatalog.allLevels[0]), isTrue);
      expect(controller.isLevelUnlocked(LevelCatalog.allLevels[1]), isFalse);
      expect(controller.nextLevel?.globalIndex, 0);
    });

    test('completing a level unlocks the next one', () async {
      final controller = await freshController();
      final level = LevelCatalog.allLevels[0];

      controller.completeLevel(
        level: level,
        elapsed: const Duration(seconds: 30),
        hintsUsed: 0,
        wordsFound: level.wordCount,
      );

      expect(controller.progress.highestUnlockedIndex, 1);
      expect(controller.isLevelUnlocked(LevelCatalog.allLevels[1]), isTrue);
      expect(controller.nextLevel?.globalIndex, 1);
    });

    test('replaying an old level never moves the unlock marker back', () async {
      final controller = await freshController();

      for (var i = 0; i < 5; i++) {
        controller.completeLevel(
          level: LevelCatalog.allLevels[i],
          elapsed: const Duration(seconds: 30),
          hintsUsed: 0,
          wordsFound: 4,
        );
      }
      expect(controller.progress.highestUnlockedIndex, 5);

      controller.completeLevel(
        level: LevelCatalog.allLevels[0],
        elapsed: const Duration(seconds: 20),
        hintsUsed: 0,
        wordsFound: 4,
      );
      expect(controller.progress.highestUnlockedIndex, 5);
    });

    test('a world unlocks only once its first level is reachable', () async {
      final controller = await freshController();
      final secondWorld = LevelCatalog.worlds[1];

      expect(controller.isWorldUnlocked(secondWorld), isFalse);

      // Clear all 30 levels of world one.
      for (var i = 0; i < LevelCatalog.levelsPerWorld; i++) {
        controller.completeLevel(
          level: LevelCatalog.allLevels[i],
          elapsed: const Duration(seconds: 30),
          hintsUsed: 0,
          wordsFound: 5,
        );
      }

      expect(controller.isWorldUnlocked(secondWorld), isTrue);
      expect(controller.completedInWorld(LevelCatalog.worlds[0]), 30);
      expect(controller.worldProgress(LevelCatalog.worlds[0]), 1.0);
    });

    test('the world-unlock celebration fires exactly once', () async {
      final controller = await freshController();

      var unlockEvents = 0;
      for (var i = 0; i < LevelCatalog.levelsPerWorld; i++) {
        final completion = controller.completeLevel(
          level: LevelCatalog.allLevels[i],
          elapsed: const Duration(seconds: 30),
          hintsUsed: 0,
          wordsFound: 5,
        );
        if (completion.unlockedWorld != null) unlockEvents++;
      }
      expect(unlockEvents, 1);

      // Replaying the boundary level must not re-fire it.
      final replay = controller.completeLevel(
        level: LevelCatalog.allLevels[LevelCatalog.levelsPerWorld - 1],
        elapsed: const Duration(seconds: 10),
        hintsUsed: 0,
        wordsFound: 5,
      );
      expect(replay.unlockedWorld, isNull);
    });
  });

  group('ProgressController — scoring and rewards', () {
    test('a fast hint-free run earns three stars', () async {
      final controller = await freshController();
      final level = LevelCatalog.allLevels[0];

      final completion = controller.completeLevel(
        level: level,
        elapsed: const Duration(seconds: 5),
        hintsUsed: 0,
        wordsFound: level.wordCount,
      );

      expect(completion.score.stars, 3);
      expect(completion.isFirstClear, isTrue);
      expect(completion.score.noHintBonus, greaterThan(0));
      expect(completion.score.speedBonus, greaterThan(0));
    });

    test('a slow hint-heavy run still completes, at one star', () async {
      final controller = await freshController();
      final level = LevelCatalog.allLevels[0];

      final completion = controller.completeLevel(
        level: level,
        elapsed: const Duration(minutes: 20),
        hintsUsed: 6,
        wordsFound: level.wordCount,
      );

      expect(completion.score.stars, 1);
      expect(completion.score.totalCoins, greaterThan(0));
    });

    test('replays pay less than a first clear', () async {
      final controller = await freshController();
      final level = LevelCatalog.allLevels[0];

      final coinsBefore = controller.coins;
      controller.completeLevel(
        level: level,
        elapsed: const Duration(seconds: 5),
        hintsUsed: 0,
        wordsFound: 4,
      );
      final firstClearGain = controller.coins - coinsBefore;

      final beforeReplay = controller.coins;
      controller.completeLevel(
        level: level,
        elapsed: const Duration(seconds: 5),
        hintsUsed: 0,
        wordsFound: 4,
      );
      final replayGain = controller.coins - beforeReplay;

      expect(replayGain, lessThan(firstClearGain));
    });

    test('a best result is never downgraded by a worse replay', () async {
      final controller = await freshController();
      final level = LevelCatalog.allLevels[0];

      controller.completeLevel(
        level: level,
        elapsed: const Duration(seconds: 5),
        hintsUsed: 0,
        wordsFound: 4,
      );
      controller.completeLevel(
        level: level,
        elapsed: const Duration(minutes: 15),
        hintsUsed: 5,
        wordsFound: 4,
      );

      final result = controller.progress.resultFor(level.id)!;
      expect(result.stars, 3);
      expect(result.bestTimeSeconds, 5);
      expect(result.hintsUsed, 0);
      expect(result.timesPlayed, 2);
    });
  });

  group('ProgressController — coins', () {
    test('spending fails cleanly when the player cannot afford it', () async {
      final controller = await freshController();

      expect(controller.spendCoins(controller.coins + 1), isFalse);
      expect(controller.coins, PlayerProgress.kStartingCoins);

      expect(controller.spendCoins(50), isTrue);
      expect(controller.coins, PlayerProgress.kStartingCoins - 50);
    });
  });

  group('ProgressController — daily streak', () {
    test('first daily starts a streak of one', () async {
      final controller = await freshController();

      expect(controller.hasCompletedTodaysDaily, isFalse);
      final result = controller.completeDailyChallenge(
        wordsFound: 8,
        elapsed: const Duration(minutes: 3),
      );

      expect(result.streak, 1);
      expect(result.coinsAwarded, greaterThan(0));
      expect(controller.hasCompletedTodaysDaily, isTrue);
    });

    test('a second completion on the same day awards nothing extra', () async {
      final controller = await freshController();

      controller.completeDailyChallenge(
        wordsFound: 8,
        elapsed: const Duration(minutes: 3),
      );
      final coinsAfterFirst = controller.coins;

      final second = controller.completeDailyChallenge(
        wordsFound: 8,
        elapsed: const Duration(minutes: 3),
      );

      expect(second.coinsAwarded, 0);
      expect(controller.coins, coinsAfterFirst);
      expect(controller.progress.dailyStreak, 1);
    });

    test('a lapsed streak displays as zero', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.create();
      final repository = ProgressRepository(storage);

      // Seed a streak whose last play was three days ago.
      repository.save(
        const PlayerProgress(dailyStreak: 9, longestStreak: 9).copyWith(
          lastDailyDate: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );
      await repository.flush();

      final controller = ProgressController(
        repository: ProgressRepository(storage),
        ads: AdService(),
      );

      expect(controller.progress.dailyStreak, 9); // stored value is preserved
      expect(controller.displayStreak, 0); // ...but it reads as broken
      expect(controller.isStreakAtRisk, isFalse);
    });
  });

  group('Persistence', () {
    test('progress survives a reload', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.create();

      final first = ProgressController(
        repository: ProgressRepository(storage),
        ads: AdService(),
      );
      first.completeLevel(
        level: LevelCatalog.allLevels[0],
        elapsed: const Duration(seconds: 12),
        hintsUsed: 0,
        wordsFound: 4,
      );
      first.addCoins(500);
      await first.flush();

      final reloaded = ProgressController(
        repository: ProgressRepository(storage),
        ads: AdService(),
      );

      expect(reloaded.progress.levelsCompleted, 1);
      expect(reloaded.coins, first.coins);
      expect(reloaded.progress.highestUnlockedIndex, 1);
    });

    test('reset wipes everything back to a new profile', () async {
      final controller = await freshController();

      controller.completeLevel(
        level: LevelCatalog.allLevels[0],
        elapsed: const Duration(seconds: 12),
        hintsUsed: 0,
        wordsFound: 4,
      );
      controller.addCoins(999);

      await controller.resetProgress();

      expect(controller.progress.levelsCompleted, 0);
      expect(controller.progress.highestUnlockedIndex, 0);
      expect(controller.coins, PlayerProgress.kStartingCoins);
    });

    test('corrupt stored JSON falls back to defaults instead of throwing',
        () async {
      SharedPreferences.setMockInitialValues({
        'wq.progress.v1': '{not valid json',
        'wq.settings.v1': 'also broken',
      });
      final storage = await StorageService.create();

      final progress = ProgressRepository(storage).load();
      expect(progress.coins, PlayerProgress.kStartingCoins);

      final settings = SettingsRepository(storage).load();
      expect(settings.soundEnabled, isTrue);
    });

    test('settings round-trip through storage', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.create();
      final repository = SettingsRepository(storage);

      await repository.save(
        const GameSettings(
          soundEnabled: false,
          hapticsEnabled: false,
          largeLetters: true,
        ),
      );

      final loaded = repository.load();
      expect(loaded.soundEnabled, isFalse);
      expect(loaded.hapticsEnabled, isFalse);
      expect(loaded.largeLetters, isTrue);
      expect(loaded.musicEnabled, isTrue); // untouched default
    });
  });

  group('Achievements', () {
    test('an achievement is granted once and pays its coin reward', () async {
      final controller = await freshController();

      final completion = controller.completeLevel(
        level: LevelCatalog.allLevels[0],
        elapsed: const Duration(seconds: 12),
        hintsUsed: 0,
        wordsFound: 4,
      );

      // "First Steps" fires on the very first clear.
      expect(
        completion.unlockedAchievements.map((a) => a.id),
        contains('first-steps'),
      );

      final second = controller.completeLevel(
        level: LevelCatalog.allLevels[1],
        elapsed: const Duration(seconds: 12),
        hintsUsed: 0,
        wordsFound: 4,
      );
      expect(
        second.unlockedAchievements.map((a) => a.id),
        isNot(contains('first-steps')),
      );
    });
  });

  group('DailyChallenge', () {
    const generator = PuzzleGenerator();

    test('the same date always produces the same level', () {
      final date = DateTime(2026, 7, 26);
      final a = DailyChallenge.forDate(date);
      final b = DailyChallenge.forDate(date);

      expect(a.id, b.id);
      expect(a.seed, b.seed);
      expect(a.theme, b.theme);
      expect(a.wordPool, b.wordPool);
    });

    test('different dates produce different puzzles', () {
      final a = DailyChallenge.forDate(DateTime(2026, 7, 26));
      final b = DailyChallenge.forDate(DateTime(2026, 7, 27));
      expect(a.seed, isNot(b.seed));
    });

    test('a full year of daily puzzles is generable and solvable', () {
      var date = DateTime(2026, 1, 1);
      for (var i = 0; i < 365; i++) {
        final level = DailyChallenge.forDate(date);
        final puzzle = generator.generate(
          PuzzleRequest(
            rows: level.rows,
            cols: level.cols,
            wordPool: level.wordPool,
            wordCount: level.wordCount,
            allowedDirections: level.allowedDirections,
            seed: level.seed,
          ),
        );

        expect(
          puzzle.isSolvable,
          isTrue,
          reason: 'daily puzzle for ${level.id} was invalid',
        );
        expect(puzzle.placedWords, hasLength(level.wordCount));

        date = date.add(const Duration(days: 1));
      }
    });

    test('the week strip covers seven days ending today', () {
      final week = DailyChallenge.recentWeek();
      expect(week, hasLength(7));

      final today = DateTime.now();
      expect(week.last.day, today.day);
      expect(week.first.isBefore(week.last), isTrue);
    });
  });
}
