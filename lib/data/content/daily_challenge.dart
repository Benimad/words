import 'dart:math';

import '../models/grid_position.dart';
import '../models/level.dart';
import 'word_banks.dart';

/// Builds the Daily Challenge level for a given calendar day.
///
/// The puzzle is derived purely from the date, which means:
///  * every player worldwide gets the same board on the same day,
///  * it works completely offline (no server round-trip), and
///  * reopening the app mid-solve rebuilds the identical grid.
///
/// Daily boards sit at a fixed medium-hard difficulty regardless of campaign
/// progress, so the mode reads as a distinct challenge rather than a shortcut.
abstract final class DailyChallenge {
  /// Stable id, e.g. `daily-2026-07-26`.
  static String idFor(DateTime date) => 'daily-${dateKey(date)}';

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// A seed that changes exactly once per day.
  static int seedFor(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  static Level forDate(DateTime date) {
    final seed = seedFor(date);
    final rng = Random(seed);

    final theme = WordBanks.daily[seed % WordBanks.daily.length];

    // Board and word count wobble slightly day to day so the mode never feels
    // like the same puzzle with different letters.
    final size = 10 + rng.nextInt(3); // 10, 11 or 12
    final wordCount = 7 + rng.nextInt(2); // 7 or 8

    final pool = theme.words
        .where((w) => w.length >= 4 && w.length <= size)
        .toList()
      ..shuffle(Random(seed));

    return Level(
      id: idFor(date),
      worldId: 'daily',
      indexInWorld: 0,
      // Daily levels sit outside the campaign ordering.
      globalIndex: -1,
      theme: theme.name,
      wordPool: pool.take(wordCount + 6).toList(),
      rows: size,
      cols: size,
      wordCount: wordCount,
      allowedDirections: WordDirection.values,
      difficulty: Difficulty.hard,
      seed: seed,
      // Daily play should be relaxing, not a race.
      timeLimit: null,
    );
  }

  static Level get today => forDate(DateTime.now());

  /// The seven days ending today, oldest first — powers the streak strip.
  static List<DateTime> recentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
  }
}
