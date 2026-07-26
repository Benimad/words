import 'dart:math';

import '../../data/models/grid_position.dart';
import '../../data/models/puzzle.dart';

/// Thrown when a puzzle could not be produced from the given request. Callers
/// should treat this as a content bug, not a runtime condition — the generator
/// is designed to always succeed for the level definitions the game ships.
class PuzzleGenerationException implements Exception {
  PuzzleGenerationException(this.message);
  final String message;

  @override
  String toString() => 'PuzzleGenerationException: $message';
}

/// What the caller wants generated.
class PuzzleRequest {
  PuzzleRequest({
    required this.rows,
    required this.cols,
    required this.wordPool,
    required this.wordCount,
    required this.allowedDirections,
    required this.seed,
    this.minWordLength = 3,
  });

  final int rows;
  final int cols;

  /// Candidate answers. More candidates than [wordCount] gives the generator
  /// room to swap out a word that will not fit.
  final List<String> wordPool;

  /// How many answers the finished puzzle should contain.
  final int wordCount;

  final List<WordDirection> allowedDirections;
  final int seed;
  final int minWordLength;
}

/// Generates guaranteed-solvable word-search puzzles.
///
/// ## Algorithm
///
/// 1. **Normalise & filter** the pool: upper-case, letters only, deduplicated,
///    and short enough to fit the board.
/// 2. **Sort longest-first.** Long words are the hardest to place, so placing
///    them while the board is still empty dramatically raises the success rate.
/// 3. **Backtracking placement.** For each word, every legal (position,
///    direction) slot is scored and tried in order. If a word cannot be placed,
///    the algorithm backtracks and retries earlier words in a different slot.
/// 4. **Restart with a new seed** if backtracking exhausts itself, and shrink
///    the target word count as a final fallback so generation can never hang.
/// 5. **Fill** the empty cells with letters biased toward the answers' own
///    letter distribution, so filler does not stand out visually.
/// 6. **Verify** the result with [Puzzle.isSolvable] before returning it.
///
/// Placement scoring prefers slots that *overlap* existing words on matching
/// letters. Overlaps are what make a word search feel dense and handcrafted
/// rather than like a list of parallel lines.
class PuzzleGenerator {
  const PuzzleGenerator();

  /// Cap on placement attempts per generation pass, guarding against pathological
  /// inputs (e.g. ten 12-letter words on a 7x7 board).
  static const _maxBacktrackSteps = 20000;

  /// How many times to restart with a fresh seed before reducing the word count.
  static const _maxRestarts = 12;

  Puzzle generate(PuzzleRequest request) {
    _validate(request);

    final candidates = _prepareWords(request);
    if (candidates.isEmpty) {
      throw PuzzleGenerationException(
        'No usable words for a ${request.rows}x${request.cols} board.',
      );
    }

    // Never ask for more words than we actually have.
    var target = min(request.wordCount, candidates.length);

    // Progressive fallback: try the full target, then fewer words. In practice
    // the first pass succeeds for every shipped level; the loop exists so a
    // hostile custom level can still produce *something* playable.
    while (target >= 1) {
      for (var restart = 0; restart < _maxRestarts; restart++) {
        final rng = Random(request.seed + restart * 7919);
        final puzzle = _attempt(request, candidates, target, rng);
        if (puzzle != null) {
          // Defensive: never hand out a board we cannot prove is solvable.
          if (!puzzle.isSolvable) {
            throw PuzzleGenerationException(
              'Generated puzzle failed its own solvability check.',
            );
          }
          return puzzle;
        }
      }
      target--;
    }

    throw PuzzleGenerationException(
      'Could not place any word on a ${request.rows}x${request.cols} board.',
    );
  }

