import '../models/grid_position.dart';
import '../models/level.dart';

/// The tuning parameters for a single level, derived from its position in the
/// campaign.
class DifficultyStep {
  const DifficultyStep({
    required this.rows,
    required this.cols,
    required this.wordCount,
    required this.directions,
    required this.difficulty,
    required this.minWordLength,
    required this.maxWordLength,
  });

  final int rows;
  final int cols;
  final int wordCount;
  final List<WordDirection> directions;
  final Difficulty difficulty;
  final int minWordLength;
  final int maxWordLength;
}

/// Maps a level's global index onto concrete difficulty parameters.
///
/// The curve is deliberately *staged* rather than smooth. Players notice a new
/// mechanic (diagonals, then backwards words) far more than they notice a board
/// growing by one cell, so each band introduces one new idea and then gives the
/// player a dozen levels to get comfortable with it:
///
/// | Levels    | Board   | Words | New mechanic                    |
/// |-----------|---------|-------|---------------------------------|
/// | 1-15      | 7x7     | 4-5   | across & down only              |
/// | 16-40     | 8x8     | 5-6   | + downward diagonal             |
/// | 41-80     | 9x9     | 6-7   | + backwards (across & down)     |
/// | 81-130    | 10x10   | 7-8   | + all four diagonals            |
/// | 131-190   | 11x11   | 8-9   | longer words, denser boards     |
/// | 191-240   | 12-13   | 9-10  | full difficulty                 |
abstract final class DifficultyCurve {
  /// Levels that run "across and down" only.
  static const _straightOnly = [WordDirection.east, WordDirection.south];

  static const _plusDownDiagonal = [
    WordDirection.east,
    WordDirection.south,
    WordDirection.southEast,
  ];

  static const _plusReversed = [
    WordDirection.east,
    WordDirection.south,
    WordDirection.southEast,
    WordDirection.west,
    WordDirection.north,
  ];

  static const _allDirections = WordDirection.values;

  static DifficultyStep forGlobalIndex(int globalIndex) {
    // Band 1 — teaching the basic swipe.
    if (globalIndex < 15) {
      return DifficultyStep(
        rows: 7,
        cols: 7,
        wordCount: globalIndex < 6 ? 4 : 5,
        directions: _straightOnly,
        difficulty: Difficulty.gentle,
        minWordLength: 3,
        maxWordLength: 6,
      );
    }

    // Band 2 — introducing diagonals.
    if (globalIndex < 40) {
      return DifficultyStep(
        rows: 8,
        cols: 8,
        wordCount: globalIndex < 28 ? 5 : 6,
        directions: _plusDownDiagonal,
        difficulty: Difficulty.easy,
        minWordLength: 3,
        maxWordLength: 7,
      );
    }

    // Band 3 — introducing backwards words.
    if (globalIndex < 80) {
      return DifficultyStep(
        rows: 9,
        cols: 9,
        wordCount: globalIndex < 60 ? 6 : 7,
        directions: _plusReversed,
        difficulty: Difficulty.steady,
        minWordLength: 3,
        maxWordLength: 8,
      );
    }

    // Band 4 — the full eight directions.
    if (globalIndex < 130) {
      return DifficultyStep(
        rows: 10,
        cols: 10,
        wordCount: globalIndex < 105 ? 7 : 8,
        directions: _allDirections,
        difficulty: Difficulty.tricky,
        minWordLength: 4,
        maxWordLength: 9,
      );
    }

    // Band 5 — longer vocabulary.
    if (globalIndex < 190) {
      return DifficultyStep(
        rows: 11,
        cols: 11,
        wordCount: globalIndex < 160 ? 8 : 9,
        directions: _allDirections,
        difficulty: Difficulty.hard,
        minWordLength: 4,
        maxWordLength: 10,
      );
    }

    // Band 6 — endgame. Board grows once more at the very end.
    final isFinalStretch = globalIndex >= 220;
    return DifficultyStep(
      rows: isFinalStretch ? 13 : 12,
      cols: isFinalStretch ? 13 : 12,
      wordCount: isFinalStretch ? 10 : 9,
      directions: _allDirections,
      difficulty: isFinalStretch ? Difficulty.master : Difficulty.expert,
      minWordLength: 4,
      maxWordLength: isFinalStretch ? 12 : 11,
    );
  }

  /// Every 8th level (from level 8 of each world) is a timed sprint. Timed
  /// levels break the rhythm and give the campaign a heartbeat.
  static bool isTimedLevel(int indexInWorld) =>
      indexInWorld > 0 && (indexInWorld + 1) % 8 == 0;

  /// Generous but meaningful countdown: enough time to solve calmly, tight
  /// enough that hesitating costs you.
  static Duration timeLimitFor(DifficultyStep step) =>
      Duration(seconds: 45 + step.wordCount * 18);

  /// Target solve time used for the 3-star rating.
  static Duration parTimeFor(DifficultyStep step) => Duration(
        seconds: (step.wordCount * 15 + step.rows * step.cols ~/ 4).round(),
      );
}
