import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fretboard/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots with the shared JHG design system', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);

    final navigatorContext = tester.element(find.byType(Navigator).first);
    expect(
      Theme.of(navigatorContext).extension<JhgTokens>(),
      isNotNull,
      reason: 'Every Fretboard screen must inherit JHG Elements tokens.',
    );
    expect(tester.takeException(), isNull);

    // The registration splash intentionally schedules short animation and
    // routing timers. Let them expire, then dispose the app tree cleanly.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
