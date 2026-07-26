import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin, testable wrapper around the key-value store.
///
/// Everything the game persists goes through here, which gives us one place to
/// handle corrupt data. The rule is: **a read never throws**. If stored JSON is
/// unparseable (a crash mid-write, a downgrade, a tampered file), we log it and
/// fall back to defaults rather than trapping the player in a crash loop.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kProgress = 'wq.progress.v1';
  static const _kSettings = 'wq.settings.v1';
  static const _kDailyPuzzle = 'wq.daily.v1';
  static const _kSchemaVersion = 'wq.schema';

  /// Current storage schema. Bump when a breaking change to the stored shape
  /// requires a migration in [_migrateIfNeeded].
  static const currentSchemaVersion = 1;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._migrateIfNeeded();
    return service;
  }

  Future<void> _migrateIfNeeded() async {
    final stored = _prefs.getInt(_kSchemaVersion) ?? 0;
    if (stored == currentSchemaVersion) return;

    // v0 -> v1 is the initial release: nothing to migrate. Future versions add
    // their transformations here, each guarded by the version they upgrade from.
    await _prefs.setInt(_kSchemaVersion, currentSchemaVersion);
  }

  // --- Generic JSON helpers --------------------------------------------

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on FormatException catch (error) {
      debugPrint('StorageService: corrupt JSON at "$key" ($error) — resetting.');
      _prefs.remove(key);
      return null;
    }
  }

  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    try {
      return await _prefs.setString(key, jsonEncode(value));
    } catch (error) {
      // A failed write must not take the game down; the player simply keeps
      // playing with in-memory state and the next write may succeed.
      debugPrint('StorageService: failed to write "$key" ($error).');
      return false;
    }
  }

  // --- Typed accessors --------------------------------------------------

  Map<String, dynamic>? readProgress() => readJson(_kProgress);
  Future<bool> writeProgress(Map<String, dynamic> json) =>
      writeJson(_kProgress, json);

  Map<String, dynamic>? readSettings() => readJson(_kSettings);
  Future<bool> writeSettings(Map<String, dynamic> json) =>
      writeJson(_kSettings, json);

  /// The cached daily puzzle, so reopening the app on the same day returns the
  /// identical board with the player's found words intact.
  Map<String, dynamic>? readDailyState() => readJson(_kDailyPuzzle);
  Future<bool> writeDailyState(Map<String, dynamic> json) =>
      writeJson(_kDailyPuzzle, json);

  /// Wipes everything. Used by "Reset progress" in Settings.
  Future<void> clearAll() async {
    await Future.wait([
      _prefs.remove(_kProgress),
      _prefs.remove(_kSettings),
      _prefs.remove(_kDailyPuzzle),
    ]);
    await _prefs.setInt(_kSchemaVersion, currentSchemaVersion);
  }
}
