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

/// The chord game types. `lab` is the customized Chord Lab, which rotates
/// through the [ChordLabRound] variations within one session.
enum ChordGameType { name, build, lab }

/// The four round types Chord Lab rotates through (equal random, anti-repeat).
enum ChordLabRound {
  /// A shape lights up — pick its name from the choice grid.
  name,

  /// A partial shape is shown (1–2 notes hidden) — tap the missing note(s).
  complete,

  /// A valid shape plus one wrong note — tap the note that doesn't belong.
  remove,

  /// A chord name + a highlighted fret region — build the shape there.
  build,
}

/// The 12 chromatic roots the trainer uses (sharps, matching note naming).
const List<String> kChromaticRoots = [
  'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#',
];

/// The curated, nameable tonalities offered in Chord Lab (raw library keys).
/// The library's full exotic set (slash chords, one-offs) is intentionally left
/// out — it belongs in the dictionary app, not a practice game.
const List<String> kChordLabTonalities = [
  'Major', 'm', '5', '6', 'm6', '7', 'm7', 'Maj7', 'mMaj7',
  'dim', 'dim7', 'aug', 'sus2', 'sus4', 'Add9', 'mAdd9',
  '9', 'm9', 'Maj9', '11', '13', 'm7b5',
];

/// Readable label for a Chord Lab tonality (the dropdown text).
const Map<String, String> kChordLabTonalityLabels = {
  'Major': 'Major', 'm': 'Minor', '5': 'Power (5)', '6': 'Sixth',
  'm6': 'Minor 6th', '7': 'Dominant 7th', 'm7': 'Minor 7th',
  'Maj7': 'Major 7th', 'mMaj7': 'Minor-Major 7th', 'dim': 'Diminished',
  'dim7': 'Diminished 7th', 'aug': 'Augmented', 'sus2': 'Sus2', 'sus4': 'Sus4',
  'Add9': 'Add9', 'mAdd9': 'Minor Add9', '9': 'Ninth', 'm9': 'Minor 9th',
  'Maj9': 'Major 9th', '11': 'Eleventh', '13': 'Thirteenth',
  'm7b5': 'Half-diminished (m7♭5)',
};

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
  'Add9': 'add9', 'mAdd9': 'm(add9)', 'Add2': 'add2', 'Add4': 'add4',
  'dim': 'dim', 'dim7': 'dim7', 'aug': 'aug', '+': 'aug',
  'm7b5': 'm7♭5', '7b9': '7♭9', '7sharp9': '7♯9', '7sharp5': '7♯5',
  '7b5': '7♭5', '6/9': '6/9', 'm6/9': 'm6/9',
};

/// Readable name for a chord quality, used by the Stats screen. Prefers the
/// curated Chord Lab labels, then the quality-name table, then a tidied symbol.
String chordQualityLabel(String tonality) =>
    kChordLabTonalityLabels[tonality] ??
    _qualityName[tonality] ??
    (_tonalitySuffix(tonality).isEmpty
        ? 'Major'
        : '${_tonalitySuffix(tonality)} chord');

/// Compact chord-symbol suffix for a tonality, exposed for the Stats screen
/// (e.g. "m7", "maj7", "" for a plain major).
String chordSuffixFor(String tonality) => _tonalitySuffix(tonality);

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

// ── Musical validation ───────────────────────────────────────────────────────
//
// A guard against bad data: a handful of voicings in the bundled library are
// musically wrong for their chord name (a Maj7 grip that omits the major 7th and
// collapses to a bare triad, a shape carrying a note that isn't in the chord,
// a rootless grip, …). Left in, they make the trainer "sometimes play a triad"
// or the wrong chord. Every voicing is checked against the chord's pitch-class
// spelling before it enters the pool; anything that doesn't fit is dropped.

/// Pitch class of each open string, in board-column order (col 0 = low-E string
/// 6 … col 5 = high-e string 1). C = 0, C# = 1, … B = 11.
const List<int> _openStringPc = [4, 9, 2, 7, 11, 4];

/// Pitch class of each canonical (sharp-spelled) root.
const Map<String, int> _rootPc = {
  'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5,
  'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11,
};

