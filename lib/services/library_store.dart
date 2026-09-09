// services/library_store.dart
//
// Persists the Saved Sessions library folder tree in SharedPreferences. The
// sessions themselves (and their folder assignment) are owned by
// SavedSessionsService; this only stores the lightweight folder layer.

import 'dart:convert';

import 'package:fretboard/models/library_folder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryStore {
  static const _foldersKey = 'fretboard_library_folders_v1';

  Future<List<LibraryFolder>> loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_foldersKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              LibraryFolder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFolders(List<LibraryFolder> folders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _foldersKey, jsonEncode(folders.map((f) => f.toJson()).toList()));
  }
}
