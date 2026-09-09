// services/saved_sessions_service.dart
//
// Persistence for saved practice sessions — a JSON list in SharedPreferences,
// newest first. Small by design: sessions are lightweight config + score
// snapshots, so there's no need for a database.

import 'package:flutter/foundation.dart';
import 'package:fretboard/models/saved_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedSessionsService {
  static const String _key = 'fretboard_saved_sessions_v1';
  // A soft cap so the store can't grow without bound.
  static const int _max = 50;

  /// How many sessions are stored — drives the "Saved sessions" entry on Home,
  /// which stays hidden while this is 0 (e.g. a first launch). Updated by every
  /// mutation and by [refreshCount].
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  /// The most recently saved session, or null when the store is empty. Drives
  /// the Home "Continue" card so it can name the session waiting to be picked
  /// back up.
  static final ValueNotifier<SavedSession?> latest =
      ValueNotifier<SavedSession?>(null);

  /// All saved sessions, newest first.
  static Future<List<SavedSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      count.value = 0;
      latest.value = null;
      return [];
    }
    final list = SavedSession.decodeList(raw);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    count.value = list.length;
    latest.value = list.isNotEmpty ? list.first : null;
    return list;
  }

  /// Loads just the count (for the Home entry) without returning the list.
  static Future<void> refreshCount() async {
    await load();
  }

  /// Adds [session] to the front of the store (trimmed to [_max]).
  static Future<void> add(SavedSession session) async {
    final list = await load();
    list.insert(0, session);
    if (list.length > _max) list.removeRange(_max, list.length);
    await _write(list);
  }

  /// Removes the session with [id].
  static Future<void> delete(String id) async {
    final list = await load()..removeWhere((s) => s.id == id);
    await _write(list);
  }

  /// Replaces the stored session sharing [session]'s id — used by the library
  /// for rename / colour / move edits. Does nothing if it no longer exists.
  static Future<void> update(SavedSession session) async {
    final list = await load();
    final i = list.indexWhere((s) => s.id == session.id);
    if (i == -1) return;
    list[i] = session;
    await _write(list);
  }

  /// Overwrites the whole store — used by the library after a bulk edit, such
  /// as deleting a folder and returning its sessions to the root.
  static Future<void> overwrite(List<SavedSession> list) async {
    await _write(List.of(list));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    count.value = 0;
    latest.value = null;
  }

  static Future<void> _write(List<SavedSession> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, SavedSession.encodeList(list));
    count.value = list.length;
    final sorted = List.of(list)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    latest.value = sorted.isNotEmpty ? sorted.first : null;
  }
}
