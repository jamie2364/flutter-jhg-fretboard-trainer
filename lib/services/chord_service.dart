// services/chord_service.dart
//
// Loads the bundled chord library and parses it off the UI thread. No audio —
// the trainer plays chords by strumming the individual fret sounds already on
// each BoardModel (see HomeController._playChord).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/chord_model.dart';

class ChordService {
  static const String _assetPath =
      'assets/dictionary/restructured_chordlibrary.json';

  Map<String, ChordModel> _cache = {};

  /// Parsed chord library, keyed by chord id (e.g. "C", "Cm", "Cmaj7").
  /// Cached after the first load.
  Future<Map<String, ChordModel>> getData() async {
    if (_cache.isNotEmpty) return _cache;
    final data = await rootBundle.loadString(_assetPath);
    _cache = await compute(_parseJson, data);
    return _cache;
  }

  static Map<String, ChordModel> _parseJson(String jsonString) {
    final Map<String, dynamic> jsonMap =
        json.decode(jsonString) as Map<String, dynamic>;
    return jsonMap.map(
      (key, value) =>
          MapEntry(key, ChordModel.fromMap(value as Map<String, dynamic>)),
    );
  }
}
