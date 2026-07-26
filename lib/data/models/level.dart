import 'package:flutter/foundation.dart';

import 'grid_position.dart';

/// How hard a level is, derived from its index in the overall campaign.
enum Difficulty {
  gentle('Gentle', 1),
  easy('Easy', 2),
  steady('Steady', 3),
  tricky('Tricky', 4),
  hard('Hard', 5),
  expert('Expert', 6),
  master('Master', 7);

  const Difficulty(this.label, this.stars);

  final String label;

  /// Used for reward scaling — harder levels pay out more coins.
  final int stars;
}

/// The recipe for one level.
///
/// A level is *not* a stored puzzle: it is a deterministic description that the
/// generator turns into a puzzle on demand. That keeps the app's install size
/// tiny while still giving every player the identical board for a given level
/// (the seed is fixed), which matters for fairness and for reproducing bugs.
@immutable
class Level {
  const Level({
    required this.id,
    required this.worldId,
    required this.indexInWorld,
    required this.globalIndex,
    required this.theme,
    required this.wordPool,
    required this.rows,
    required this.cols,
    required this.wordCount,
    required this.allowedDirections,
    required this.difficulty,
    required this.seed,
    this.timeLimit,
  });

  /// Stable identifier, e.g. `w2-l07`. Used as the persistence key.
  final String id;
  final String worldId;

  /// 0-based position within its world.
  final int indexInWorld;

  /// 0-based position across the whole campaign; drives the difficulty curve.
  final int globalIndex;

  /// Human-readable category, e.g. "Rainforest Animals".
  final String theme;

  /// Candidate answers for this level. The generator picks [wordCount] of them
  /// that fit; having a surplus is what makes generation reliable.
  final List<String> wordPool;

  final int rows;
  final int cols;
  final int wordCount;

  /// Orientations the generator is permitted to use. Early levels are
  /// horizontal/vertical only; diagonals and reversed words unlock later.
  final List<WordDirection> allowedDirections;

  final Difficulty difficulty;

  /// Deterministic RNG seed, so level N always generates the same board.
  final int seed;

  /// Optional per-level countdown (used by timed challenge levels).
  final Duration? timeLimit;

  /// Display label shown on cards and the map, e.g. "Level 7".
  String get displayNumber => 'Level ${indexInWorld + 1}';

  /// Base coin payout before streak/perfection bonuses.
  int get baseReward => 10 + difficulty.stars * 5;

  bool get isTimed => timeLimit != null;
}
