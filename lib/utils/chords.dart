// utils/chords.dart
//
// Training-logic layer for the Chord mode. The bundled chord library
// (restructured_chordlibrary.json, parsed by ChordService) is turned into a
// pool of playable [ChordShape]s, filtered by difficulty. Two game types mirror
// the Intervals mode:
//   name  — a chord shape lights up on the neck, the user picks its name.
//   build — a chord name is shown, the user taps the frets to place the shape.
//
// Board geometry note: the trainer's fretList is laid out as fret*6 + col, where
// col 0 = low-E (string 6) and col 5 = high-e (string 1). A chord's position
// string "x,3,2,0,1,0" is already in strings 6→1 order, so token index == col.

import 'dart:math';

import 'package:fretboard/models/chord_model.dart';

/// Highest fret drawn on the trainer board (frets 0..15).
const int kMaxBoardFret = 15;

/// Difficulty widens both the chord vocabulary and how high up the neck a shape
/// may sit:
///   easy   — Major / minor triads, open or low positions (≤ fret 4).
///   medium — adds 7ths, sixths, sus, add9, dim, aug (≤ fret 9).
///   hard   — the full catalog of standard qualities, anywhere up to fret 15.
enum ChordDifficulty { easy, medium, hard }

/// The two chord game types.
enum ChordGameType { name, build }

int _fretWindow(ChordDifficulty d) {
  switch (d) {
    case ChordDifficulty.easy:
      return 4;
    case ChordDifficulty.medium:
      return 9;
    case ChordDifficulty.hard:
      return kMaxBoardFret;
  }
}

/// Tonalities unlocked at Easy (also included at Medium/Hard).
const Set<String> _easyTonalities = {'Major', 'm'};

/// Extra tonalities unlocked at Medium (added to the Easy set).
const Set<String> _mediumExtra = {
  '7', 'Maj7', 'm7', 'sus2', 'sus4', '5', '6', 'm6', 'Add9', 'dim', 'aug',
};

bool _tonalityAllowed(String tonality, ChordDifficulty d) {
  switch (d) {
    case ChordDifficulty.easy:
      return _easyTonalities.contains(tonality);
    case ChordDifficulty.medium:
      return _easyTonalities.contains(tonality) ||
          _mediumExtra.contains(tonality);
    case ChordDifficulty.hard:
      // Everything except slash / inversion chords (e.g. "/a", "m/c"), which
      // read confusingly as a training target.
      return !tonality.contains('/');
  }
}

// ── Display names ────────────────────────────────────────────────────────────

/// Root spelled with sharps, matching the trainer's note naming ("Csharp"→"C#").
String _canonicalRoot(String root) => root.replaceAll('sharp', '#');

/// Compact chord-symbol suffix for a tonality (Major → "", m7 → "m7").
const Map<String, String> _suffix = {
  'Major': '', 'm': 'm', '5': '5', '6': '6', 'm6': 'm6',
  '7': '7', 'm7': 'm7', 'Maj7': 'maj7', 'mMaj7': 'm(maj7)',
  '9': '9', 'm9': 'm9', 'Maj9': 'maj9',
  '11': '11', 'm11': 'm11', 'Maj11': 'maj11',
  '13': '13', 'm13': 'm13', 'Maj13': 'maj13',
  'sus2': 'sus2', 'sus4': 'sus4',
  'Add9': 'add9', 'Add2': 'add2', 'Add4': 'add4',
  'dim': 'dim', 'dim7': 'dim7', 'aug': 'aug', '+': 'aug',
  'm7b5': 'm7♭5', '7b9': '7♭9', '7sharp9': '7♯9', '7sharp5': '7♯5',
  '7b5': '7♭5', '6/9': '6/9', 'm6/9': 'm6/9',
};

String _tonalitySuffix(String tonality) {
  final mapped = _suffix[tonality];
  if (mapped != null) return mapped;
  // Fallback: tidy sharps/flats in any unmapped exotic tonality.
  return tonality.replaceAll('sharp', '♯');
}

