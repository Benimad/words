import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models/grid_position.dart';
import '../data/models/hint.dart';
import '../data/models/level.dart';
import '../data/models/puzzle.dart';
import '../game/generator/puzzle_generator.dart';

/// Lifecycle of one play session.
enum GameStatus { loading, playing, paused, completed, failed, error }

/// A word the player has solved, plus how it was solved.
class FoundWord {
  const FoundWord({
    required this.placed,
    required this.viaHint,
    required this.orderFound,
  });

  final PlacedWord placed;

  /// True when a "Reveal Word" hint solved it rather than the player.
  final bool viaHint;

  /// 0-based order, used to pick the ribbon colour so each word gets its own.
  final int orderFound;
}

/// Drives a single level: the board, the swipe selection, hints and the clock.
///
/// The controller owns *only* in-level state. Coins, unlocks and stats live in
/// `ProgressController`; the game screen wires the two together when the level
/// ends. That split keeps replaying, previewing and the daily challenge all
/// able to reuse this class unchanged.
class GameSessionController extends ChangeNotifier {
  GameSessionController({
    required this.level,
    required this.isDailyChallenge,
    PuzzleGenerator generator = const PuzzleGenerator(),
  }) : _generator = generator;

  final Level level;
  final bool isDailyChallenge;
  final PuzzleGenerator _generator;

  // --- State ------------------------------------------------------------

  GameStatus _status = GameStatus.loading;
  GameStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Puzzle? _puzzle;
  Puzzle get puzzle => _puzzle!;
  bool get isReady => _puzzle != null;

  final List<FoundWord> _found = [];
  List<FoundWord> get foundWords => List.unmodifiable(_found);

  /// Fast lookup for "is this word solved".
  final Set<String> _foundLookup = {};

  /// The cells under the finger right now.
  List<GridPosition> _selection = const [];
  List<GridPosition> get selection => _selection;

  GridPosition? _anchor;

  /// Cells belonging to solved words, mapped to the order they were found in
  /// (so the board can colour each word differently).
  final Map<GridPosition, int> _solvedCells = {};
  Map<GridPosition, int> get solvedCells => Map.unmodifiable(_solvedCells);

  /// Cells flashed by a "First Letter" hint.
  final Set<GridPosition> _hintedCells = {};
  Set<GridPosition> get hintedCells => Set.unmodifiable(_hintedCells);

  /// Filler cells dimmed by "Clear Clutter".
  final Set<GridPosition> _dimmedCells = {};
  Set<GridPosition> get dimmedCells => Set.unmodifiable(_dimmedCells);

  int _hintsUsed = 0;
  int get hintsUsed => _hintsUsed;

  /// Bumped whenever a selection is rejected, so the board can run its shake
  /// animation without the controller knowing anything about widgets.
  int _rejectionCounter = 0;
  int get rejectionCounter => _rejectionCounter;

  /// The most recently solved word — drives the "found!" toast.
  FoundWord? _lastFound;
  FoundWord? get lastFound => _lastFound;

  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  Duration? get remaining => level.timeLimit == null
      ? null
      : level.timeLimit! - _elapsed < Duration.zero
          ? Duration.zero
          : level.timeLimit! - _elapsed;

  int get wordsRemaining => (_puzzle?.placedWords.length ?? 0) - _found.length;

  double get completionRatio {
    final total = _puzzle?.placedWords.length ?? 0;
    return total == 0 ? 0 : _found.length / total;
  }

  bool isWordFound(String word) => _foundLookup.contains(word);

  /// Answers still to be found.
  List<PlacedWord> get unsolvedWords => _puzzle == null
      ? const []
      : _puzzle!.placedWords.where((w) => !_foundLookup.contains(w.word)).toList();

  // --- Setup ------------------------------------------------------------