/// Every pitch class (relative to the root) a voicing of this tonality may
/// contain. A voicing with any note outside this set is rejected. Tonalities
/// absent from the map (slash chords, rare one-offs) skip validation and trust
/// the library as-is.
const Map<String, Set<int>> _allowedTones = {
  'Major': {0, 4, 7},
  'm': {0, 3, 7},
  'sus2': {0, 2, 7},
  'sus4': {0, 5, 7},
  'Add2': {0, 2, 4, 7},
  'Add9': {0, 2, 4, 7},
  'Add4': {0, 4, 5, 7},
  'Add11': {0, 4, 5, 7},
  'mAdd2': {0, 2, 3, 7},
  'mAdd9': {0, 2, 3, 7},
  'mAdd4': {0, 3, 5, 7},
  'Add2Add4': {0, 2, 4, 5, 7},
  'mAdd2Add4': {0, 2, 3, 5, 7},
  'aug': {0, 4, 8},
  '+': {0, 4, 8},
  'dim': {0, 3, 6, 9},
  'dim7': {0, 3, 6, 9},
  '5': {0, 7},
  '6': {0, 4, 7, 9},
  'm6': {0, 3, 7, 9},
  '6/9': {0, 2, 4, 7, 9},
  'm6/9': {0, 2, 3, 7, 9},
  '7': {0, 4, 7, 10},
  'm7': {0, 3, 7, 10},
  'Maj7': {0, 4, 7, 11},
  '7sus4': {0, 5, 7, 10},
  '7sus2': {0, 2, 7, 10},
  '7Add4': {0, 4, 5, 7, 10},
  'm7Add4': {0, 3, 5, 7, 10},
  '9': {0, 2, 4, 7, 10},
  'm9': {0, 2, 3, 7, 10},
  'Maj9': {0, 2, 4, 7, 11},
  '9sus4': {0, 2, 5, 7, 10},
  '11': {0, 2, 4, 5, 7, 10},
  'm11': {0, 2, 3, 5, 7, 10},
  'Maj11': {0, 2, 4, 5, 7, 11},
  '13': {0, 2, 4, 5, 7, 9, 10},
  'm13': {0, 2, 3, 5, 7, 9, 10},
  'Maj13': {0, 2, 4, 5, 7, 9, 11},
  '13sus4': {0, 2, 5, 7, 9, 10},
  'mMaj7': {0, 3, 7, 11},
  'mMaj9': {0, 2, 3, 7, 11},
  '7sharp9': {0, 3, 4, 7, 10},
  '7b9': {0, 1, 4, 7, 10},
  '7sharp5': {0, 4, 8, 10},
  '7b5': {0, 4, 6, 10},
  'm7sharp5': {0, 3, 8, 10},
  'm7b5': {0, 3, 6, 10},
  'Maj7sharp5': {0, 4, 8, 11},
  'Maj7b5': {0, 4, 6, 11},
  '9sharp5': {0, 2, 4, 8, 10},
  '9b5': {0, 2, 4, 6, 10},
  '+7': {0, 4, 8, 10},
  '+9': {0, 2, 4, 8, 10},
  '+7b9': {0, 1, 4, 8, 10},
  '+7sharp9': {0, 3, 4, 8, 10},
  '7sharp11': {0, 2, 4, 6, 7, 10},
  'Maj7sharp11': {0, 2, 4, 6, 7, 11},
  'm9b5': {0, 2, 3, 6, 10},
  'sus4sharp5': {0, 5, 8},
  'sus2b5': {0, 2, 6},
  'sus2sharp5': {0, 2, 8},
  '7b5sharp9': {0, 3, 4, 6, 10},
  '7sharp9b5': {0, 3, 4, 6, 10},
};

