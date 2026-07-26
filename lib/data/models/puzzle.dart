import 'package:flutter/foundation.dart';

import 'grid_position.dart';

/// A word after it has been placed into the grid, including every cell it
/// occupies. Storing the cells (rather than recomputing them) means selection
/// matching is a cheap set comparison.
@immutable
class PlacedWord {
  const PlacedWord({
    required this.word,
    required this.start,
    required this.direction,
    required this.cells,
  });

  /// The answer, always upper-case and letters-only.
  final String word;
  final GridPosition start;
  final WordDirection direction;

  /// Cells in reading order, `cells.first == start`.
  final List<GridPosition> cells;

  GridPosition get end => cells.last;

  Map<String, dynamic> toJson() => {
        'w': word,
        's': start.toJson(),
        'd': direction.name,
      };

  /// Rebuilds a placed word from its compact JSON form. Cells are derived from
  /// the start position, direction and length so they never fall out of sync.
  factory PlacedWord.fromJson(Map<String, dynamic> json) {
    final word = json['w'] as String;
    final start = GridPosition.fromJson(
      Map<String, dynamic>.from(json['s'] as Map),
    );
    final direction = WordDirection.values.byName(json['d'] as String);
    return PlacedWord(
      word: word,
      start: start,
      direction: direction,
      cells: List.generate(word.length, (i) => start.step(direction, i)),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacedWord &&
          other.word == word &&
          other.start == start &&
          other.direction == direction;

  @override
  int get hashCode => Object.hash(word, start, direction);
}

/// A fully generated, solvable puzzle: the letter grid plus the placement of
/// every answer inside it.
///
/// A [Puzzle] is pure data — it holds no play state. Which words the player has
/// already found lives in the game session controller, so the same puzzle
/// object can be replayed without being mutated.
@immutable
class Puzzle {
  const Puzzle({
    required this.grid,
    required this.placedWords,
    required this.rows,
    required this.cols,
  });

  /// `grid[row][col]` — a single upper-case letter.
  final List<List<String>> grid;
  final List<PlacedWord> placedWords;
  final int rows;
  final int cols;

  List<String> get words => placedWords.map((w) => w.word).toList();

  String letterAt(GridPosition p) => grid[p.row][p.col];

  bool contains(GridPosition p) =>
      p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols;

  /// Finds the placed word occupying exactly [selection], in either direction.
  ///
  /// Returns `null` when the selection does not correspond to an answer, which
  /// is how invalid swipes get rejected.
  PlacedWord? matchSelection(List<GridPosition> selection) {
    if (selection.isEmpty) return null;
    for (final placed in placedWords) {
      if (placed.cells.length != selection.length) continue;
      if (_sameOrder(placed.cells, selection)) return placed;
      if (_sameOrder(placed.cells.reversed.toList(), selection)) return placed;
    }
    return null;
  }

  static bool _sameOrder(List<GridPosition> a, List<GridPosition> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Cells that belong to no answer. The "clear clutter" hint removes some of
  /// these, and the generator uses it to verify grid density.
  Set<GridPosition> get fillerCells {
    final used = <GridPosition>{for (final w in placedWords) ...w.cells};
    return {
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++)
          if (!used.contains(GridPosition(r, c))) GridPosition(r, c),
    };
  }

  /// Self-check used by the generator and the test-suite: every answer must
  /// actually be readable in the grid at its recorded location.
  bool get isSolvable {
    if (grid.length != rows) return false;
    for (final row in grid) {
      if (row.length != cols) return false;
    }
    if (placedWords.isEmpty) return false;

    final seen = <String>{};
    for (final placed in placedWords) {
      // No duplicate answers within one puzzle.
      if (!seen.add(placed.word)) return false;
      if (placed.cells.length != placed.word.length) return false;
      for (var i = 0; i < placed.cells.length; i++) {
        final cell = placed.cells[i];
        if (!contains(cell)) return false;
        if (grid[cell.row][cell.col] != placed.word[i]) return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'rows': rows,
        'cols': cols,
        'grid': grid.map((r) => r.join()).toList(),
        'words': placedWords.map((w) => w.toJson()).toList(),
      };

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'] as int;
    final cols = json['cols'] as int;
    return Puzzle(
      rows: rows,
      cols: cols,
      grid: (json['grid'] as List)
          .map((r) => (r as String).split(''))
          .toList(growable: false),
      placedWords: (json['words'] as List)
          .map((w) => PlacedWord.fromJson(Map<String, dynamic>.from(w as Map)))
          .toList(growable: false),
    );
  }
}
