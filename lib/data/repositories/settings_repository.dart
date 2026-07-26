import 'package:flutter/foundation.dart';

import '../models/game_settings.dart';
import '../services/storage_service.dart';

/// Reads and writes [GameSettings]. Settings change rarely, so writes are
/// immediate — no debouncing needed here.
class SettingsRepository {
  SettingsRepository(this._storage);

  final StorageService _storage;

  GameSettings load() {
    final json = _storage.readSettings();
    if (json == null) return const GameSettings();
    try {
      return GameSettings.fromJson(json);
    } catch (error) {
      debugPrint('SettingsRepository: unreadable settings ($error) — default.');
      return const GameSettings();
    }
  }

  Future<void> save(GameSettings settings) =>
      _storage.writeSettings(settings.toJson());
}
