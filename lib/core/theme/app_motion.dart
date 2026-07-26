import 'package:flutter/animation.dart';

/// Motion tokens.
///
/// Every animation in the app pulls its duration and curve from here. Using a
/// small, shared set is what makes an interface feel "designed" rather than
/// assembled — screens that share timing read as one system.
abstract final class AppDurations {
  /// Micro-feedback: button press, ripple, letter highlight.
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);

  /// The default for most state changes.
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 480);

  /// Page transitions and celebratory sequences.
  static const page = Duration(milliseconds: 420);
  static const celebrate = Duration(milliseconds: 900);

  /// Ambient loops (floating orbs, shimmer sweeps).
  static const ambient = Duration(seconds: 6);
}

abstract final class AppCurves {
  /// Standard easing for entrances — decelerates into place.
  static const enter = Curves.easeOutCubic;

  /// Standard easing for exits.
  static const exit = Curves.easeInCubic;

  /// For anything that should feel physical (cards settling, sheets).
  static const spring = Curves.easeOutBack;

  /// Emphasised motion for celebratory beats.
  static const emphasised = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Symmetric easing for looping ambient motion.
  static const ambient = Curves.easeInOut;
}

/// Layout rhythm. All spacing in the app is a multiple of 4.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const huge = 48.0;
}

/// Corner radii. The app leans generously rounded to match the display font.
abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}
