import 'package:flutter/foundation.dart';

import '../models/player_progress.dart';
import '../services/storage_service.dart';

/// Reads and writes [PlayerProgress].
///
/// Writes are **debounced**: gameplay updates progress frequently (every found
/// word bumps counters), and hammering the platform channel on every change
/// causes jank. Changes are coalesced into one write per [_debounce] window,
/// with [flush] available for moments where losing state is unacceptable
/// (app backgrounding, reset).
class ProgressRepository {
  ProgressRepository(this._storage);

  final StorageService _storage;

  static const _debounce = Duration(milliseconds: 400);

  PlayerProgress _cache = const PlayerProgress();
  bool _dirty = false;
  Future<void>? _pendingWrite;

  PlayerProgress get current => _cache;

  /// Loads saved progress, falling back to a fresh profile if nothing is
  /// stored or the stored blob cannot be understood.
  PlayerProgress load() {
    final json = _storage.readProgress();
    if (json == null) {
      _cache = const PlayerProgress();
      return _cache;
    }
    try {
      _cache = PlayerProgress.fromJson(json);
    } catch (error) {
      // Malformed but syntactically valid JSON (e.g. a field changed type).
      debugPrint('ProgressRepository: unreadable progress ($error) — reset.');
      _cache = const PlayerProgress();
    }
    return _cache;
  }

  /// Records [progress] and schedules a debounced save.
  void save(PlayerProgress progress) {
    _cache = progress;
    _dirty = true;
    _pendingWrite ??= Future.delayed(_debounce, () async {
      _pendingWrite = null;
      await flush();
    });
  }

  /// Writes immediately if there are unsaved changes.
  Future<void> flush() async {
    if (!_dirty) return;
    _dirty = false;
    await _storage.writeProgress(_cache.toJson());
  }

  /// Clears saved progress and returns a fresh profile.
  Future<PlayerProgress> reset() async {
    _cache = const PlayerProgress();
    _dirty = false;
    await _storage.clearAll();
    await _storage.writeProgress(_cache.toJson());
    return _cache;
  }
}