  void _validate(PuzzleRequest request) {
    if (request.rows < 3 || request.cols < 3) {
      throw PuzzleGenerationException('Board must be at least 3x3.');
    }
    if (request.rows > 20 || request.cols > 20) {
      throw PuzzleGenerationException('Board must be at most 20x20.');
    }
    if (request.allowedDirections.isEmpty) {
      throw PuzzleGenerationException('At least one direction is required.');
    }
    if (request.wordCount < 1) {
      throw PuzzleGenerationException('wordCount must be >= 1.');
    }
  }

  /// Cleans and orders the candidate pool.
  List<String> _prepareWords(PuzzleRequest request) {
    final longestFit = max(request.rows, request.cols);
    final seen = <String>{};
    final words = <String>[];

    for (final raw in request.wordPool) {
      // Strip spaces, hyphens and accents-free non-letters; upper-case.
      final word = raw.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
      if (word.length < request.minWordLength) continue;
      if (word.length > longestFit) continue;
      if (!seen.add(word)) continue; // no duplicates within one puzzle
      words.add(word);
    }

    // Longest first — the constraint-heaviest placements happen while the board
    // is emptiest.
    words.sort((a, b) => b.length.compareTo(a.length));
    return words;
  }

  /// One full placement pass. Returns `null` if it could not place [target]
  /// words within the step budget.
  Puzzle? _attempt(
    PuzzleRequest request,
    List<String> candidates,
    int target,
    Random rng,
  ) {
    final grid = List.generate(
      request.rows,
      (_) => List.filled(request.cols, _empty),
      growable: false,
    );

    // Keep the long words (which must be placed early) in order, but shuffle
    // within equal-length groups so different seeds give different boards.
    final pool = _shuffleWithinLengthGroups(candidates, rng);

    final placed = <PlacedWord>[];
    var steps = 0;

    /// Depth-first search over "which pool word goes next, in which slot".
    bool place(int poolStart) {
      if (placed.length == target) return true;

      // Not enough words left to reach the target — prune.
      if (pool.length - poolStart < target - placed.length) return false;

      for (var i = poolStart; i < pool.length; i++) {
        final word = pool[i];
        final slots = _candidateSlots(grid, word, request, rng);

        for (final slot in slots) {
          if (++steps > _maxBacktrackSteps) return false;

          final overwritten = _write(grid, word, slot);
          placed.add(
            PlacedWord(
              word: word,
              start: slot.start,
              direction: slot.direction,
              cells: List.generate(
                word.length,
                (k) => slot.start.step(slot.direction, k),
              ),
            ),
          );

          if (place(i + 1)) return true;

          // Undo and try the next slot / next word.
          placed.removeLast();
          _erase(grid, overwritten);
        }
      }
      return false;
    }

    if (!place(0)) return null;

    _fillEmptyCells(grid, placed, rng);

    return Puzzle(
      grid: grid,
      placedWords: List.unmodifiable(placed),
      rows: request.rows,
      cols: request.cols,
    );
  }

  static const _empty = '';

