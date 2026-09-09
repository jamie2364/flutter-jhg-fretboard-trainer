// services/app_flags.dart
//
// Small persistent app-level flags, read once at startup so the UI can use them
// synchronously and never flashes the wrong layout on the first frame.

import 'package:shared_preferences/shared_preferences.dart';

class AppFlags {
  AppFlags._();

  static const _launchedBeforeKey = 'fretboard_has_launched_before_v1';

  /// True only for the very first run after a fresh install. The home screen
  /// keeps itself to Quick start and Customized Practice while this is set, so
  /// a new player sees two clear ways in rather than a full set of controls.
  static bool isFirstRun = false;

  /// Reads the flag and, on that first ever run, flips it so the next launch is
  /// treated as a return visit. Call once from `main()` before `runApp`.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final launchedBefore = prefs.getBool(_launchedBeforeKey) ?? false;
      isFirstRun = !launchedBefore;
      if (isFirstRun) await prefs.setBool(_launchedBeforeKey, true);
    } catch (_) {
      // If prefs are unavailable, treat it as a return visit: the worst case is
      // a new player seeing the full home screen, never a returning one losing
      // their navigation.
      isFirstRun = false;
    }
  }
}