/// The tones (relative to the root) a voicing MUST contain to legitimately be
/// this chord: the root, the quality-defining 3rd/sus/alteration, and — for
/// named 6th/7th/altered chords — the tone that separates it from a plain triad.
/// The perfect 5th and colour extensions above the 7th (9/11/13) are omittable,
/// as guitarists routinely drop them. Absent tonalities skip this check.
const Map<String, Set<int>> _requiredTones = {
  'Major': {0, 4},
  'm': {0, 3},
  'sus2': {0, 2},
  'sus4': {0, 5},
  'Add2': {0, 2, 4},
  'Add9': {0, 2, 4},
  'Add4': {0, 4, 5},
  'Add11': {0, 4, 5},
  'mAdd2': {0, 2, 3},
  'mAdd9': {0, 2, 3},
  'mAdd4': {0, 3, 5},
  'Add2Add4': {0, 2, 4, 5},
  'mAdd2Add4': {0, 2, 3, 5},
  'aug': {0, 4, 8},
  '+': {0, 4, 8},
  'dim': {0, 3, 6},
  'dim7': {0, 3, 6, 9},
  '5': {0, 7},
  '6': {0, 4, 9},
  'm6': {0, 3, 9},
  '6/9': {0, 4, 9},
  'm6/9': {0, 3, 9},
  '7': {0, 4, 10},
  'm7': {0, 3, 10},
  'Maj7': {0, 4, 11},
  '7sus4': {0, 5, 10},
  '7sus2': {0, 2, 10},
  '7Add4': {0, 4, 10},
  'm7Add4': {0, 3, 10},
  '9': {0, 4, 10},
  'm9': {0, 3, 10},
  'Maj9': {0, 4, 11},
  '9sus4': {0, 5, 10},
  '11': {0, 5, 10},
  'm11': {0, 3, 5, 10},
  'Maj11': {0, 4, 11},
  '13': {0, 4, 9, 10},
  'm13': {0, 3, 9, 10},
  'Maj13': {0, 4, 9, 11},
  '13sus4': {0, 5, 9, 10},
  'mMaj7': {0, 3, 11},
  'mMaj9': {0, 3, 11},
  '7sharp9': {0, 3, 4, 10},
  '7b9': {0, 1, 4, 10},
  '7sharp5': {0, 4, 8, 10},
  '7b5': {0, 4, 6, 10},
  'm7sharp5': {0, 3, 8, 10},
  'm7b5': {0, 3, 6, 10},
  'Maj7sharp5': {0, 4, 8, 11},
  'Maj7b5': {0, 4, 6, 11},
  '9sharp5': {0, 4, 8, 10},
  '9b5': {0, 4, 6, 10},
  '+7': {0, 4, 8, 10},
  '+9': {0, 4, 8, 10},
  '+7b9': {0, 1, 4, 8, 10},
  '+7sharp9': {0, 3, 4, 8, 10},
  '7sharp11': {0, 4, 6, 10},
  'Maj7sharp11': {0, 4, 6, 11},
  'm9b5': {0, 3, 6, 10},
  'sus4sharp5': {0, 5, 8},
  'sus2b5': {0, 2, 6},
  'sus2sharp5': {0, 2, 8},
  '7b5sharp9': {0, 3, 4, 6, 10},
  '7sharp9b5': {0, 3, 4, 6, 10},
};

