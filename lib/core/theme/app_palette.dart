import 'package:flutter/material.dart';

/// The raw colour tokens for WordQuest's visual identity.
///
/// The identity is "aurora over a night sky": deep indigo surfaces lit by
/// violet/teal gradients, with a warm amber used exclusively for rewards and
/// currency so that "gold = value" reads instantly anywhere in the app.
///
/// Nothing here is derived from any existing product — the ramps were built
/// around a violet primary (`#6C4CF1`) and checked for WCAG AA contrast against
/// both the light and dark surface colours.
abstract final class AppPalette {
  // --- Brand ------------------------------------------------------------
  /// Primary brand violet. Used for main actions and the logo mark.
  static const violet = Color(0xFF6C4CF1);
  static const violetLight = Color(0xFF9B85FF);
  static const violetDark = Color(0xFF4A2FC7);
  static const violetSoft = Color(0xFFEDE8FF);

  /// Secondary accent — used for "discovery" moments (found words, progress).
  static const teal = Color(0xFF21C7BE);
  static const tealLight = Color(0xFF5EE8DF);
  static const tealDark = Color(0xFF0E8C86);

  /// Reserved for coins, rewards and streaks.
  static const amber = Color(0xFFFFB020);
  static const amberLight = Color(0xFFFFD37A);
  static const amberDark = Color(0xFFC77D00);

  // --- Semantic ---------------------------------------------------------
  static const mint = Color(0xFF34D399);
  static const coral = Color(0xFFFF6B6B);
  static const sky = Color(0xFF38BDF8);
  static const rose = Color(0xFFF472B6);
  static const lime = Color(0xFFA3E635);
  static const orange = Color(0xFFFB923C);

  // --- Dark surfaces ----------------------------------------------------
  static const night = Color(0xFF0B0D26);
  static const nightElevated = Color(0xFF151841);
  static const nightCard = Color(0xFF1B1E4D);
  static const nightBorder = Color(0xFF2C3070);

  // --- Light surfaces ---------------------------------------------------
  static const dawn = Color(0xFFF7F5FF);
  static const dawnCard = Color(0xFFFFFFFF);
  static const dawnBorder = Color(0xFFE4E0F5);

  // --- Neutral text -----------------------------------------------------
  static const inkStrong = Color(0xFF171533);
  static const ink = Color(0xFF3A3763);
  static const inkMuted = Color(0xFF6E6A94);
  static const onDark = Color(0xFFF4F3FF);
  static const onDarkMuted = Color(0xFFA6A3CE);

  /// The eight world accent colours. Index maps to `World.paletteIndex`, so the
  /// map, level cards and in-game board all stay colour-consistent per world.
  static const worldAccents = <Color>[
    Color(0xFF34D399), // Verdant Vale — mint
    Color(0xFF38BDF8), // Coral Coast — sky
    Color(0xFFFB923C), // Ember Dunes — orange
    Color(0xFF22D3EE), // Frostpeak — cyan
    Color(0xFFA855F7), // Neon Nexus — purple
    Color(0xFFF472B6), // Blossom Bay — rose
    Color(0xFF818CF8), // Starfall Rift — indigo
    Color(0xFFFACC15), // Chronicle Keep — gold
  ];
}

/// Reusable gradients. Kept in one place so every surface in the app shares the
/// same light direction (top-left highlight → bottom-right shadow).
abstract final class AppGradients {
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.violetLight, AppPalette.violet, AppPalette.violetDark],
  );

  static const reward = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.amberLight, AppPalette.amber, AppPalette.amberDark],
  );

  static const discovery = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppPalette.tealLight, AppPalette.teal, AppPalette.tealDark],
  );

  static const nightSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF171A45), AppPalette.night],
  );

  static const daySky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), AppPalette.dawn],
  );

  /// Builds a soft two-stop gradient from a single accent colour. Used for
  /// world cards, badges and the found-word "ribbon" drawn on the board.
  static LinearGradient fromAccent(Color accent) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, Colors.white, 0.28)!,
          accent,
          Color.lerp(accent, Colors.black, 0.22)!,
        ],
      );
}
