// services/practice_stats_service.dart
//
// Accuracy tracking for the non-note training modes (Intervals, Chords, Chord
// Lab). The note modes keep their own per-fret store in HeatmapService; this
// service records "how well do you know each interval / chord quality / lab
// round" so the Stats screen can show real strong/weak areas.
//
// Storage: SharedPreferences, one attempts+correct pair per (module, key).
// Keys are opaque strings the caller namespaces with a short dimension prefix,
// e.g. "q:Maj7" (by quality), "mode:build" (by game type), "round:complete"
// (by Chord Lab round). Everything under a module is scanned back by prefix, so
// new dimensions can be added later without touching this file.

import 'package:shared_preferences/shared_preferences.dart';

/// Accuracy for a single tracked item (one interval, one chord quality, …).
class StatEntry {
  const StatEntry({required this.attempts, required this.correct});

  final int attempts;
  final int correct;

  bool get hasData => attempts > 0;
  double get accuracy => attempts == 0 ? 0.0 : correct / attempts;

  StatEntry plus(bool wasCorrect) => StatEntry(
        attempts: attempts + 1,
        correct: correct + (wasCorrect ? 1 : 0),
      );
}

/// A module's raw entries split into the dimensions the Stats screen shows:
/// by quality (which interval / chord), by game type (name vs build), and — for
/// Chord Lab — by round type (Name / Complete / Remove / Build).
class ModuleBreakdown {
  const ModuleBreakdown({
    required this.byQuality,
    required this.byMode,
    required this.byRound,
  });

  final Map<String, StatEntry> byQuality;
  final Map<String, StatEntry> byMode;
  final Map<String, StatEntry> byRound;

  static const empty = ModuleBreakdown(byQuality: {}, byMode: {}, byRound: {});

  factory ModuleBreakdown.from(Map<String, StatEntry> raw) {
    final q = <String, StatEntry>{};
    final m = <String, StatEntry>{};
    final r = <String, StatEntry>{};
    raw.forEach((key, entry) {
      if (key.startsWith('q:')) {
        q[key.substring(2)] = entry;
      } else if (key.startsWith('mode:')) {
        m[key.substring(5)] = entry;
      } else if (key.startsWith('round:')) {
        r[key.substring(6)] = entry;
      }
    });
    return ModuleBreakdown(byQuality: q, byMode: m, byRound: r);
  }

  // The richest populated dimension covers every attempt (each graded answer
  // records both a "q:" and a "mode:"/"round:" key). Notes only have "mode:".
  Map<String, StatEntry> get _canonical => byQuality.isNotEmpty
      ? byQuality
      : (byRound.isNotEmpty ? byRound : byMode);

  int get totalAttempts =>
      _canonical.values.fold(0, (s, e) => s + e.attempts);
  int get totalCorrect =>
      _canonical.values.fold(0, (s, e) => s + e.correct);
  double get accuracy =>
      totalAttempts == 0 ? 0.0 : totalCorrect / totalAttempts;
  bool get hasData => totalAttempts > 0;

  /// Quality entries sorted weakest-first (lowest accuracy on top), so the
  /// thing most worth practising leads the list. Ties broken by most attempts.
  List<MapEntry<String, StatEntry>> get qualitiesWeakestFirst {
    final list = byQuality.entries.toList();
    list.sort((a, b) {
      final byAcc = a.value.accuracy.compareTo(b.value.accuracy);
      if (byAcc != 0) return byAcc;
      return b.value.attempts.compareTo(a.value.attempts);
    });
    return list;
  }

  /// The strongest quality (highest accuracy, needs ≥1 attempt), or null.
  MapEntry<String, StatEntry>? get strongest {
    final list = qualitiesWeakestFirst;
    return list.isEmpty ? null : list.last;
  }

  /// The weakest quality, or null when there's no data.
  MapEntry<String, StatEntry>? get weakest {
    final list = qualitiesWeakestFirst;
    return list.isEmpty ? null : list.first;
  }
}

/// The modules tracked here. String values are the on-disk namespaces. (Notes
/// keep their per-fret store in HeatmapService; this only records the Notes
/// Find-vs-Identify game-type split.)
enum StatsModule { note, interval, chord, chordLab }

extension StatsModuleKey on StatsModule {
  String get key {
    switch (this) {
      case StatsModule.note:
        return 'note';
      case StatsModule.interval:
        return 'interval';
      case StatsModule.chord:
        return 'chord';
      case StatsModule.chordLab:
        return 'chordlab';
    }
  }
}

class PracticeStatsService {
  static const String _root = 'ps_'; // ps_<module>_<key>_a / _c

  static String _attKey(String module, String key) => '$_root${module}_${key}_a';
  static String _corKey(String module, String key) => '$_root${module}_${key}_c';

  /// Records one graded attempt for [key] within [module]. Fire-and-forget.
  static Future<void> record(
      StatsModule module, String key, bool correct) async {
    final prefs = await SharedPreferences.getInstance();
    final m = module.key;
    final att = (prefs.getInt(_attKey(m, key)) ?? 0) + 1;
    final cor = (prefs.getInt(_corKey(m, key)) ?? 0) + (correct ? 1 : 0);
    await prefs.setInt(_attKey(m, key), att);
    await prefs.setInt(_corKey(m, key), cor);
  }

  /// Records the same result against several keys at once (e.g. by-quality and
  /// by-mode for one answer).
  static Future<void> recordAll(
      StatsModule module, List<String> keys, bool correct) async {
    for (final k in keys) {
      await record(module, k, correct);
    }
  }

  /// All tracked entries for [module], keyed by the caller's full key
  /// ("q:Maj7", "mode:build", …).
  static Future<Map<String, StatEntry>> load(StatsModule module) async {
    final prefs = await SharedPreferences.getInstance();
    final m = module.key;
    final attPrefix = '$_root${m}_';
    final result = <String, StatEntry>{};
    for (final storeKey in prefs.getKeys()) {
      if (!storeKey.startsWith(attPrefix) || !storeKey.endsWith('_a')) continue;
      // Strip "ps_<module>_" … "_a" to recover the caller's key.
      final key = storeKey.substring(attPrefix.length, storeKey.length - 2);
      final att = prefs.getInt(storeKey) ?? 0;
      final cor = prefs.getInt(_corKey(m, key)) ?? 0;
      if (att > 0) result[key] = StatEntry(attempts: att, correct: cor);
    }
    return result;
  }

  /// Convenience: [load] split into the Stats screen's dimensions.
  static Future<ModuleBreakdown> loadBreakdown(StatsModule module) async =>
      ModuleBreakdown.from(await load(module));

  /// Wipes every stat for [module].
  static Future<void> clear(StatsModule module) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_root${module.key}_';
    final doomed = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in doomed) {
      await prefs.remove(k);
    }
  }
}