/// Human-readable quality for the prompt subtitle ("m7" → "Minor 7th").
const Map<String, String> _qualityName = {
  'Major': 'Major', 'm': 'Minor', '5': 'Power chord', '6': 'Major 6th',
  'm6': 'Minor 6th', '7': 'Dominant 7th', 'm7': 'Minor 7th',
  'Maj7': 'Major 7th', '9': 'Dominant 9th', 'm9': 'Minor 9th',
  'Maj9': 'Major 9th', '11': '11th', '13': '13th', 'sus2': 'Suspended 2nd',
  'sus4': 'Suspended 4th', 'Add9': 'Added 9th', 'dim': 'Diminished',
  'dim7': 'Diminished 7th', 'aug': 'Augmented',
};

// ── Position parsing ─────────────────────────────────────────────────────────

/// Parses a position string ("x,3,2,0,1,0", strings 6→1) into six nullable
/// frets (null = muted). Returns null if the string is malformed or references
/// a fret past the drawn board.
List<int?>? _parseFrets(String positions) {
  final tokens = positions.split(',');
  if (tokens.length != 6) return null;
  final frets = <int?>[];
  for (final raw in tokens) {
    final t = raw.trim();
    if (t == 'x' || t.isEmpty) {
      frets.add(null);
      continue;
    }
    final f = int.tryParse(t);
    if (f == null || f < 0 || f > kMaxBoardFret) return null;
    frets.add(f);
  }
  return frets;
}

int _maxFret(List<int?> frets) {
  var m = 0;
  for (final f in frets) {
    if (f != null && f > m) m = f;
  }
  return m;
}

/// Board (fretList) index for the note on [col] (0 = low-E) at [fret].
int boardIndex(int col, int fret) => fret * 6 + col;

/// Every non-muted board index in a shape (open strings included) — used to
/// draw the note balls.
List<int> shapeBoardIndices(List<int?> frets) {
  final out = <int>[];
  for (var col = 0; col < 6; col++) {
    final f = frets[col];
    if (f != null) out.add(boardIndex(col, f));
  }
  return out;
}

/// Only the *fretted* board indices (fret > 0) — the notes the user actually
/// presses. Used to grade Build mode (open/muted strings are ignored).
Set<int> frettedBoardIndices(List<int?> frets) {
  final out = <int>{};
  for (var col = 0; col < 6; col++) {
    final f = frets[col];
    if (f != null && f > 0) out.add(boardIndex(col, f));
  }
  return out;
}

// ── ChordShape ───────────────────────────────────────────────────────────────

/// One generated chord question: the display shape plus every fretted-note set
/// that counts as a correct build (any voicing of the same chord within the
/// difficulty's fret window).
class ChordShape {
  ChordShape({
    required this.root,
    required this.tonality,
    required this.symbol,
    required this.qualityName,
    required this.frets,
    required this.acceptableFrettedSets,
  });

  /// Root spelled with sharps, e.g. "C", "C#".
  final String root;

  /// Raw tonality key, e.g. "Major", "m7".
  final String tonality;

  /// Compact chord symbol for buttons/labels, e.g. "C", "Cm7".
  final String symbol;

  /// Readable quality for subtitles, e.g. "Minor 7th".
  final String qualityName;

  /// The shape shown on the neck (strings 6→1, null = muted).
  final List<int?> frets;

  /// Fretted board-index sets that count as a correct build.
  final List<Set<int>> acceptableFrettedSets;

  /// Board indices of every sounding note (for drawing balls).
  List<int> get boardIndices => shapeBoardIndices(frets);

  /// Fretted board indices of the display shape (fret > 0).
  Set<int> get frettedIndices => frettedBoardIndices(frets);
}

// ── Catalog ──────────────────────────────────────────────────────────────────

/// A chord in the catalog: its identity plus every playable (≤ fret 15)
/// voicing. Difficulty selection narrows these down at pick time.
class _ChordEntry {
  _ChordEntry(this.root, this.tonality, this.symbol, this.qualityName,
      this.variations);
  final String root;
  final String tonality;
  final String symbol;
  final String qualityName;
  final List<List<int?>> variations; // each strings 6→1, null = muted
}

/// Builds and serves the difficulty-filtered chord pools from parsed data.
class ChordCatalog {
  ChordCatalog(Map<String, ChordModel> data) {
    _build(data);
  }

  final List<_ChordEntry> _entries = [];
  final Map<ChordDifficulty, List<_ChordEntry>> _poolCache = {};
  final Random _rng = Random();
  String? _lastSymbol;

