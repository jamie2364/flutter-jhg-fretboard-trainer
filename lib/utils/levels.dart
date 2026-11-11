// utils/levels.dart
//
// The "Level" of a Customized Practice session.
//
// A level is a PRESET over the difficulty knobs the three modes already have,
// not a second axis on top of them. Its headline is the fret window — how far
// up the neck the trainer may ask — because that is the part a player can see,
// and it is the thing that separates "I know open position" from "I can find
// anything on the neck". The vocabulary knobs (naturals only, small interval
// gaps, triad-only chords) move with it so a Beginner session cannot be handed
// an A♯ at the 11th fret.
//
// Quick start deliberately runs with NO level: it keeps the full neck, exactly
// as it always has.
//
// Naming: Easy / Medium / Hard, matching the difficulty steps that were already
// in the Notes / Intervals / Chords wizards. Internally these are still the
// existing ChordDifficulty / IntervalDifficulty tiers, so saved sessions and
// every generator keep working; [PracticeLevel.difficultyIndex] is the bridge.
//
// The levels are CUMULATIVE, mirroring the ear-training app: Medium adds to
// Easy, Hard adds to Medium.
//
// Board geometry note: HomeController.fretList is ordered fret-major with six
// columns per fret, so index = fret * 6 + column (column 0 = low-E string 6,
// column 5 = high-e string 1). See utils/chords.dart:boardIndex.

/// `easy` is the enum name (Dart keywords) — the UI label is "Easy".
enum PracticeLevel { easy, medium, hard }

/// The seven natural note names. Beginner note sessions ask only these, which
/// is the difference between "find G" being a real question and not.
const Set<String> kNaturalNoteNames = {
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
};

/// Highest fret drawn on the trainer board (0..15, 16 positions).
const int kMaxBoardFret = 15;

extension PracticeLevelX on PracticeLevel {
  /// Highest fret a prompt may sit on.
  ///
  /// Easy: 0–5 — open position plus the first-position frets, which is what a
  /// beginner's hand actually covers.
  /// Medium: 0–9 — adds the second/middle positions without the dusty end.
  /// Hard: 0–15 — the whole drawn neck.
  ///
  /// Note "within 5 frets" means `fret <= 5`, so a 5-fret Beginner span would
  /// be frets 1–5; including the open strings the easy window is frets 0–5.
  int get fretCap {
    switch (this) {
      case PracticeLevel.easy:
        return 5;
      case PracticeLevel.medium:
        return 9;
      case PracticeLevel.hard:
        return kMaxBoardFret;
    }
  }

  /// The window as the subtitle shows it, e.g. "Frets 0–5".
  String get fretRangeLabel {
    switch (this) {
      case PracticeLevel.easy:
        return 'Frets 0–5';
      case PracticeLevel.medium:
        return 'Frets 0–9';
      case PracticeLevel.hard:
        return 'Frets 0–15';
    }
  }

  /// "Easy" / "Medium" / "Hard" — used on saved sessions and the level cards.
  String get label {
    switch (this) {
      case PracticeLevel.easy:
        return 'Easy';
      case PracticeLevel.medium:
        return 'Medium';
      case PracticeLevel.hard:
        return 'Hard';
    }
  }

  /// One line under the label on the level card.
  String get description {
    switch (this) {
      case PracticeLevel.easy:
        return 'Open position only. Naturals, small interval gaps, open chords.';
      case PracticeLevel.medium:
        return 'Adds frets 6–9. Every note, wider gaps, 7ths and sus chords.';
      case PracticeLevel.hard:
        return 'The whole neck. Any interval in either direction, every chord.';
    }
  }

  /// What this level unlocks over the previous one — the card's "adds" badge.
  /// Easy is the baseline, so it names what is included instead.
  String get unlocks {
    switch (this) {
      case PracticeLevel.easy:
        return 'Open strings & frets 1–5';
      case PracticeLevel.medium:
        return 'Adds frets 6–9 and accidentals';
      case PracticeLevel.hard:
        return 'Adds frets 10–15 and every chord';
    }
  }

  /// Short two-chip summary shown on the card ("Frets 0–5", "Naturals only").
  List<String> get chips {
    switch (this) {
      case PracticeLevel.easy:
        return const ['Naturals only', 'Ascending gaps', 'Major & minor'];
      case PracticeLevel.medium:
        return const ['All 12 notes', 'Up the neck', '7ths, sus, add9'];
      case PracticeLevel.hard:
        return const ['Full neck', 'Any direction', 'All chord types'];
    }
  }

  /// Whether this level asks only the natural notes in Notes mode.
  bool get naturalNotesOnly => this == PracticeLevel.easy;

  /// The ordinal this level maps to in the legacy difficulty enums.
  ///
  /// `IntervalDifficulty` and `ChordDifficulty` both declare their values in
  /// exactly this order (`easy, medium, hard`), and that order is part of the
  /// saved-session schema (stored as an index). Exposing the ordinal instead of
  /// the enum keeps this file free of `intervals.dart` / `chords.dart` imports —
  /// both of those import *this* file, so referencing their enums here would be
  /// an import cycle — while letting callers convert in one line:
  /// `IntervalDifficulty.values[level.difficultyIndex]`.
  int get difficultyIndex {
    switch (this) {
      case PracticeLevel.easy:
        return 0;
      case PracticeLevel.medium:
        return 1;
      case PracticeLevel.hard:
        return 2;
    }
  }
}

/// Inverse bridge: the level matching a legacy difficulty enum index. For
/// callers that only know the old tier (an older saved session, the board's
/// in-place mode switcher) and need a level to describe it.
PracticeLevel practiceLevelForDifficultyIndex(int index) {
  if (index <= 0) return PracticeLevel.easy;
  if (index >= 2) return PracticeLevel.hard;
  return PracticeLevel.medium;
}

/// Parses a stored [PracticeLevel.name] back into a level. Unknown / missing
/// values (sessions saved before levels existed) return null, which the app
/// treats as "full board".
PracticeLevel? practiceLevelFromName(String? name) {
  if (name == null) return null;
  for (final level in PracticeLevel.values) {
    if (level.name == name) return level;
  }
  return null;
}

/// The level to offer as the opening pick: whatever the player last ran in a
/// customized session, widened back to the full board if they never picked.
PracticeLevel suggestedLevel(PracticeLevel? last) => last ?? PracticeLevel.easy;
