import 'package:flutter/widgets.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:get/get.dart';

import 'tour_controller.dart';
import 'tour_step.dart';

/// Screen identifiers. Home and the board are separate routes and Home stays
/// mounted underneath, so each hosts its own `TourOverlay(ownerScreenId: …)`
/// and paints only its own steps.
abstract class TourScreens {
  static const start = 'start';
  static const board = 'board';
}

/// Internal step indices. The board advances the tour by index when it opens,
/// so this name is shared with `home_screen.dart` and must not drift.
abstract class TourSteps {
  static const quickStart = 0;
  static const play = 1;
}

/// What the progress rail counts. Three positions.
abstract class TourStages {
  static const start = 0;
  static const round = 1;
  static const modes = 2;
}

/// The keys the tour spotlights, attached to the real controls by each screen.
///
/// All of them live in `portrait_board.dart`, and the tour does not run on the
/// web build, whose board is a different layout with different controls. The
/// old tour got this exactly backwards: two of its steps pointed at a mode chip
/// attached only in `web_board.dart`, so on a phone they spotlighted nothing —
/// full dim, no cutout, an instruction aimed at a control that was not there.
class TourKeys {
  /// Quick start card on Home.
  final GlobalKey quickStart = GlobalKey(debugLabel: 'tour_quickStart');

  /// The neck itself.
  final GlobalKey fretboard = GlobalKey(debugLabel: 'tour_fretboard');

  /// Play / Pause on the board's control row.
  final GlobalKey playButton = GlobalKey(debugLabel: 'tour_playButton');

  /// Skip on the collapsed tile. Only mounted while a round is running, which
  /// is exactly when the tour points at it.
  final GlobalKey skipButton = GlobalKey(debugLabel: 'tour_skipButton');

  /// The six string chips pinned above the nut.
  final GlobalKey stringChips = GlobalKey(debugLabel: 'tour_stringChips');

  /// The in-board MODES shifter, top-left over the neck.
  final GlobalKey modeSwitcher = GlobalKey(debugLabel: 'tour_modeSwitcher');
}

bool get _ready => Get.isRegistered<HomeController>();

HomeController get _hc => Get.find<HomeController>();

/// Fires when [counter] moves on from wherever it stood at subscribe time.
///
/// Counted rather than compared against zero, so a step works just as well on a
/// replay, part way into a session that already has a score on the board.
Stream<bool> _bumped(RxInt Function() counter) => Stream<bool>.multi((c) {
      c.add(false);
      if (!_ready) return;
      final rx = counter();
      final base = rx.value;
      final sub = rx.stream.listen((v) => c.add(v != base));
      c.onCancel = sub.cancel;
    });

