import 'package:flutter/foundation.dart';

import 'level.dart';

/// A themed region of the journey map containing a run of levels.
///
/// Worlds are the game's macro-progression: finishing one unlocks the next and
/// triggers a celebration, which gives players a reason to come back beyond the
/// next individual level.
@immutable
class World {
  const World({
    required this.id,
    required this.name,
    required this.tagline,
    required this.emoji,
    required this.paletteIndex,
    required this.levels,
    required this.order,
  });

  final String id;
  final String name;

  /// One-line flavour text shown on the world card.
  final String tagline;

  /// Simple emoji marker — avoids shipping bitmap art while still giving each
  /// region a distinct identity.
  final String emoji;

  /// Index into `AppPalette.worldAccents`.
  final int paletteIndex;

  final List<Level> levels;

  /// 0-based position on the map.
  final int order;

  int get levelCount => levels.length;

  /// Global index of this world's first level — used to decide whether the
  /// world is reachable given the player's furthest unlocked level.
  int get firstGlobalIndex => levels.first.globalIndex;

  int get lastGlobalIndex => levels.last.globalIndex;
}
