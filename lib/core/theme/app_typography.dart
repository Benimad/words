import 'package:flutter/material.dart';

/// Type scale for WordQuest.
///
/// Two families, each with one job:
///  * **Baloo** (rounded display) — headings, numbers, anything "game-y".
///  * **Plus Jakarta Sans** — body copy, labels, dense UI. Chosen for its tall
///    x-height, which keeps small labels legible on phone screens.
abstract final class AppTypography {
  static const display = 'Baloo';
  static const body = 'Plus Jakarta Sans';

  /// Builds the Material text theme with the right family per role.
  static TextTheme textTheme(Color primary, Color muted) => TextTheme(
        // Display / headline roles use the rounded face.
        displayLarge: _display(44, FontWeight.w800, primary, height: 1.08),
        displayMedium: _display(36, FontWeight.w800, primary, height: 1.1),
        displaySmall: _display(30, FontWeight.w700, primary, height: 1.14),
        headlineLarge: _display(26, FontWeight.w700, primary, height: 1.2),
        headlineMedium: _display(22, FontWeight.w700, primary, height: 1.22),
        headlineSmall: _display(19, FontWeight.w600, primary, height: 1.25),
        titleLarge: _display(17, FontWeight.w700, primary, height: 1.3),

        // Everything below is UI text.
        titleMedium: _body(15, FontWeight.w600, primary, height: 1.35),
        titleSmall: _body(13.5, FontWeight.w600, primary, height: 1.35),
        bodyLarge: _body(15.5, FontWeight.w400, primary, height: 1.5),
        bodyMedium: _body(14, FontWeight.w400, muted, height: 1.5),
        bodySmall: _body(12.5, FontWeight.w400, muted, height: 1.45),
        labelLarge: _body(14, FontWeight.w700, primary, height: 1.2),
        labelMedium: _body(12.5, FontWeight.w600, muted, height: 1.2),
        labelSmall: _body(11, FontWeight.w600, muted, height: 1.2, tracking: .4),
      );

  static TextStyle _display(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.2,
    double tracking = -0.2,
  }) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: tracking,
      );

  static TextStyle _body(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.4,
    double tracking = 0,
  }) =>
      TextStyle(
        fontFamily: body,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: tracking,
      );

  /// The letters printed inside the puzzle grid. Slightly wider tracking makes
  /// individual glyphs easier to distinguish while swiping quickly.
  static TextStyle gridLetter(double size, Color color) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
        height: 1.0,
      );

  /// Tabular-ish numeric style for coins, timers and counters, so digits do not
  /// jitter as values change.
  static TextStyle numeric(double size, Color color,
          [FontWeight weight = FontWeight.w800]) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
