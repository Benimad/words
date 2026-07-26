import 'package:flutter/material.dart';

/// User-controlled preferences, persisted locally.
@immutable
class GameSettings {
  const GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.themeMode = ThemeMode.system,
    this.highContrastGrid = false,
    this.largeLetters = false,
    this.showTimer = true,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final ThemeMode themeMode;

  /// Accessibility: boosts the contrast of grid letters and selection fills.
  final bool highContrastGrid;

  /// Accessibility: bumps grid letter size at the cost of some board padding.
  final bool largeLetters;

  /// Some players find the timer stressful, so it can be hidden. It still runs
  /// for scoring — hiding it only removes the on-screen readout.
  final bool showTimer;

  GameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    ThemeMode? themeMode,
    bool? highContrastGrid,
    bool? largeLetters,
    bool? showTimer,
  }) =>
      GameSettings(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        themeMode: themeMode ?? this.themeMode,
        highContrastGrid: highContrastGrid ?? this.highContrastGrid,
        largeLetters: largeLetters ?? this.largeLetters,
        showTimer: showTimer ?? this.showTimer,
      );

  Map<String, dynamic> toJson() => {
        'sound': soundEnabled,
        'music': musicEnabled,
        'haptics': hapticsEnabled,
        'theme': themeMode.name,
        'contrast': highContrastGrid,
        'largeLetters': largeLetters,
        'timer': showTimer,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        soundEnabled: json['sound'] as bool? ?? true,
        musicEnabled: json['music'] as bool? ?? true,
        hapticsEnabled: json['haptics'] as bool? ?? true,
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == json['theme'],
          orElse: () => ThemeMode.system,
        ),
        highContrastGrid: json['contrast'] as bool? ?? false,
        largeLetters: json['largeLetters'] as bool? ?? false,
        showTimer: json['timer'] as bool? ?? true,
      );
}
