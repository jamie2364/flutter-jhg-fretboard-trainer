import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';

import 'tour_anchor.dart';
import 'tour_coach.dart';
import 'tour_controller.dart';

/// The painted layer of the tour: the travelling spotlight, its halo, the
/// instruction text and the progress hairline.
///
/// Two rules this file exists to enforce.
///
/// **Nothing is a box.** There is no card and no panel. See [TourCoach].
///
/// **The instruction gets the free band, and only the free band.** The bottom of
/// the screen belongs to the app: across this suite that is where everything you
/// actually press lives (wizard footers, the transport, the nav bar). The top
/// belongs to the screen's own heading, which any screen can declare by wrapping
/// it in a [TourReserve]. The tour takes the space between the two and starts at
/// the top of it, dropping below the spotlight on the one occasion the spotlight
/// is sitting in that space itself.
class TourOverlay extends StatefulWidget {
  const TourOverlay({
    super.key,
    required this.controller,
    this.ownerScreenId = 'home',
  });

  final TourController controller;

  /// The screen hosting this overlay. Steps tagged with another screen's id are
  /// not painted here, so no screen ever flashes another screen's step during a
  /// navigation transition.
  final String ownerScreenId;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with TickerProviderStateMixin {
  final GlobalKey _coachKey = GlobalKey();

  Rect? _targetRect;

  /// Spotlight plus any declared passthroughs: the holes in the fence.
  List<Rect> _allowedRects = const [];

  Rect? _coachRect;
  CoachAnchor _anchor = CoachAnchor.screenTop;
  double _coachTop = 0;

  /// Status-bar padding folded into the coach the last time it was laid out at
  /// the screen top. Subtracted before the slot tests so they compare a stable
  /// height: without it the coach measures taller at the top slot than in the
  /// others, so a marginal fit could pass, grow, fail, shrink and flip back
  /// every frame.
  double _appliedTopInset = 0;

  late final AnimationController _travel;
  late final AnimationController _breathe;
  late final AnimationController _fade;

  /// Where the spotlight is coming from and going to, so it can tween.
  Rect? _fromRect;
  Rect? _toRect;

  /// Last step the overlay reacted to, so a revision bump that was not a step
  /// change (a mis-tap, a completion flash) does not re-run the measure/settle
  /// work for a target that has not moved.
  int _lastStep = -1;

  Timer? _settleTimer;

  /// Countdown for a closing step. Owned here rather than left to the
  /// controller alone: the overlay is the thing actually on screen, so the
  /// message disappearing cannot depend on a timer somewhere else surviving a
  /// step transition.
  Timer? _dismissTimer;
  int? _armedFor;

  @override
  void initState() {
    super.initState();

    _travel = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure(jump: true);
      _trackSettling();
      _fade.forward();
      _armDismiss();
    });

