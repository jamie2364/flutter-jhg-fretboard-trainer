import 'package:flutter/widgets.dart';

/// The live cue shown on the right of the dock while the tour waits for the
/// user to do the real thing. There is deliberately no "Next" button on these
/// steps: the breathing dot plus the verb is what tells the user the app is
/// waiting for *them*.
enum TourCue {
  none,
  tap,
  drag,
  spin,
  listen;

  String get label => switch (this) {
        TourCue.none => '',
        TourCue.tap => 'Tap it',
        TourCue.drag => 'Drag it',
        TourCue.spin => 'Spin it',
        TourCue.listen => 'Listen',
      };
}

/// One step of the guided tour.
///
/// Positioning is **not** a property of a step. The dock is pinned to the
/// bottom of the screen and only ever flips to the top band when the spotlight
/// would sit underneath it, and the overlay works that out from the live target
/// rect. That is the whole point of the redesign: the panel stays put, the
/// light travels. Anything that used to be a hand-tuned `labelYOffset` is gone.
class TourStep {
  /// Headline. Poppins 20 / w600. Say what the user will *get*, not what the
  /// button is called.
  final String title;

  /// One or two lines of Inter 14. If it needs three, the step is wrong.
  final String? body;

  /// Which rail position this step belongs to, 0-based.
  ///
  /// Steps that share a [stage] are **one** step as far as the user is
  /// concerned: the rail does not move and the counter does not change, only
  /// the dock's text cross-fades. This is how a five-screen setup wizard shows
  /// as "1 of 3" instead of blowing the rail out to seven dots.
  final int stage;

  /// Which screen owns this step. A [TourOverlay] only paints steps whose
  /// [screenId] matches its own `ownerScreenId`, so one shared controller can
  /// drive a tour across Welcome, the wizard and the canvas without a screen
  /// flashing another screen's step mid-transition.
  final String screenId;

  /// The widget to spotlight. Null means no cutout: the dock still shows, the
  /// screen stays whole.
  final GlobalKey? targetKey;

  final double spotlightPadding;

  /// When false a targeted step draws its halo ring as a *pointer only*, with
  /// no cutout and no dim. Use it when the user has to see and use the whole
  /// surrounding screen, like dragging chords from a palette onto a canvas.
  final bool dimBackground;

  /// When true (the default) every tap outside the spotlight — and outside
  /// [passthroughKeys] — is swallowed and the instruction shakes.
  ///
  /// This is on by default on purpose. A guided tour that lets you wander into
  /// a "Close this track?" dialog half way through is not guided. Turn it off
  /// only for a step whose real interaction cannot be expressed as a set of
  /// rects, and there should be very few of those.
  final bool blockBackground;

  /// Extra controls that stay live alongside the spotlight while blocking.
  ///
  /// Some steps genuinely need two things: a picker *and* the Next button that
  /// commits it, or a drag source *and* the canvas it is dropped onto. Fencing
  /// everything but the single target would deadlock those, and dropping the
  /// fence entirely would open the whole screen. This is the middle ground.
  final List<GlobalKey> passthroughKeys;

  /// The live cue shown while the step waits. Ignored when [actionLabel] is set.
  final TourCue cue;

  /// Set this only on a step that genuinely has nothing for the user to do. It
  /// replaces the cue with a coral pill. There should be at most one per tour,
  /// and most tours should have none.
  final String? actionLabel;

  /// Called when the user taps inside the cutout.
  final VoidCallback? onSpotlightTap;

  /// Called instead of `controller.next()` when the action pill is tapped.
  final VoidCallback? onActionTap;

  /// When set, the step shows for this long and then ends the tour on its own.
  /// Used for the closing line: no button, no cue, nothing to dismiss. It says
  /// its piece and gets out of the way.
  final Duration? autoDismiss;

  /// Emits true when the step's real action has happened. The ring flashes
  /// green and the dock cross-fades straight on. No dead pause.
  final Stream<bool>? completionStream;

  const TourStep({
    required this.title,
    required this.stage,
    this.body,
    this.screenId = 'home',
    this.targetKey,
    this.spotlightPadding = 8.0,
    this.dimBackground = true,
    this.blockBackground = true,
    this.passthroughKeys = const [],
    this.cue = TourCue.tap,
    this.actionLabel,
    this.onSpotlightTap,
    this.onActionTap,
    this.completionStream,
    this.autoDismiss,
  });
}
