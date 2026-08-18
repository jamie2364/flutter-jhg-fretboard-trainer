// utils/intervals.dart
//
// Music helpers for the interval-training modes. A fretboard position only
// carries a note *name*, but an interval is an exact semitone gap between two
// pitches — so we derive an absolute pitch from string + fret (standard tuning)
// and measure the gap from that.

import 'dart:math';

import 'package:fretboard/models/board_model.dart';

/// Open-string pitch as a MIDI note number, keyed by the app's string
/// numbering (1 = high e, 6 = low E) in standard tuning. E2=40 … E4=64.
const Map<int, int> kOpenStringMidi = {
  6: 40, // E2
  5: 45, // A2
  4: 50, // D3
  3: 55, // G3
  2: 59, // B3
  1: 64, // E4
};

/// Absolute pitch of a fretboard position, in semitones (MIDI value).
int absSemitone(BoardModel pos) =>
    (kOpenStringMidi[pos.string] ?? 0) + (pos.fret ?? 0);

/// Signed semitone gap from [a] to [b] (positive = [b] is higher).
int semitoneGap(BoardModel a, BoardModel b) =>
    absSemitone(b) - absSemitone(a);

/// One of the 13 intervals from unison to octave.
///
/// Named `MusicInterval` (not `Interval`) to avoid clashing with Flutter's
/// animation `Interval` from material.dart.
class MusicInterval {
  const MusicInterval(this.semitones, this.name, this.short);

  /// Distance in semitones (0 = unison … 12 = octave).
  final int semitones;

  /// Full display name, e.g. "Perfect 5th".
  final String name;

  /// Compact label for tight buttons, e.g. "P5".
  final String short;
}

/// The full catalog, indexed by semitone count.
const List<MusicInterval> kIntervals = [
  MusicInterval(0, 'Unison', 'P1'),
  MusicInterval(1, 'Minor 2nd', 'm2'),
  MusicInterval(2, 'Major 2nd', 'M2'),
  MusicInterval(3, 'Minor 3rd', 'm3'),
  MusicInterval(4, 'Major 3rd', 'M3'),
  MusicInterval(5, 'Perfect 4th', 'P4'),
  MusicInterval(6, 'Tritone', 'TT'),
  MusicInterval(7, 'Perfect 5th', 'P5'),
  MusicInterval(8, 'Minor 6th', 'm6'),
  MusicInterval(9, 'Major 6th', 'M6'),
  MusicInterval(10, 'Minor 7th', 'm7'),
  MusicInterval(11, 'Major 7th', 'M7'),
  MusicInterval(12, 'Octave', 'P8'),
];

/// The interval whose compact label is [short] (e.g. "P5"), or null.
MusicInterval? intervalForShort(String short) {
  for (final i in kIntervals) {
    if (i.short == short) return i;
  }
  return null;
}

/// The interval for a (signed or unsigned) semitone [gap], or null if out of
/// the unison..octave range.
MusicInterval? intervalForGap(int gap) {
  final abs = gap.abs();
  if (abs > 12) return null;
  return kIntervals[abs];
}

/// Difficulty controls how far apart the two notes may sit and whether the
/// interval may descend. The full 13-interval catalog is available at every
/// level — difficulty only widens the spatial spread.
enum IntervalDifficulty { easy, medium, hard }

/// The two interval game types:
///   name  — two notes are shown, the user picks the interval name (buttons).
///   build — a root note + an interval name are shown, the user taps the fret
///           that lands that interval away.
enum IntervalGameType { name, build }

/// A generated interval question: the [root] note, the [target] note, and the
/// [interval] between them.
class IntervalPrompt {
  const IntervalPrompt(this.root, this.target, this.interval);

  final BoardModel root;
  final BoardModel target;
  final MusicInterval interval;
}

/// Picks a random valid interval pair from [board], honouring the active
/// strings and difficulty:
///   easy   — both notes on the same string, ascending
///   medium — same or adjacent string, ascending
///   hard   — any two positions, either direction
///
/// [isStringActive] mirrors HomeController.getStringStatus so muted strings are
/// excluded. Returns null only if no valid pair exists (e.g. one active string
/// under medium/easy leaves too few options).
IntervalPrompt? pickIntervalPrompt(
  List<BoardModel> board, {
  required IntervalDifficulty difficulty,
  required bool Function(int string) isStringActive,
  Set<int>? allowedSemitones,
  Random? rng,
}) {
  final r = rng ?? Random();
  final active =
      board.where((b) => isStringActive(b.string ?? 0)).toList();
  if (active.length < 2) return null;

  for (var attempt = 0; attempt < 600; attempt++) {
    final root = active[r.nextInt(active.length)];
    final target = active[r.nextInt(active.length)];
    if (identical(root, target)) continue;

    final gap = semitoneGap(root, target);
    if (gap.abs() > 12) continue;
    // Restrict to the intervals the user chose to practise (null = all).
    if (allowedSemitones != null && !allowedSemitones.contains(gap.abs())) {
      continue;
    }

    switch (difficulty) {
      case IntervalDifficulty.easy:
        if (root.string != target.string) continue;
        if (gap <= 0) continue; // ascending, non-unison
      case IntervalDifficulty.medium:
        if (((root.string ?? 0) - (target.string ?? 0)).abs() > 1) continue;
        if (gap <= 0) continue;
      case IntervalDifficulty.hard:
        if (gap == 0) continue; // skip same-pitch unison duplicates
    }

    return IntervalPrompt(root, target, kIntervals[gap.abs()]);
  }
  return null;
}

/// Builds a shuffled multiple-choice set: the [correct] interval plus
/// [count]-1 distractors drawn from the catalog.
List<MusicInterval> intervalChoices(MusicInterval correct,
    {int count = 4, Random? rng}) {
  final r = rng ?? Random();
  final pool = List<MusicInterval>.from(kIntervals)
    ..removeWhere((i) => i.semitones == correct.semitones)
    ..shuffle(r);
  final choices = <MusicInterval>[correct, ...pool.take(count - 1)]..shuffle(r);
  return choices;
}
