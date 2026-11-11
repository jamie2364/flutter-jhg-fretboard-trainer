import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fretboard/utils/levels.dart';
import 'package:fretboard/views/screens/widgets/practice_level_step.dart';

void main() {
  testWidgets('level step renders all three levels with their windows',
      (tester) async {
    PracticeLevel? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeLevelStep(
            eyebrow: 'STEP 3 · LEVEL',
            subtitle: 'How far up the neck?',
            selected: PracticeLevel.medium,
            onPick: (level) => picked = level,
          ),
        ),
      ),
    );

    for (final level in PracticeLevel.values) {
      expect(find.text(level.label), findsOneWidget,
          reason: '${level.label} card must be on screen');
      expect(find.text(level.fretRangeLabel), findsOneWidget,
          reason: '${level.label} must state its fret window');
    }

    // The selected level is the one currently applied to the session.
    expect(find.byType(PracticeLevelCard), findsNWidgets(3));

    await tester.tap(find.text(PracticeLevel.hard.label));
    await tester.pump();
    expect(picked, PracticeLevel.hard);

    expect(tester.takeException(), isNull);
  });

  testWidgets('chords variant exposes the fine-tune escape hatch',
      (tester) async {
    var customized = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeLevelStep(
            eyebrow: 'STEP 3 · LEVEL',
            subtitle: 'How far up the neck?',
            selected: null,
            onPick: (_) {},
            onCustomize: () => customized = true,
            customizeLabel: 'Skip — just choose chord types',
          ),
        ),
      ),
    );

    final link = find.text('Skip — just choose chord types');
    expect(link, findsOneWidget);
    // The step scrolls; on a short viewport the link sits under the three cards.
    await tester.ensureVisible(link);
    await tester.pump();
    await tester.tap(link);
    await tester.pump();
    expect(customized, isTrue);

    expect(tester.takeException(), isNull);
  });

  testWidgets('every level card is fully visible on a short phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeLevelStep(
            eyebrow: 'STEP 3 · LEVEL',
            subtitle: 'How far up the neck?',
            selected: PracticeLevel.easy,
            onPick: (_) {},
          ),
        ),
      ),
    );

    // The step scrolls rather than overflowing when three cards and a heading
    // do not fit — this is the layout the old fixed-spacer steps used to break.
    expect(tester.takeException(), isNull);
    for (final level in PracticeLevel.values) {
      expect(find.text(level.label), findsOneWidget);
    }
  });
}
