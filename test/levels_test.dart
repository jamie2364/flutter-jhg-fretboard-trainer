import 'package:flutter_test/flutter_test.dart';
import 'package:fretboard/models/saved_session.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/utils/levels.dart';
import 'package:fretboard/utils/intervals.dart';

void main() {
  group('PracticeLevel', () {
    test('fret caps are 0–5 / 0–9 / 0–15', () {
      expect(PracticeLevel.easy.fretCap, 5);
      expect(PracticeLevel.medium.fretCap, 9);
      expect(PracticeLevel.hard.fretCap, kMaxBoardFret);
    });

    test('labels match the app-wide Easy/Medium/Hard naming', () {
      expect(PracticeLevel.easy.label, 'Easy');
      expect(PracticeLevel.medium.label, 'Medium');
      expect(PracticeLevel.hard.label, 'Hard');
    });

    test('only Easy restricts notes to naturals', () {
      expect(PracticeLevel.easy.naturalNotesOnly, isTrue);
      expect(PracticeLevel.medium.naturalNotesOnly, isFalse);
      expect(PracticeLevel.hard.naturalNotesOnly, isFalse);
    });

    test('difficulty ordinals line up with the legacy enums', () {
      for (final level in PracticeLevel.values) {
        expect(
          IntervalDifficulty.values[level.difficultyIndex].name,
          level.name,
        );
        expect(
          ChordDifficulty.values[level.difficultyIndex].name,
          level.name,
        );
      }
    });

    test('the ordinal bridge round-trips', () {
      for (final level in PracticeLevel.values) {
        expect(
          practiceLevelForDifficultyIndex(level.difficultyIndex),
          level,
        );
      }
    });

    test('stored name parsing is tolerant of missing / unknown values', () {
      expect(practiceLevelFromName('medium'), PracticeLevel.medium);
      expect(practiceLevelFromName('hard'), PracticeLevel.hard);
      expect(practiceLevelFromName(null), isNull);
      expect(practiceLevelFromName('expert'), isNull);
    });
  });

  group('effectiveChordWindow', () {
    test('no level keeps the difficulty window', () {
      expect(effectiveChordWindow(ChordDifficulty.easy, null), 4);
      expect(effectiveChordWindow(ChordDifficulty.medium, null), 9);
      expect(effectiveChordWindow(ChordDifficulty.hard, null), kMaxBoardFret);
    });

    test('Easy level shortens a wider difficulty window', () {
      expect(effectiveChordWindow(ChordDifficulty.hard, PracticeLevel.easy), 5);
      expect(
          effectiveChordWindow(ChordDifficulty.medium, PracticeLevel.easy), 5);
    });

    test('a Hard level still cannot outgrow a narrow difficulty window', () {
      expect(effectiveChordWindow(ChordDifficulty.easy, PracticeLevel.hard), 4);
    });
  });

  group('SavedSession level persistence', () {
    SavedSession sample({String? level, int? fretCap}) => SavedSession(
          id: '1',
          createdAt: DateTime(2026, 1, 1),
          gameMode: 'stopwatch',
          intervalGameType: 0,
          chordGameType: 0,
          intervalDifficulty: 0,
          chordDifficulty: 2,
          level: level,
          fretCap: fretCap,
          strings: const [true, true, true, true, true, true],
          selectedIntervals: const [1, 2, 3],
          chordLabKeys: const ['C'],
          chordLabTonalities: const ['Major'],
          chordLabRounds: const ['name'],
          timerMode: 'stopwatch',
          timerIntervalValue: 60,
          score: 0,
          secondsRemaining: 0,
          title: 'Find the Note',
          subtitle: 'Hard · all strings',
        );

    test('level and fret cap survive a JSON round trip', () {
      final decoded = SavedSession.fromJson(sample(
        level: 'medium',
        fretCap: 9,
      ).toJson());
      expect(decoded.level, 'medium');
      expect(decoded.fretCap, 9);
    });

    test('a session saved before levels restores to the full board', () {
      final json = sample().toJson()
        ..remove('level')
        ..remove('fretCap');
      final decoded = SavedSession.fromJson(json);
      expect(decoded.level, isNull);
      expect(decoded.fretCap, isNull);
    });

    test('copyWith preserves the level fields', () {
      final copy =
          sample(level: 'easy', fretCap: 5).copyWith(customName: 'My drill');
      expect(copy.level, 'easy');
      expect(copy.fretCap, 5);
      expect(copy.displayName, 'My drill');
    });
  });
}
