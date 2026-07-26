import 'package:flutter/material.dart';

import '../data/models/game_settings.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/audio_service.dart';
import '../data/services/haptic_service.dart';

/// Owns [GameSettings] and keeps the audio/haptic services in sync with them.
///
/// Services are updated here rather than at each call site so a preference
/// change takes effect instantly and globally.
class SettingsController extends ChangeNotifier {
  SettingsController({
    required SettingsRepository repository,
    required AudioService audio,
    required HapticService haptics,
  })  : _repository = repository,
        _audio = audio,
        _haptics = haptics {
    _settings = _repository.load();
    _applyToServices();
  }

  final SettingsRepository _repository;
  final AudioService _audio;
  final HapticService _haptics;

  late GameSettings _settings;
  GameSettings get settings => _settings;

  ThemeMode get themeMode => _settings.themeMode;

  void _applyToServices() {
    _audio.applySettings(
      sound: _settings.soundEnabled,
      music: _settings.musicEnabled,
    );
    _haptics.setEnabled(_settings.hapticsEnabled);
  }

  void _update(GameSettings next) {
    _settings = next;
    _applyToServices();
    notifyListeners();
    _repository.save(next);
  }

  void setSound(bool value) => _update(_settings.copyWith(soundEnabled: value));

  void setMusic(bool value) => _update(_settings.copyWith(musicEnabled: value));

  void setHaptics(bool value) =>
      _update(_settings.copyWith(hapticsEnabled: value));

  void setThemeMode(ThemeMode mode) =>
      _update(_settings.copyWith(themeMode: mode));

  void setHighContrastGrid(bool value) =>
      _update(_settings.copyWith(highContrastGrid: value));

  void setLargeLetters(bool value) =>
      _update(_settings.copyWith(largeLetters: value));

  void setShowTimer(bool value) =>
      _update(_settings.copyWith(showTimer: value));

  /// Restores factory defaults without touching game progress.
  void resetToDefaults() => _update(const GameSettings());
}