/// True if [frets] is a musically legitimate voicing of [root] [tonality]:
/// it contains no note foreign to the chord and includes every required tone.
/// Unknown tonalities (slash chords, one-offs) are trusted and always pass.
bool _voicingFitsChord(String root, String tonality, List<int?> frets) {
  final allowed = _allowedTones[tonality];
  final required = _requiredTones[tonality];
  if (allowed == null || required == null) return true; // exotic — trust data
  final rootPc = _rootPc[root];
  if (rootPc == null) return true;

  final relative = <int>{};
  for (var col = 0; col < 6; col++) {
    final f = frets[col];
    if (f != null) relative.add((_openStringPc[col] + f - rootPc) % 12);
  }
  // No note outside the chord, and nothing characteristic missing.
  if (relative.difference(allowed).isNotEmpty) return false;
  return required.every(relative.contains);
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

// ── ChordLabPrompt ─────────────────────────────────────────────────────────

/// One Chord Lab round: which variation, the target chord, the notes on the
/// board at the start, which of them are locked, the fretted sets that count as
/// a win, and (for [ChordLabRound.build]) the highlighted region.
class ChordLabPrompt {
  ChordLabPrompt({
    required this.round,
    required this.target,
    required this.locked,
    required this.initial,
    required this.acceptable,
    this.regionLo,
    this.regionHi,
  });

  final ChordLabRound round;
  final ChordShape target;

  /// Shown notes the user cannot toggle (the given part of a Complete round).
  final Set<int> locked;

  /// Fretted board indices lit at the start (Remove: a valid voicing + one
  /// wrong note; Complete: the given part; Name: the display shape; Build: none).
  final Set<int> initial;

  /// Fretted-index sets that count as a solved chord for this round.
  final List<Set<int>> acceptable;

  /// Build round only: inclusive fret band the shape must sit within.
  final int? regionLo;
  final int? regionHi;
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

      final root = _canonicalRoot(model.root);

      final variations = <List<int?>>[];
      for (final v in model.variations) {
        final frets = _parseFrets(v.positions);
        if (frets == null) continue;
        // A buildable shape needs at least one fretted note.
        if (frettedBoardIndices(frets).isEmpty) continue;
        // Drop voicings that don't musically match the chord (bad data that
        // would otherwise play a triad or a wrong chord).
        if (!_voicingFitsChord(root, model.tonality, frets)) continue;
        variations.add(frets);
      }
      if (variations.isEmpty) continue;

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
    return _shapeFor(entry, window);
  }

  /// Builds a [ChordShape] for [entry] within [window]: a random in-window
  /// display voicing plus every in-window voicing as an accepted build.
  ChordShape _shapeFor(_ChordEntry entry, int window) {
    final inWindow =
        entry.variations.where((f) => _maxFret(f) <= window).toList();
    final display = inWindow.isNotEmpty
        ? inWindow[_rng.nextInt(inWindow.length)]
        : (List<List<int?>>.from(entry.variations)
              ..sort((a, b) => _maxFret(a).compareTo(_maxFret(b))))
            .first;

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

  // ── Chord Lab ──────────────────────────────────────────────────────────────

  Set<String> get _presentRoots => {for (final e in _entries) e.root};
  Set<String> get _presentTonalities => {for (final e in _entries) e.tonality};

  /// Roots that actually exist in the library, in chromatic order.
  List<String> get labRoots =>
      kChromaticRoots.where(_presentRoots.contains).toList();

  /// Curated tonalities that actually exist in the library.
  List<String> get labTonalities =>
      kChordLabTonalities.where(_presentTonalities.contains).toList();

  /// Picks a target chord for Chord Lab: any entry whose root and tonality are
  /// both selected and that has a voicing inside the difficulty window. Returns
  /// null only when nothing in the whole selection fits.
  ChordShape? _pickLabShape({
    required ChordDifficulty difficulty,
    required Set<String> keys,
    required Set<String> tonalities,
  }) {
    final window = _fretWindow(difficulty);
    final candidates = _entries
        .where((e) =>
            keys.contains(e.root) &&
            tonalities.contains(e.tonality) &&
            e.variations.any((f) => _maxFret(f) <= window))
        .toList();
    if (candidates.isEmpty) return null;
    var entry = candidates[_rng.nextInt(candidates.length)];
    if (candidates.length > 1 && entry.symbol == _lastSymbol) {
      entry = candidates[_rng.nextInt(candidates.length)];
    }
    return _shapeFor(entry, window);
  }

  /// Name-round choices: distractors drawn from the whole (nameable) vocabulary
  /// so there are always four confusable options, even from a tiny selection.
  List<String> labChoices(ChordShape correct, {int count = 4}) {
    final sameRoot = <String>{};
    final sameQuality = <String>{};
    final others = <String>{};
    for (final e in _entries) {
      if (e.tonality.contains('/')) continue; // slash chords read confusingly
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
    return <String>[correct.symbol, ...distractors.take(count - 1)]
      ..shuffle(_rng);
  }

  /// Generates the next Chord Lab round. Tries a handful of targets, and for
  /// each a random round type (avoiding [avoid] where possible), until one is
  /// buildable. Returns null only if the whole selection has nothing playable.
  ChordLabPrompt? nextLabPrompt({
    required ChordDifficulty difficulty,
    required Set<String> keys,
    required Set<String> tonalities,
    required Set<ChordLabRound> rounds,
    ChordLabRound? avoid,
  }) {
    final allowed =
        rounds.isEmpty ? ChordLabRound.values.toSet() : rounds;
    for (var attempt = 0; attempt < 40; attempt++) {
      final shape =
          _pickLabShape(difficulty: difficulty, keys: keys, tonalities: tonalities);
      if (shape == null) return null;

      final order = [...allowed]..shuffle(_rng);
      // Push the just-played round to the back so types alternate.
      order.sort((a, b) => (a == avoid ? 1 : 0) - (b == avoid ? 1 : 0));

      for (final round in order) {
        final prompt = _buildLabRound(round, shape, difficulty);
        if (prompt != null) {
          _lastSymbol = shape.symbol;
          return prompt;
        }
      }
    }
    return null;
  }

  ChordLabPrompt? _buildLabRound(
      ChordLabRound round, ChordShape shape, ChordDifficulty difficulty) {
    final sets = shape.acceptableFrettedSets.where((s) => s.isNotEmpty).toList();
    if (sets.isEmpty) return null;
    final window = _fretWindow(difficulty);

    switch (round) {
      case ChordLabRound.name:
        return ChordLabPrompt(
          round: round,
          target: shape,
          locked: shape.frettedIndices,
          initial: shape.frettedIndices,
          acceptable: sets, // used only to validate the shown shape
        );

      case ChordLabRound.complete:
        final voicing = _bigEnough(sets, 2);
        if (voicing == null) return null;
        final k = difficulty == ChordDifficulty.hard
            ? min(2, voicing.length - 1)
            : 1;
        final hidden = (voicing.toList()..shuffle(_rng)).take(k).toSet();
        final given = voicing.difference(hidden);
        if (given.isEmpty) return null;
        return ChordLabPrompt(
          round: round,
          target: shape,
          locked: given,
          initial: given,
          acceptable: sets,
        );

      case ChordLabRound.remove:
        final voicing = _bigEnough(sets, 1);
        if (voicing == null) return null;
        final extra = _pickExtraNote(voicing, sets, window);
        if (extra == null) return null;
        return ChordLabPrompt(
          round: round,
          target: shape,
          locked: const {},
          initial: {...voicing, extra},
          acceptable: sets,
        );

      case ChordLabRound.build:
        final voicing = _bigEnough(sets, 2) ?? sets.first;
        final frets = voicing.map((i) => i ~/ 6);
        final lo = frets.reduce(min);
        final hi = frets.reduce(max);
        final inRegion = sets
            .where((s) => s.every((i) {
                  final f = i ~/ 6;
                  return f >= lo && f <= hi;
                }))
            .toList();
        if (inRegion.isEmpty) return null;
        return ChordLabPrompt(
          round: round,
          target: shape,
          locked: const {},
          initial: const {},
          acceptable: inRegion,
          regionLo: lo,
          regionHi: hi,
        );
    }
  }

  /// A random acceptable set with at least [min] notes, or null.
  Set<int>? _bigEnough(List<Set<int>> sets, int min) {
    final big = sets.where((s) => s.length >= min).toList();
    if (big.isEmpty) return null;
    return big[_rng.nextInt(big.length)];
  }

  /// A "wrong" fretted note to graft onto [voicing] for the Remove round: on a
  /// string the voicing doesn't use, within the fret window, and not forming a
  /// bigger valid voicing. Null if no clean choice exists.
  int? _pickExtraNote(Set<int> voicing, List<Set<int>> sets, int window) {
    final usedCols = voicing.map((i) => i % 6).toSet();
    final freeCols = [for (var c = 0; c < 6; c++) if (!usedCols.contains(c)) c]
      ..shuffle(_rng);
    for (final col in freeCols) {
      for (var attempt = 0; attempt < 8; attempt++) {
        final fret = 1 + _rng.nextInt(window); // 1..window
        final candidate = fret * 6 + col;
        final grafted = {...voicing, candidate};
        // Reject if the grafted set is itself an accepted voicing.
        if (sets.any((s) => s.length == grafted.length && s.containsAll(grafted))) {
          continue;
        }
        return candidate;
      }
    }
    return null;
  }
}