  List<String> _shuffleWithinLengthGroups(List<String> words, Random rng) {
    final byLength = <int, List<String>>{};
    for (final w in words) {
      byLength.putIfAbsent(w.length, () => []).add(w);
    }
    final lengths = byLength.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final len in lengths) ...(byLength[len]!..shuffle(rng)),
    ];
  }

  /// Every legal slot for [word], best-scoring first.
  List<_Slot> _candidateSlots(
    List<List<String>> grid,
    String word,
    PuzzleRequest request,
    Random rng,
  ) {
    final slots = <_Slot>[];

    for (final direction in request.allowedDirections) {
      // Restrict the start range so the whole word stays on the board — this is
      // what makes out-of-bounds placements structurally impossible.
      final endOffset = word.length - 1;
      final minRow = direction.dRow < 0 ? endOffset : 0;
      final maxRow = direction.dRow > 0
          ? request.rows - 1 - endOffset
          : request.rows - 1;
      final minCol = direction.dCol < 0 ? endOffset : 0;
      final maxCol = direction.dCol > 0
          ? request.cols - 1 - endOffset
          : request.cols - 1;

      for (var r = minRow; r <= maxRow; r++) {
        for (var c = minCol; c <= maxCol; c++) {
          final start = GridPosition(r, c);
          final score = _scorePlacement(grid, word, start, direction);
          if (score == null) continue; // conflicts with an existing letter
          slots.add(_Slot(start, direction, score));
        }
      }
    }

    if (slots.isEmpty) return const [];

    // Shuffle first so equal scores break ties randomly (varied boards), then
    // sort by score so overlap-rich placements are attempted first.
    slots.shuffle(rng);
    slots.sort((a, b) => b.score.compareTo(a.score));

    // Trying every slot is wasteful on big boards; the best 40 is plenty for
    // backtracking to find a solution.
    return slots.length > 40 ? slots.sublist(0, 40) : slots;
  }

  /// Returns a desirability score, or `null` when the placement is illegal.
  ///
  /// Higher is better. Overlaps on matching letters are strongly rewarded;
  /// placements that merely sit next to existing words get a small bonus for
  /// keeping the board compact.
  int? _scorePlacement(
    List<List<String>> grid,
    String word,
    GridPosition start,
    WordDirection direction,
  ) {
    var overlaps = 0;

    for (var i = 0; i < word.length; i++) {
      final p = start.step(direction, i);
      final existing = grid[p.row][p.col];
      if (existing == _empty) continue;
      // A different letter already occupies this cell: illegal.
      if (existing != word[i]) return null;
      overlaps++;
    }

    // A word entirely on top of another word would be invisible as a distinct
    // answer — reject full shadowing.
    if (overlaps == word.length) return null;

    return overlaps * 12 + word.length;
  }

  /// Writes [word] into the grid, returning the cells that were empty before so
  /// the move can be undone precisely during backtracking.
  List<GridPosition> _write(
    List<List<String>> grid,
    String word,
    _Slot slot,
  ) {
    final written = <GridPosition>[];
    for (var i = 0; i < word.length; i++) {
      final p = slot.start.step(slot.direction, i);
      if (grid[p.row][p.col] == _empty) {
        grid[p.row][p.col] = word[i];
        written.add(p);
      }
    }
    return written;
  }

  void _erase(List<List<String>> grid, List<GridPosition> cells) {
    for (final p in cells) {
      grid[p.row][p.col] = _empty;
    }
  }

  /// Fills blank cells with plausible filler.
  ///
  /// Sampling from the answers' own letter frequencies (rather than uniform
  /// A-Z) matters: uniform filler is full of J/Q/X/Z, which makes real words
  /// pop out and the puzzle trivially easy.
  void _fillEmptyCells(
    List<List<String>> grid,
    List<PlacedWord> placed,
    Random rng,
  ) {
    final bag = <String>[];
    for (final p in placed) {
      bag.addAll(p.word.split(''));
    }
    // Blend with English letter frequency so filler stays varied even when the
    // theme's words share few letters.
    bag.addAll(_englishFrequencyBag);

    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid[r].length; c++) {
        if (grid[r][c] == _empty) {
          grid[r][c] = bag[rng.nextInt(bag.length)];
        }
      }
    }
  }

  /// Letters repeated in rough proportion to their English frequency.
  static final List<String> _englishFrequencyBag = () {
    const frequencies = <String, int>{
      'E': 12, 'T': 9, 'A': 8, 'O': 8, 'I': 7, 'N': 7, 'S': 6, 'H': 6,
      'R': 6, 'D': 4, 'L': 4, 'C': 3, 'U': 3, 'M': 2, 'W': 2, 'F': 2,
      'G': 2, 'Y': 2, 'P': 2, 'B': 1, 'V': 1, 'K': 1, 'J': 1, 'X': 1,
      'Q': 1, 'Z': 1,
    };
    return [
      for (final entry in frequencies.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ];
  }();
}

/// A candidate placement under consideration.
class _Slot {
  const _Slot(this.start, this.direction, this.score);
  final GridPosition start;
  final WordDirection direction;
  final int score;
}