  void _build(Map<String, ChordModel> data) {
    for (final model in data.values) {
      // Skip flat-spelled roots so enharmonic duplicates (Bb vs A#) collapse to
      // the 12 sharp/natural roots the trainer uses.
      if (model.root.contains('b')) continue;

      final variations = <List<int?>>[];
      for (final v in model.variations) {
        final frets = _parseFrets(v.positions);
        if (frets == null) continue;
        // A buildable shape needs at least one fretted note.
        if (frettedBoardIndices(frets).isEmpty) continue;
        variations.add(frets);
      }
      if (variations.isEmpty) continue;

      final root = _canonicalRoot(model.root);
      _entries.add(_ChordEntry(
        root,
        model.tonality,
        '$root${_tonalitySuffix(model.tonality)}',
        _qualityName[model.tonality] ?? '${_tonalitySuffix(model.tonality)} chord'.trim(),
        variations,
      ));
    }
  }

  List<_ChordEntry> _pool(ChordDifficulty d) {
    return _poolCache.putIfAbsent(d, () {
      final window = _fretWindow(d);
      return _entries.where((e) {
        if (!_tonalityAllowed(e.tonality, d)) return false;
        // Must have at least one voicing inside this difficulty's fret window.
        return e.variations.any((frets) => _maxFret(frets) <= window);
      }).toList();
    });
  }

  /// True once at least one chord is available for [difficulty].
  bool hasChords(ChordDifficulty difficulty) => _pool(difficulty).isNotEmpty;

  /// Picks the next chord question for [difficulty], avoiding an immediate
  /// repeat. Returns null only if the pool is empty.
  ChordShape? pick(ChordDifficulty difficulty) {
    final pool = _pool(difficulty);
    if (pool.isEmpty) return null;
    final window = _fretWindow(difficulty);

    _ChordEntry entry = pool[_rng.nextInt(pool.length)];
    // One re-roll to dodge showing the same chord twice in a row.
    if (pool.length > 1 && entry.symbol == _lastSymbol) {
      entry = pool[_rng.nextInt(pool.length)];
    }
    _lastSymbol = entry.symbol;

    // Voicings that fit the difficulty window; fall back to the lowest voicing.
    final inWindow =
        entry.variations.where((f) => _maxFret(f) <= window).toList();
    final display = inWindow.isNotEmpty
        ? inWindow[_rng.nextInt(inWindow.length)]
        : (entry.variations..sort((a, b) => _maxFret(a).compareTo(_maxFret(b))))
            .first;

    // Any in-window voicing counts as a correct build.
    final acceptable = (inWindow.isNotEmpty ? inWindow : [display])
        .map(frettedBoardIndices)
        .where((s) => s.isNotEmpty)
        .toList();

    return ChordShape(
      root: entry.root,
      tonality: entry.tonality,
      symbol: entry.symbol,
      qualityName: entry.qualityName,
      frets: display,
      acceptableFrettedSets: acceptable,
    );
  }

  /// Multiple-choice set for Name mode: the [correct] symbol plus [count]-1
  /// distractors drawn from the same difficulty pool, biased toward the same
  /// root (other qualities) and the same quality (other roots) so choices are
  /// genuinely confusable.
  List<String> choices(
    ChordShape correct,
    ChordDifficulty difficulty, {
    int count = 4,
  }) {
    final pool = _pool(difficulty);
    final sameRoot = <String>{};
    final sameQuality = <String>{};
    final others = <String>{};
    for (final e in pool) {
      if (e.symbol == correct.symbol) continue;
      if (e.root == correct.root) {
        sameRoot.add(e.symbol);
      } else if (e.tonality == correct.tonality) {
        sameQuality.add(e.symbol);
      } else {
        others.add(e.symbol);
      }
    }

    final distractors = <String>[];
    void drain(Set<String> src) {
      final list = src.toList()..shuffle(_rng);
      for (final s in list) {
        if (distractors.length >= count - 1) break;
        if (!distractors.contains(s)) distractors.add(s);
      }
    }

    drain(sameRoot);
    drain(sameQuality);
    drain(others);

    final result = <String>[correct.symbol, ...distractors.take(count - 1)]
      ..shuffle(_rng);
    return result;
  }
}