/// The tour, in three moves:
///
///   1. Quick start. Whole neck, note names, nothing to set up.
///   2. One real round: start it, find the note, and learn that a note you
///      cannot find can be skipped rather than sat on.
///   3. Make it yours: narrow the drill to the strings you care about, then the
///      MODES shifter, which is the whole app behind one word.
///
/// Deliberately not here: the heat map and the stats behind it, Saved Sessions,
/// Settings and the leaderboard. None of those are a first round. The old tour
/// ran two full modes end to end across seven steps and never once appeared on
/// the screen the user actually lands on.
List<TourStep> buildFretboardTourSteps(TourKeys keys) {
  return [
    // ── Stage 1 · Get in ────────────────────────────────────────────────────
    // No completion stream: the board advances this by index as it opens, which
    // is the only thing that can honestly report "we got there".
    TourStep(
      stage: TourStages.start,
      screenId: TourScreens.start,
      title: 'Learn the neck',
      body: 'Tap Quick start. The whole neck, note names, nothing to set up.',
      targetKey: keys.quickStart,
      cue: TourCue.tap,
    ),

    // ── Stage 2 · Play a round ──────────────────────────────────────────────
    TourStep(
      stage: TourStages.round,
      screenId: TourScreens.board,
      title: 'Start the round',
      body: 'A note name appears and the clock starts.',
      targetKey: keys.playButton,
      cue: TourCue.tap,
      completionStream: _bumped(() => _hc.roundsStarted),
    ),
    // Same stage: the rail holds still, the words change. Starting the round
    // folds the panel away on its own, which is what puts the neck on screen
    // for this step.
    TourStep(
      stage: TourStages.round,
      screenId: TourScreens.board,
      title: 'Find it on the neck',
      // Kept to one line. The instruction sits over the top frets, so every
      // word of it is a fret the user cannot see.
      body: 'Tap it anywhere on the neck. More than one fret will do.',
      // No target, deliberately. The neck fills the screen, so spotlighting it
      // drew a halo round the whole display and pointed at nothing. It goes in
      // as a passthrough instead: no ring, no cutout, nothing painted over the
      // frets, but the neck and the tile under it stay the only live things
      // while everything else is fenced off.
      passthroughKeys: [keys.fretboard],
      cue: TourCue.tap,
      // Any answer, not a correct one. Getting it wrong is still finding out
      // where the note is, and a tour that will not let you past until you are
      // right is a test with a spotlight on it.
      completionStream: _bumped(() => _hc.answersGiven),
    ),
    // The way out of a note you cannot find. Worth a step of its own: without
    // it a stuck player either guesses at random or puts the app down.
    TourStep(
      stage: TourStages.round,
      screenId: TourScreens.board,
      title: 'Stuck? Skip it',
      body: 'Next draws a different note. Nothing is scored against you.',
      targetKey: keys.skipButton,
      cue: TourCue.tap,
      completionStream: _bumped(() => _hc.skipsUsed),
    ),

    // ── Stage 3 · Make it yours ─────────────────────────────────────────────
    // Six chips most players never realise are live. Drilling one string at a
    // time is how the neck is actually learned, and it is the difference
    // between this and a flashcard app.
    TourStep(
      stage: TourStages.modes,
      screenId: TourScreens.board,
      title: 'Drill one string',
      // One line: this step sits above the nut, and every extra line pushes it
      // down onto the frets.
      body: 'Tap a string chip to switch that string off.',
      targetKey: keys.stringChips,
      cue: TourCue.tap,
      completionStream: _bumped(() => _hc.stringToggles),
    ),


    // The payoff. Notes is one of three games on the same neck, and a player
    // who never finds this word thinks the app only does note names.
    TourStep(
      stage: TourStages.modes,
      screenId: TourScreens.board,
      title: 'Three ways to drill',
      body: 'Intervals and chords play on this same neck.',
      targetKey: keys.modeSwitcher,
      cue: TourCue.tap,
      completionStream: _bumped(() => _hc.modeSwitcherRevision),
    ),

    // ── Closing line ────────────────────────────────────────────────────────
    // Shares the last stage, so the rail is already full and this reads as the
    // tail of step 3 rather than a fourth thing to sit through.
    const TourStep(
      stage: TourStages.modes,
      screenId: TourScreens.board,
      title: "That's the neck",
      body: 'Every round picks a new spot. The more you play, the more of the '
          'neck you cover.',
      cue: TourCue.none,
      dimBackground: false,
      blockBackground: false,
      autoDismiss: Duration(milliseconds: 3600),
    ),
  ];
}

/// Ensures the shared [TourKeys] and the [TourController] exist, reusing
/// whatever is already registered. Both are permanent: GetX's smart management
/// disposes non-permanent dependencies when the route that registered them is
/// removed, and the board is a pushed route, so the keys have to outlive it.
TourController ensureFretboardTour() {
  final keys = Get.isRegistered<TourKeys>()
      ? Get.find<TourKeys>()
      : Get.put(TourKeys(), permanent: true);
  if (Get.isRegistered<TourController>()) return Get.find<TourController>();
  return Get.put(
    TourController(steps: buildFretboardTourSteps(keys)),
    permanent: true,
  );
}

TourKeys get fretboardTourKeys => Get.isRegistered<TourKeys>()
    ? Get.find<TourKeys>()
    : Get.put(TourKeys(), permanent: true);

TourController? get fretboardTourOrNull =>
    Get.isRegistered<TourController>() ? Get.find<TourController>() : null;