  /// Builds the board. Called once from the game screen's `initState`.
  Future<void> start() async {
    _status = GameStatus.loading;
    notifyListeners();

    try {
      // Generation is fast (single-digit ms for shipped levels) but it is CPU
      // work, so it runs after a frame to let the entry transition play first.
      await Future<void>.delayed(const Duration(milliseconds: 16));

      _puzzle = _generator.generate(
        PuzzleRequest(
          rows: level.rows,
          cols: level.cols,
          wordPool: level.wordPool,
          wordCount: level.wordCount,
          allowedDirections: level.allowedDirections,
          seed: level.seed,
        ),
      );

      _status = GameStatus.playing;
      _startTicker();
    } on PuzzleGenerationException catch (error) {
      // Content-level failure. Surfaced as a recoverable error screen rather
      // than a crash, so the player can back out and pick another level.
      _status = GameStatus.error;
      _errorMessage = 'This puzzle could not be prepared.\n${error.message}';
    } catch (error) {
      _status = GameStatus.error;
      _errorMessage = 'Something went wrong preparing this puzzle.';
      debugPrint('GameSessionController: unexpected start failure ($error).');
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != GameStatus.playing) return;
      _elapsed += const Duration(seconds: 1);

      // Timed levels end when the clock runs out.
      final limit = level.timeLimit;
      if (limit != null && _elapsed >= limit) {
        _status = GameStatus.failed;
        _ticker?.cancel();
      }
      notifyListeners();
    });
  }

  void pause() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    clearSelection();
    notifyListeners();
  }

  void resume() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    notifyListeners();
  }

  // --- Selection --------------------------------------------------------

  /// Begins a swipe at [position].
  void beginSelection(GridPosition position) {
    if (_status != GameStatus.playing || !isReady) return;
    if (!puzzle.contains(position)) return;
    _anchor = position;
    _selection = [position];
    notifyListeners();
  }

  /// Extends the current swipe to [position].
  ///
  /// Rather than tracking every cell the finger crossed, the selection is
  /// recomputed as the straight line from the anchor to [position]. This is
  /// what makes fast diagonal swipes feel accurate: the player only has to hit
  /// the first and last letter, and a jittery finger cannot corrupt the word.
  /// Positions that are not on one of the eight rays from the anchor are
  /// ignored, leaving the previous valid line on screen.
  ///
  /// Returns true when the selection actually changed (used to fire the tick
  /// sound/haptic exactly once per new cell).
  bool extendSelection(GridPosition position) {
    if (_status != GameStatus.playing || _anchor == null || !isReady) {
      return false;
    }
    if (!puzzle.contains(position)) return false;
    if (_selection.isNotEmpty && _selection.last == position) return false;

    final line = _lineBetween(_anchor!, position);
    if (line == null) return false; // not aligned — keep the last valid line

    final changed = line.length != _selection.length ||
        (line.isNotEmpty && _selection.isNotEmpty && line.last != _selection.last);

    _selection = line;
    if (changed) notifyListeners();
    return changed;
  }

  /// The inclusive straight line from [from] to [to], or `null` when the two
  /// points do not share a row, column or exact diagonal.
  List<GridPosition>? _lineBetween(GridPosition from, GridPosition to) {
    final dRow = to.row - from.row;
    final dCol = to.col - from.col;

    final isAligned =
        dRow == 0 || dCol == 0 || dRow.abs() == dCol.abs();
    if (!isAligned) return null;

    final steps = max(dRow.abs(), dCol.abs());
    if (steps == 0) return [from];

    final stepRow = dRow.sign;
    final stepCol = dCol.sign;

    return List.generate(
      steps + 1,
      (i) => GridPosition(from.row + stepRow * i, from.col + stepCol * i),
    );
  }

  /// Ends the swipe and evaluates it.
  ///
  /// Returns what happened so the UI can pick the right sound, haptic and
  /// animation without re-deriving the result.
  SelectionResult endSelection() {
    if (_status != GameStatus.playing || _selection.isEmpty) {
      clearSelection();
      return SelectionResult.none;
    }

    // A single tap is not an attempt — just deselect silently.
    if (_selection.length < 2) {
      clearSelection();
      return SelectionResult.none;
    }

    final match = puzzle.matchSelection(_selection);

    if (match == null) {
      _rejectionCounter++;
      clearSelection();
      return SelectionResult.rejected;
    }

    if (_foundLookup.contains(match.word)) {
      // Already solved: not an error, just a no-op the UI can acknowledge.
      clearSelection();
      return SelectionResult.alreadyFound;
    }

    _registerFound(match, viaHint: false);
    clearSelection();
    return SelectionResult.accepted;
  }

  void clearSelection() {
    if (_selection.isEmpty && _anchor == null) return;
    _selection = const [];
    _anchor = null;
    notifyListeners();
  }

  void _registerFound(PlacedWord placed, {required bool viaHint}) {
    final found = FoundWord(
      placed: placed,
      viaHint: viaHint,
      orderFound: _found.length,
    );
    _found.add(found);
    _foundLookup.add(placed.word);
    _lastFound = found;

    for (final cell in placed.cells) {
      _solvedCells[cell] = found.orderFound;
      // A solved letter is never clutter, and never still "hinted".
      _dimmedCells.remove(cell);
      _hintedCells.remove(cell);
    }

    if (_found.length == puzzle.placedWords.length) {
      _status = GameStatus.completed;
      _ticker?.cancel();
    }
    notifyListeners();
  }

  // --- Hints ------------------------------------------------------------

  /// Applies [type] to the board.
  ///
  /// The controller does **not** charge coins — the caller checks affordability
  /// first and only commits the spend when this returns [HintOutcome.applied].
  /// That ordering means a hint can never take coins without having an effect.
  HintOutcome applyHint(HintType type) {
    if (_status != GameStatus.playing || !isReady) {
      return HintOutcome.nothingToReveal;
    }

    switch (type) {
      case HintType.firstLetter:
        return _hintFirstLetter();
      case HintType.revealWord:
        return _hintRevealWord();
      case HintType.clearClutter:
        return _hintClearClutter();
    }
  }

  /// Flashes the starting cell of an unsolved word — preferring one that has
  /// not already been hinted, so repeat purchases keep giving new information.
  HintOutcome _hintFirstLetter() {
    final candidates = unsolvedWords
        .where((w) => !_hintedCells.contains(w.cells.first))
        .toList();
    final pool = candidates.isNotEmpty ? candidates : unsolvedWords;
    if (pool.isEmpty) return HintOutcome.nothingToReveal;

    // Seeded by state so the same board does not always reveal the same word.
    final rng = Random(level.seed + _hintsUsed * 31 + _found.length);
    final target = pool[rng.nextInt(pool.length)];

    _hintedCells.add(target.cells.first);
    _hintsUsed++;
    notifyListeners();
    return HintOutcome.applied;
  }

  /// Solves the shortest unsolved word outright. Shortest-first is deliberate:
  /// it keeps the most satisfying (longest) words for the player.
  HintOutcome _hintRevealWord() {
    final unsolved = unsolvedWords;
    if (unsolved.isEmpty) return HintOutcome.nothingToReveal;

    unsolved.sort((a, b) => a.word.length.compareTo(b.word.length));
    _hintsUsed++;
    _registerFound(unsolved.first, viaHint: true);
    return HintOutcome.applied;
  }

  /// Dims a batch of letters belonging to no answer.
  ///
  /// A *fraction* of the remaining clutter is removed rather than all of it, so
  /// the hint stays useful (and purchasable) more than once on a big board.
  HintOutcome _hintClearClutter() {
    final clutter = puzzle.fillerCells
        .where((c) => !_dimmedCells.contains(c) && !_solvedCells.containsKey(c))
        .toList();
    if (clutter.isEmpty) return HintOutcome.nothingToReveal;

    final rng = Random(level.seed + _hintsUsed * 17);
    clutter.shuffle(rng);

    final batch = max(1, (clutter.length * 0.35).round());
    _dimmedCells.addAll(clutter.take(batch));
    _hintsUsed++;
    notifyListeners();
    return HintOutcome.applied;
  }

  /// Grants extra time on a timed level (sold by the "out of time" sheet).
  void addTime(Duration bonus) {
    if (level.timeLimit == null) return;
    _elapsed = _elapsed - bonus;
    if (_elapsed < Duration.zero) _elapsed = Duration.zero;
    if (_status == GameStatus.failed) {
      _status = GameStatus.playing;
      _startTicker();
    }
    notifyListeners();
  }

  /// Restarts the same level from scratch (keeps the same board).
  void restart() {
    _found.clear();
    _foundLookup.clear();
    _solvedCells.clear();
    _hintedCells.clear();
    _dimmedCells.clear();
    _selection = const [];
    _anchor = null;
    _hintsUsed = 0;
    _elapsed = Duration.zero;
    _lastFound = null;
    _status = GameStatus.playing;
    _startTicker();
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// What a completed swipe turned out to be.
enum SelectionResult { none, accepted, rejected, alreadyFound }
