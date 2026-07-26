import 'dart:math';

import '../models/level.dart';
import '../models/world.dart';
import 'difficulty_curve.dart';
import 'word_banks.dart';

/// Builds the campaign: 8 worlds x 30 levels = 240 levels.
///
/// Levels are *described*, not stored. Each one carries a fixed seed, so the
/// generator rebuilds an identical board every time — the same level always
/// looks the same on every device and across reinstalls, without shipping a
/// megabyte of pre-baked grids.
abstract final class LevelCatalog {
  static const levelsPerWorld = 30;

  static const _worldMeta = <({
    String id,
    String name,
    String tagline,
    String emoji,
  })>[
    (
      id: 'verdant-vale',
      name: 'Verdant Vale',
      tagline: 'Where every path begins in green.',
      emoji: '🌿',
    ),
    (
      id: 'coral-coast',
      name: 'Coral Coast',
      tagline: 'Salt air, bright water, hidden words.',
      emoji: '🐚',
    ),
    (
      id: 'ember-dunes',
      name: 'Ember Dunes',
      tagline: 'Sun-baked sands and spice-laden trade winds.',
      emoji: '🏜️',
    ),
    (
      id: 'frostpeak-hollow',
      name: 'Frostpeak Hollow',
      tagline: 'Climb high. The air is thin and the puzzles sharp.',
      emoji: '❄️',
    ),
    (
      id: 'neon-nexus',
      name: 'Neon Nexus',
      tagline: 'A city that never stops spelling.',
      emoji: '🌃',
    ),
    (
      id: 'blossom-bay',
      name: 'Blossom Bay',
      tagline: 'Slow mornings, warm kitchens, gentle grids.',
      emoji: '🌸',
    ),
    (
      id: 'starfall-rift',
      name: 'Starfall Rift',
      tagline: 'Beyond the atmosphere, the letters get serious.',
      emoji: '🌌',
    ),
    (
      id: 'chronicle-keep',
      name: 'Chronicle Keep',
      tagline: 'The final archive. Only masters read here.',
      emoji: '📜',
    ),
  ];

  static List<World>? _cache;

  /// All worlds, built once and cached for the process lifetime.
  static List<World> get worlds => _cache ??= _build();

  /// Flat list of every level in campaign order.
  static List<Level> get allLevels =>
      [for (final world in worlds) ...world.levels];

  static int get totalLevels => worlds.length * levelsPerWorld;

  static World worldById(String id) =>
      worlds.firstWhere((w) => w.id == id, orElse: () => worlds.first);

  static Level? levelById(String id) {
    for (final world in worlds) {
      for (final level in world.levels) {
        if (level.id == id) return level;
      }
    }
    return null;
  }

  /// The level at [globalIndex], or `null` when the campaign is finished.
  static Level? levelByGlobalIndex(int globalIndex) {
    if (globalIndex < 0 || globalIndex >= totalLevels) return null;
    final worldIndex = globalIndex ~/ levelsPerWorld;
    return worlds[worldIndex].levels[globalIndex % levelsPerWorld];
  }

  static World worldForLevel(Level level) => worldById(level.worldId);

  static List<World> _build() {
    final worlds = <World>[];

    for (var w = 0; w < _worldMeta.length; w++) {
      final meta = _worldMeta[w];
      final themes = WordBanks.byWorld[w];
      final levels = <Level>[];

      for (var i = 0; i < levelsPerWorld; i++) {
        final globalIndex = w * levelsPerWorld + i;
        final step = DifficultyCurve.forGlobalIndex(globalIndex);
        final theme = themes[i % themes.length];

        // A large odd multiplier spreads consecutive seeds far apart, so
        // neighbouring levels do not produce visually similar boards.
        final seed = 1000003 * (globalIndex + 1) + theme.name.hashCode;

        levels.add(
          Level(
            id: '${meta.id}-${(i + 1).toString().padLeft(2, '0')}',
            worldId: meta.id,
            indexInWorld: i,
            globalIndex: globalIndex,
            theme: theme.name,
            wordPool: _selectPool(theme.words, step, seed),
            rows: step.rows,
            cols: step.cols,
            wordCount: step.wordCount,
            allowedDirections: step.directions,
            difficulty: step.difficulty,
            seed: seed,
            timeLimit: DifficultyCurve.isTimedLevel(i)
                ? DifficultyCurve.timeLimitFor(step)
                : null,
          ),
        );
      }

      worlds.add(
        World(
          id: meta.id,
          name: meta.name,
          tagline: meta.tagline,
          emoji: meta.emoji,
          paletteIndex: w,
          levels: List.unmodifiable(levels),
          order: w,
        ),
      );
    }

    return List.unmodifiable(worlds);
  }

  /// Picks the candidate words for one level.
  ///
  /// Two goals pull against each other here:
  ///  * The pool must suit the band's difficulty (short words early, long
  ///    words late), and
  ///  * it must contain *surplus* candidates so the generator can drop a word
  ///    that refuses to fit rather than failing.
  ///
  /// So: filter by length, deterministically shuffle, then keep a comfortable
  /// surplus. If filtering leaves too few words, the length window is widened
  /// step by step until there are enough — this is what guarantees no level can
  /// ever be born unsolvable due to content.
  static List<String> _selectPool(
    List<String> themeWords,
    DifficultyStep step,
    int seed,
  ) {
    // A word can never be longer than the board.
    final hardMax = min(step.maxWordLength, max(step.rows, step.cols));
    final desired = step.wordCount + 6;

    var minLen = step.minWordLength;
    var maxLen = hardMax;
    List<String> filtered;

    // Widen the window until we have enough candidates (or run out of room).
    var guard = 0;
    do {
      filtered = themeWords
          .where((w) => w.length >= minLen && w.length <= maxLen)
          .toList();
      if (filtered.length >= desired) break;
      if (minLen > 3) minLen--;
      if (maxLen < max(step.rows, step.cols)) maxLen++;
      guard++;
    } while (guard < 12);

    // Absolute fallback: everything that physically fits on the board.
    if (filtered.length < step.wordCount) {
      filtered = themeWords
          .where((w) => w.length <= max(step.rows, step.cols))
          .toList();
    }

    filtered.shuffle(Random(seed));
    return List.unmodifiable(
      filtered.length > desired ? filtered.sublist(0, desired) : filtered,
    );
  }
}
