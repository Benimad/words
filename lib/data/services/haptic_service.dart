import 'package:flutter/services.dart';

/// Centralises haptic feedback so intensity stays consistent and the
/// user's "haptics off" preference is honoured in exactly one place.
class HapticService {
  bool _enabled = true;

  void setEnabled(bool value) => _enabled = value;

  /// Passing over a new letter mid-swipe. Must be the lightest tap available —
  /// this fires many times per gesture.
  void selectionTick() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// A word was accepted.
  void success() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// A selection was rejected.
  void error() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Buttons and navigation.
  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Level complete / reward moments.
  void celebrate() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }
}
