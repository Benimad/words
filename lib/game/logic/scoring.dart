import '../../data/content/difficulty_curve.dart';
import '../../data/models/level.dart';

/// The reward breakdown shown on the level-complete screen.
class LevelScore {
  const LevelScore({
    required this.stars,
    required this.baseCoins,
    required this.speedBonus,
    required this.noHintBonus,
    required this.streakBonus,
    required this.experience,
  });

  final int stars;
  final int baseCoins;
  final int speedBonus;
  final int noHintBonus;
  final int streakBonus;
  final int experience;

  int get totalCoins => baseCoins + speedBonus + noHintBonus + streakBonus;
}

/// Turns a level attempt into stars, coins and XP.
///
/// The rating is intentionally forgiving: three stars requires a hint-free
/// solve inside par time, but *any* completion is worth coins. Punishing slow
/// play would work against the relaxed feel the game is going for.
abstract final class Scoring {
  static LevelScore evaluate({
    required Level level,
    required Duration elapsed,
    required int hintsUsed,
    required int dailyStreak,
  }) {
    final step = DifficultyCurve.forGlobalIndex(level.globalIndex);
    final par = DifficultyCurve.parTimeFor(step);

    final stars = _stars(elapsed: elapsed, par: par, hintsUsed: hintsUsed);

    final base = level.baseReward;

    // Speed bonus tapers linearly from full value at par to zero at 2x par.
    final overPar = elapsed.inSeconds - par.inSeconds;
    final speedBonus = overPar <= 0
        ? 15
        : overPar >= par.inSeconds
            ? 0
            : (15 * (1 - overPar / par.inSeconds)).round();

    final noHintBonus = hintsUsed == 0 ? 10 : 0;

    // Streak bonus rewards daily habit, capped so it cannot dwarf skill.
    final streakBonus = dailyStreak <= 1 ? 0 : (dailyStreak.clamp(0, 10) * 2);

    final experience = 20 + level.difficulty.stars * 6 + stars * 8;

    return LevelScore(
      stars: stars,
      baseCoins: base,
      speedBonus: speedBonus,
      noHintBonus: noHintBonus,
      streakBonus: streakBonus,
      experience: experience,
    );
  }

  static int _stars({
    required Duration elapsed,
    required Duration par,
    required int hintsUsed,
  }) {
    if (hintsUsed == 0 && elapsed <= par) return 3;
    if (hintsUsed <= 1 && elapsed <= par * 2) return 2;
    return 1;
  }

  /// Par time surfaced to the UI, so the timer can show how the player is
  /// tracking against a three-star run.
  static Duration parTimeFor(Level level) =>
      DifficultyCurve.parTimeFor(DifficultyCurve.forGlobalIndex(level.globalIndex));
}
