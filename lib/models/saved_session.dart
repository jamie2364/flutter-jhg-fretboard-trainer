// models/saved_session.dart
//
// A snapshot of an in-progress practice session so the player can leave and
// pick it up later. Captures the full configuration (mode, game type,
// difficulty, strings, and the interval / chord-lab filters) plus the live
// score and clock, so a restore drops the user back exactly where they left off.

import 'dart:convert';

class SavedSession {
  const SavedSession({
    required this.id,
    required this.createdAt,
    required this.gameMode,
    required this.intervalGameType,
    required this.chordGameType,
    required this.intervalDifficulty,
    required this.chordDifficulty,
    required this.strings,
    required this.selectedIntervals,
    required this.chordLabKeys,
    required this.chordLabTonalities,
    required this.chordLabRounds,
    required this.timerMode,
    required this.timerIntervalValue,
    required this.score,
    required this.secondsRemaining,
    required this.title,
    required this.subtitle,
    this.folderId,
    this.colorValue,
    this.customName,
  });

  /// Unique id (millisecond timestamp string).
  final String id;
  final DateTime createdAt;

  // ── Restore payload ──────────────────────────────────────────────────────
  final String gameMode; // currentGameMode: reverse|interval|chord|stopwatch|countdown
  final int intervalGameType; // IntervalGameType index
  final int chordGameType; // ChordGameType index
  final int intervalDifficulty; // IntervalDifficulty index
  final int chordDifficulty; // ChordDifficulty index
  final List<bool> strings; // [string1..string6]
  final List<int> selectedIntervals; // semitones
  final List<String> chordLabKeys;
  final List<String> chordLabTonalities;
  final List<String> chordLabRounds; // ChordLabRound.name values
  final String timerMode; // stopwatch|countdown
  final int timerIntervalValue; // seconds (countdown length)
  final int score;
  final int secondsRemaining;

  // ── Precomputed display (so the list is cheap) ───────────────────────────
  final String title; // e.g. "Name the Interval"
  final String subtitle; // e.g. "Medium · 3 strings"

  // ── Library metadata (folder organisation + macOS-style tinting) ─────────
  /// Id of the library folder this session lives in. Null = library root.
  final String? folderId;

  /// Optional user-picked tint (ARGB int). Null = the default colour.
  final int? colorValue;

  /// Name the user typed when saving or renaming. Null = fall back to [title].
  final String? customName;

  /// The name shown in the library: the user's own name if they gave one,
  /// otherwise the auto-generated [title].
  String get displayName =>
      (customName != null && customName!.trim().isNotEmpty)
          ? customName!
          : title;

  SavedSession copyWith({
    String? folderId,
    bool clearFolder = false,
    int? colorValue,
    bool clearColor = false,
    String? customName,
    bool clearCustomName = false,
  }) =>
      SavedSession(
        id: id,
        createdAt: createdAt,
        gameMode: gameMode,
        intervalGameType: intervalGameType,
        chordGameType: chordGameType,
        intervalDifficulty: intervalDifficulty,
        chordDifficulty: chordDifficulty,
        strings: strings,
        selectedIntervals: selectedIntervals,
        chordLabKeys: chordLabKeys,
        chordLabTonalities: chordLabTonalities,
        chordLabRounds: chordLabRounds,
        timerMode: timerMode,
        timerIntervalValue: timerIntervalValue,
        score: score,
        secondsRemaining: secondsRemaining,
        title: title,
        subtitle: subtitle,
        folderId: clearFolder ? null : (folderId ?? this.folderId),
        colorValue: clearColor ? null : (colorValue ?? this.colorValue),
        customName: clearCustomName ? null : (customName ?? this.customName),
      );

  /// Coarse mode bucket used by the Saved Sessions filter chips.
  String get modeGroup {
    switch (gameMode) {
      case 'interval':
        return 'Intervals';
      case 'chord':
        return 'Chords';
      default:
        return 'Notes'; // reverse / stopwatch / countdown are all note games
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'gameMode': gameMode,
        'intervalGameType': intervalGameType,
        'chordGameType': chordGameType,
        'intervalDifficulty': intervalDifficulty,
        'chordDifficulty': chordDifficulty,
        'strings': strings,
        'selectedIntervals': selectedIntervals,
        'chordLabKeys': chordLabKeys,
        'chordLabTonalities': chordLabTonalities,
        'chordLabRounds': chordLabRounds,
        'timerMode': timerMode,
        'timerIntervalValue': timerIntervalValue,
        'score': score,
        'secondsRemaining': secondsRemaining,
        'title': title,
        'subtitle': subtitle,
        'folderId': folderId,
        'colorValue': colorValue,
        'customName': customName,
      };

  factory SavedSession.fromJson(Map<String, dynamic> j) => SavedSession(
        id: j['id'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
        gameMode: j['gameMode'] as String? ?? 'stopwatch',
        intervalGameType: (j['intervalGameType'] as num?)?.toInt() ?? 0,
        chordGameType: (j['chordGameType'] as num?)?.toInt() ?? 0,
        intervalDifficulty: (j['intervalDifficulty'] as num?)?.toInt() ?? 0,
        chordDifficulty: (j['chordDifficulty'] as num?)?.toInt() ?? 0,
        strings: ((j['strings'] as List?) ?? const [])
            .map((e) => e == true)
            .toList()
            .let6(),
        selectedIntervals: ((j['selectedIntervals'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        chordLabKeys: ((j['chordLabKeys'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        chordLabTonalities: ((j['chordLabTonalities'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        chordLabRounds: ((j['chordLabRounds'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        timerMode: j['timerMode'] as String? ?? 'stopwatch',
        timerIntervalValue: (j['timerIntervalValue'] as num?)?.toInt() ?? 60,
        score: (j['score'] as num?)?.toInt() ?? 0,
        secondsRemaining: (j['secondsRemaining'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? 'Practice session',
        subtitle: j['subtitle'] as String? ?? '',
        folderId: j['folderId'] as String?,
        colorValue: (j['colorValue'] as num?)?.toInt(),
        customName: j['customName'] as String?,
      );

  static String encodeList(List<SavedSession> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<SavedSession> decodeList(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(SavedSession.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

extension _Six on List<bool> {
  // Guards against a malformed store: always hand back exactly six flags.
  List<bool> let6() {
    final out = List<bool>.filled(6, true);
    for (var i = 0; i < 6 && i < length; i++) {
      out[i] = this[i];
    }
    return out;
  }
}
