import 'package:flutter/foundation.dart';

/// The player's best recorded outcome for one level.
///
/// Only the best result is kept — replaying a level can improve the star rating
/// or time but never lowers it, so replay always feels safe.
@immutable
class LevelResult {
  const LevelResult({
    required this.levelId,
    required this.stars,
    required this.bestTimeSeconds,
    required this.hintsUsed,
    required this.completedAt,
    this.timesPlayed = 1,
  });

  final String levelId;

  /// 1-3. Three stars means "no hints, comfortably inside the par time".
  final int stars;
  final int bestTimeSeconds;
  final int hintsUsed;
  final DateTime completedAt;
  final int timesPlayed;

  bool get isPerfect => stars == 3;

  /// Merges a fresh attempt into the stored best.
  LevelResult mergeWith(LevelResult attempt) => LevelResult(
        levelId: levelId,
        stars: attempt.stars > stars ? attempt.stars : stars,
        bestTimeSeconds: attempt.bestTimeSeconds < bestTimeSeconds
            ? attempt.bestTimeSeconds
            : bestTimeSeconds,
        hintsUsed: attempt.hintsUsed < hintsUsed ? attempt.hintsUsed : hintsUsed,
        completedAt: attempt.completedAt,
        timesPlayed: timesPlayed + 1,
      );

  Map<String, dynamic> toJson() => {
        'id': levelId,
        'stars': stars,
        'time': bestTimeSeconds,
        'hints': hintsUsed,
        'at': completedAt.toIso8601String(),
        'plays': timesPlayed,
      };

  factory LevelResult.fromJson(Map<String, dynamic> json) => LevelResult(
        levelId: json['id'] as String,
        stars: json['stars'] as int? ?? 1,
        bestTimeSeconds: json['time'] as int? ?? 0,
        hintsUsed: json['hints'] as int? ?? 0,
        completedAt:
            DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
        timesPlayed: json['plays'] as int? ?? 1,
      );
}