    _lastStep = widget.controller.currentStep.value;
    widget.controller.revision.addListener(_onRevision);
  }

  /// A closing step says its piece and gets out of the way on its own.
  void _armDismiss() {
    final idx = widget.controller.currentStep.value;
    if (_armedFor == idx) return;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _armedFor = idx;

    final after = widget.controller.currentTourStep.autoDismiss;
    if (after == null || !widget.controller.isVisible.value) return;
    _dismissTimer = Timer(after, () {
      if (!mounted) return;
      if (widget.controller.currentStep.value != idx) return;
      // Fade out rather than snap off. The tour arrived softly, so it should
      // leave the same way.
      _fade.reverse().whenComplete(() {
        if (widget.controller.currentStep.value == idx) {
          widget.controller.complete();
        }
      });
    });
  }

  /// The controller changed. Only a step change needs the spotlight re-measured
  /// and the entry animation replayed; everything else just repaints.
  void _onRevision() {
    if (!mounted) return;
    final step = widget.controller.currentStep.value;
    if (step == _lastStep) {
      // Same step, but the screen under it can still have moved. A step's real
      // action often changes the layout it just happened in — a control tile
      // folds away, a panel collapses — and the completion flash bumps the
      // revision without changing the step. Without re-measuring, the ring is
      // left drawing the rect the target used to occupy, or hanging over a
      // control that is no longer there.
      _trackSettling();
      setState(() {});
      return;
    }
    _lastStep = step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _measure();
      _trackSettling();
      _fade.forward();
      _armDismiss();
    });
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.revision.removeListener(_onRevision);
    _dismissTimer?.cancel();
    _settleTimer?.cancel();
    _travel.dispose();
    _breathe.dispose();
    _fade.dispose();
    super.dispose();
  }

  // ── Measurement ────────────────────────────────────────────────────────────

  /// The setup wizard slides each sub-step in with an `AnimatedSwitcher`
  /// (~260 ms). A single post-frame measurement catches the target mid-slide
  /// and freezes the cutout in the wrong place, so re-measure every frame for a
  /// short window and let it follow the content to where it settles.
  void _trackSettling() {
    _settleTimer?.cancel();
    final start = DateTime.now();
    _settleTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _measure(jump: true);
      if (DateTime.now().difference(start).inMilliseconds > 500) t.cancel();
    });
  }

  /// Reads the live target rect, works out where the instruction sits, and
  /// reads the instruction's own rect back for the connector.
  ///
  /// [jump] skips the travel animation, used while a target is still settling
  /// so the cutout tracks it frame by frame instead of chasing itself.
  void _measure({bool jump = false}) {
    final step = widget.controller.currentTourStep;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return;

    Rect? rectFor(GlobalKey key, double pad) {
      final ctx = key.currentContext;
      if (ctx == null) return null;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
      return (topLeft & box.size).inflate(pad);
    }

    final next = step.targetKey == null
        ? null
        : rectFor(step.targetKey!, step.spotlightPadding);

    // Everything the fence lets through: the spotlight plus whatever else the
    // step declared as still-live.
    final allowed = <Rect>[
      if (next != null) next,
      for (final k in step.passthroughKeys)
        if (rectFor(k, 4) case final r?) r,
    ];

    // ── Placement ──────────────────────────────────────────────────────────
    // Find the tallest genuinely free horizontal band and sit in it.
    //
    // The earlier version only checked that the text cleared the heading and
    // the spotlight, which is not the same as clearing *content*: on a landing
    // screen it happily parked itself on the other option cards. So a screen
    // reserves everything it does not want covered, the spotlight is treated as
    // blocked too, and what is left over are the gaps. Biggest gap wins.
    final safeTop = MediaQuery.paddingOf(context).top;
    final screenH = overlayBox.size.height;
    // Height with no status-bar padding in it, so every candidate is judged the
    // same way. The top slot adds its own inset back on below.
    final bareHeight =
        (_coachRect?.height ?? TourCoach.budget) - _appliedTopInset;

    final blocked = <(double, double)>[];
    final reserved = TourReservedRegion.boundsFor(widget.ownerScreenId);
    if (reserved != null) {
      blocked.add((
        overlayBox.globalToLocal(Offset(0, reserved.$1)).dy,
        overlayBox.globalToLocal(Offset(0, reserved.$2)).dy,
      ));
    }
    if (next != null) blocked.add((next.top, next.bottom));

    // Merge overlapping blocked spans, then read off what is between them.
    blocked.sort((a, b) => a.$1.compareTo(b.$1));
    final merged = <(double, double)>[];
    for (final b in blocked) {
      if (merged.isNotEmpty && b.$1 <= merged.last.$2 + 8) {
        merged[merged.length - 1] = (
          merged.last.$1,
          math.max(merged.last.$2, b.$2),
        );
      } else {
        merged.add(b);
      }
    }

    final gaps = <(double, double)>[];
    var cursor = safeTop;
    for (final m in merged) {
      if (m.$1 - cursor > 0) gaps.add((cursor, m.$1));
      cursor = math.max(cursor, m.$2);
    }
    if (screenH - cursor > 0) gaps.add((cursor, screenH));

    // A region the screen has explicitly offered beats anything worked out from
    // geometry: only the screen knows that the space under a spotlight is a
    // panel header rather than somewhere empty.
    final open = TourOpenRegion.bestFor(widget.ownerScreenId);
    double? openTop;
    if (open != null) {
      final top = overlayBox.globalToLocal(open.$1.topLeft).dy;
      final bottom = overlayBox.globalToLocal(open.$1.bottomRight).dy;
      if (bottom - top >= bareHeight) {
        openTop = open.$2 == TourOpenAlign.bottom ? bottom - bareHeight : top;
      }
    }

    final double coachTop;
    final CoachAnchor anchor;
    if (openTop != null) {
      coachTop = openTop;
      anchor = CoachAnchor.inline;
    } else if (gaps.isEmpty) {
      coachTop = safeTop;
      anchor = CoachAnchor.screenTop;
    } else {
      // Prefer a gap the text actually fits in; if none does, take the roomiest
      // and accept the overlap rather than stacking it on a control.
      final fitting = gaps.where((g) => g.$2 - g.$1 >= bareHeight + 8).toList();
      final pool = fitting.isEmpty ? gaps : fitting;
      final best = pool.reduce((a, b) => (b.$2 - b.$1) > (a.$2 - a.$1) ? b : a);

      // Sitting at the very top of the screen is the one case where the wash
      // can run to the edge; everywhere else it has to feather at both ends or
      // it reads as a panel.
      if (best.$1 <= safeTop + 2 && best.$2 - best.$1 >= bareHeight + safeTop) {
        coachTop = 0;
        anchor = CoachAnchor.screenTop;
      } else {
        // Centre it in the gap so it is not crowding whatever bounds it.
        final slack = (best.$2 - best.$1) - bareHeight;
        coachTop = best.$1 + (slack > 0 ? math.min(slack / 2, 24) : 0);
        anchor = CoachAnchor.inline;
      }
    }

    Rect? coach;
    final coachCtx = _coachKey.currentContext;
    if (coachCtx != null) {
      final box = coachCtx.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        coach = box.localToGlobal(Offset.zero, ancestor: overlayBox) & box.size;
      }
    }

    if (next == _targetRect &&
        listEquals(allowed, _allowedRects) &&
        coach == _coachRect &&
        anchor == _anchor &&
        coachTop == _coachTop) {
      return;
    }

    setState(() {
      _allowedRects = allowed;
      _coachRect = coach;
      _appliedTopInset = anchor == CoachAnchor.screenTop ? safeTop : 0;
      _anchor = anchor;
      _coachTop = coachTop;
      if (jump || _targetRect == null || next == null) {
        _targetRect = next;
        _fromRect = next;
        _toRect = next;
        _travel.value = 1;
      } else {
        _fromRect = _targetRect;
        _toRect = next;
        _targetRect = next;
        _travel.forward(from: 0);
      }
    });
  }

  /// The spotlight rect for this frame, part way along its travel.
  Rect? get _liveRect {
    if (_toRect == null) return null;
    if (_fromRect == null) return _toRect;
    final t = Curves.easeOutCubic.transform(_travel.value);
    return Rect.lerp(_fromRect, _toRect, t);
  }

  // ── Interaction ────────────────────────────────────────────────────────────

  /// A blocked tap is not nothing. Nudge the instruction so the user is pointed
  /// back at the one control the step is about.
  void _onBlockedTap() {
    HapticFeedback.selectionClick();
    widget.controller.reportMisTap();
  }

  /// Everything outside the holes is fenced off.
  ///
  /// This used to be four bands laid around a single cutout, which could only
  /// ever express one hole and so could not support a step that needs a picker
  /// and the button that commits it. [_TourFence] punts on any number of them.
  Widget _fence() => Positioned.fill(
        child: _TourFence(holes: _allowedRects, onBlocked: _onBlockedTap),
      );

  void _onSkip() => widget.controller.skip();

  void _onAction() {
    final step = widget.controller.currentTourStep;
    if (step.onActionTap != null) {
      step.onActionTap!();
    } else {
      widget.controller.next();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    {
      if (!widget.controller.isVisible.value) return const SizedBox.shrink();
      final step = widget.controller.currentTourStep;
      if (step.screenId != widget.ownerScreenId) return const SizedBox.shrink();

      final completed = widget.controller.stepCompleted.value;
      final misTap = widget.controller.misTap.value;
      final railIndex = widget.controller.railIndex;
      final railTotal = widget.controller.railTotal;
      final hasCutout = step.targetKey != null && step.dimBackground;

      return FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
        child: Stack(
          children: [
            // ── 1. Backdrop + travelling spotlight ─────────────────────────
            // A scrim is only ever drawn to make a cutout pop. A step with no
            // cutout gets no scrim at all: greying out a wheel the user is
            // being asked to spin just makes the screen look switched off,
            // and the instruction's own wash already gives it contrast.
            if (hasCutout)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _travel,
                    builder: (_, __) =>
                        CustomPaint(painter: _BackdropPainter(_liveRect)),
                  ),
                ),
              ),

            // ── 2. Tap fencing ─────────────────────────────────────────────
            // A closing step has nothing to do and nothing to protect, so a tap
            // anywhere just gets rid of it rather than waiting the clock out.
            if (step.autoDismiss != null)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: widget.controller.complete,
                ),
              )
            else if (step.blockBackground)
              _fence(),

            // Steps where the tour performs the navigation itself rather than
            // letting the screen drive it.
            //
            // Opaque, not translucent. Translucent would let the press reach
            // the real control underneath as well, so the card's own onTap and
            // the tour's callback would both run and the screen would be pushed
            // twice. A step that declares onSpotlightTap owns the tap; a step
            // that wants the real widget to handle it simply does not declare
            // one, and then there is no detector here at all.
            if (step.onSpotlightTap != null && _liveRect != null)
              Positioned.fromRect(
                rect: _liveRect!,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: step.onSpotlightTap,
                ),
              ),

            // ── 3. Halo ring + connector ───────────────────────────────────
            if (_liveRect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_travel, _breathe]),
                    builder: (_, __) => CustomPaint(
                      painter: _HaloPainter(
                        rect: _liveRect!,
                        breathe: _breathe.value,
                        completed: completed,
                        coachRect: _coachRect,
                      ),
                    ),
                  ),
                ),
              ),

            // ── 4. The instruction ─────────────────────────────────────────
            // Full bleed left to right: the wash runs off both edges so it
            // never draws a boundary. Bottom is left alone entirely.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              top: _coachTop,
              child: TourCoach(
                key: _coachKey,
                step: step,
                anchor: _anchor,
                topInset: _anchor == CoachAnchor.screenTop
                    ? MediaQuery.paddingOf(context).top
                    : 0,
                completed: completed,
                misTapTick: misTap,
                showSkip: !widget.controller.isLastStep,
                onSkip: _onSkip,
                onAction: _onAction,
              ),
            ),

            // ── 5. Progress ────────────────────────────────────────────────
            // A hairline on the screen's very top edge. The only piece of tour
            // chrome in a fixed position, and the only one that can be, because
            // at 2px it cannot cover a control on any screen.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: TourProgressLine(index: railIndex, total: railTotal),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.spotlight);

  final Rect? spotlight;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0x99000000);
    if (spotlight == null) {
      canvas.drawRect(Offset.zero & size, bg);
      return;
    }
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlight!, const Radius.circular(15)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.spotlight != spotlight;
}

