import 'package:flutter/foundation.dart';

/// A single cell coordinate on the puzzle board.
///
/// Immutable and value-comparable so positions can be used as `Set`/`Map` keys
/// when tracking which letters are currently selected or already solved.
@immutable
class GridPosition {
  const GridPosition(this.row, this.col);

  final int row;
  final int col;

  GridPosition operator +(GridPosition other) =>
      GridPosition(row + other.row, col + other.col);

  /// Steps [times] cells along [direction] starting from this position.
  GridPosition step(WordDirection direction, [int times = 1]) =>
      GridPosition(row + direction.dRow * times, col + direction.dCol * times);

  /// Chebyshev distance — 1 for any of the eight neighbouring cells. This is
  /// exactly the adjacency rule the swipe selector needs.
  int chebyshevDistanceTo(GridPosition other) =>
      (row - other.row).abs() > (col - other.col).abs()
          ? (row - other.row).abs()
          : (col - other.col).abs();

  Map<String, int> toJson() => {'r': row, 'c': col};

  factory GridPosition.fromJson(Map<String, dynamic> json) =>
      GridPosition(json['r'] as int, json['c'] as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col)';
}

/// The eight directions a word may run in.
///
/// The `reversed` flag lets the generator restrict early levels to
/// left-to-right / top-to-bottom words only, then progressively unlock the
/// harder backwards and diagonal orientations.
enum WordDirection {
  east(0, 1, reversed: false, diagonal: false),
  south(1, 0, reversed: false, diagonal: false),
  southEast(1, 1, reversed: false, diagonal: true),
  northEast(-1, 1, reversed: false, diagonal: true),
  west(0, -1, reversed: true, diagonal: false),
  north(-1, 0, reversed: true, diagonal: false),
  northWest(-1, -1, reversed: true, diagonal: true),
  southWest(1, -1, reversed: true, diagonal: true);

  const WordDirection(
    this.dRow,
    this.dCol, {
    required this.reversed,
    required this.diagonal,
  });

  final int dRow;
  final int dCol;

  /// True when the word reads right-to-left or bottom-to-top on screen.
  final bool reversed;

  /// True for the four diagonal orientations.
  final bool diagonal;

  WordDirection get opposite => switch (this) {
        east => west,
        west => east,
        south => north,
        north => south,
        southEast => northWest,
        northWest => southEast,
        northEast => southWest,
        southWest => northEast,
      };
}