/// The coral halo around the spotlight plus a short dashed run back towards the
/// instruction, so the words and the control they describe read as one thing.
class _HaloPainter extends CustomPainter {
  const _HaloPainter({
    required this.rect,
    required this.breathe,
    required this.completed,
    required this.coachRect,
  });

  final Rect rect;
  final double breathe;
  final bool completed;
  final Rect? coachRect;

  @override
  void paint(Canvas canvas, Size size) {
    final colour = completed ? const Color(0xFF4CAF50) : JHGColors.primary;

    // One soft in-and-out per cycle rather than an expanding ripple: next to a
    // breathing cue dot on the instruction, a ripple reads as clutter.
    final wave = completed
        ? 1.0
        : 0.35 + 0.65 * (0.5 - 0.5 * math.cos(breathe * 2 * math.pi));
    final spread = completed ? 3.0 : 2.0 + 2.0 * wave;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(spread),
        Radius.circular(15 + spread),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colour.withValues(
          alpha: completed ? 0.95 : 0.35 + 0.55 * wave,
        ),
    );

    _paintConnector(canvas, colour, wave);
  }

  void _paintConnector(Canvas canvas, Color colour, double wave) {
    final coach = coachRect;
    // The instruction always sits above the target, so the run is downward
    // from the text to the spotlight. Nothing to draw when the text is below
    // it (the belowTarget case) or when they are already touching.
    if (coach == null || coach.bottom >= rect.top - 8) return;

    final x = rect.center.dx.clamp(coach.left + 24, coach.right - 24);
    final fromY = rect.top - 4;
    // Cap the run. Bridging the full height of a canvas draws a dashed line
    // straight down the middle of the user's chords, which looks like damage
    // rather than a pointer. Past the cap, a short stub does the same job.
    final toY = math.max(coach.bottom - 10, fromY - 120);

    final paint = Paint()
      ..strokeWidth = 1
      ..color = colour.withValues(alpha: 0.28 + 0.24 * wave);

    const dash = 4.0;
    const gap = 4.0;
    var y = fromY;
    while (y > toY) {
      canvas.drawLine(Offset(x, y), Offset(x, math.max(y - dash, toY)), paint);
      y -= dash + gap;
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) =>
      old.rect != rect ||
      old.breathe != breathe ||
      old.completed != completed ||
      old.coachRect != coachRect;
}

/// A full-screen tap fence with holes cut in it.
///
/// Implemented as a render object rather than a stack of [GestureDetector]
/// bands because the holes are arbitrary rects, and because a hole has to be a
/// genuine hole: hit testing must fall straight through to the real control
/// underneath so the press lands on it rather than on the tour.
class _TourFence extends SingleChildRenderObjectWidget {
  const _TourFence({required this.holes, required this.onBlocked});

  final List<Rect> holes;
  final VoidCallback onBlocked;

  @override
  Widget get child => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBlocked,
        child: const SizedBox.expand(),
      );

  @override
  _RenderTourFence createRenderObject(BuildContext context) =>
      _RenderTourFence(holes);

  @override
  void updateRenderObject(BuildContext context, _RenderTourFence renderObject) {
    renderObject.holes = holes;
  }
}

class _RenderTourFence extends RenderProxyBox {
  _RenderTourFence(this._holes);

  List<Rect> _holes;
  set holes(List<Rect> value) {
    if (listEquals(_holes, value)) return;
    _holes = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    for (final hole in _holes) {
      if (hole.contains(position)) return false;
    }
    return super.hitTest(result, position: position);
  }
}
