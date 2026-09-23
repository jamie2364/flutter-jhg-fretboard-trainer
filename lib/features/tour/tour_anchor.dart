import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tour_controller.dart';

/// A region of a screen the tour must not sit on top of.
///
/// Today that means one thing: a screen's own heading. The instruction can
/// cover a faded wheel entry or an empty stretch of canvas without anyone
/// caring, but stacking it on top of the screen's title is just two headings
/// fighting each other.
///
/// This exists instead of a plain `GlobalKey` because the screens that most
/// need it draw their heading *inside* an `AnimatedSwitcher`. A GlobalKey on a
/// switching child collides the moment the outgoing and incoming steps are both
/// mounted. Reporting rects into a shared registry handles that case correctly:
/// during a cross-fade two headings report at once and the tour simply takes
/// the lower edge of both, so it never creeps up underneath the one that is on
/// its way in.
class TourReservedRegion {
  TourReservedRegion._();

  static final Map<Object, (Rect, String?)> _rects = {};

  /// Bumped on every change so an overlay can re-measure.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void put(Object owner, Rect globalRect, String? screenId) {
    final existing = _rects[owner];
    if (existing != null &&
        existing.$1 == globalRect &&
        existing.$2 == screenId) {
      return;
    }
    _rects[owner] = (globalRect, screenId);
    revision.value++;
  }

  static void remove(Object owner) {
    if (_rects.remove(owner) != null) revision.value++;
  }

  /// The span of everything reserved for [ownerScreenId], in global
  /// coordinates, or null when that screen reserves nothing.
  ///
  /// Scoped by screen, and that matters. An app whose screens stay mounted —
  /// tabs in an IndexedStack, kept-alive routes — has every screen's regions
  /// reporting at once. Velocity unioned its Landing's heading and cards with
  /// the Editor's header, which fenced off most of the screen and shoved the
  /// instruction down into the controls it was meant to be explaining. An entry
  /// with no screen id belongs to every screen, which is what a single-screen
  /// app wants.
  static (double, double)? boundsFor(String? ownerScreenId) {
    var top = double.infinity;
    var bottom = 0.0;
    for (final entry in _rects.values) {
      final screenId = entry.$2;
      if (screenId != null && screenId != ownerScreenId) continue;
      top = math.min(top, entry.$1.top);
      bottom = math.max(bottom, entry.$1.bottom);
    }
    return bottom <= 0 ? null : (top, bottom);
  }
}

/// Wrap a screen's heading in this and the tour will start below it.
///
/// ```dart
/// TourReserve(child: _buildIntro(stepId))
/// ```
///
/// Cheap to leave in place: with no tour running it is an inherited-free
/// pass-through that measures itself once per layout and writes to a map.
class TourReserve extends StatefulWidget {
  const TourReserve({super.key, required this.child, this.screenId});

  final Widget child;

  /// Which screen this region belongs to. Leave null in an app whose screens
  /// unmount when you leave them; set it when they stay alive, or one screen's
  /// reserved space will fence off another's.
  final String? screenId;

  @override
  State<TourReserve> createState() => _TourReserveState();
}

class _TourReserveState extends State<TourReserve> {
  final Object _token = Object();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  @override
  void didUpdateWidget(TourReserve old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  @override
  void dispose() {
    TourReservedRegion.remove(_token);
    super.dispose();
  }

  void _report() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    TourReservedRegion.put(
      _token,
      box.localToGlobal(Offset.zero) & box.size,
      widget.screenId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Re-report every frame the heading could have moved. Screens animate their
    // headings in, so a single post-frame read catches it mid-slide.
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return widget.child;
  }
}

/// Which end of an open region the instruction should settle at.
enum TourOpenAlign {
  /// Sit at the top of the space.
  top,

  /// Sit at the bottom of it. Use this for a region the user is about to
  /// *fill*, like a drop canvas: content lands at the top, so the instruction
  /// keeps to the tail end and stays out of its way as it fills up.
  bottom,
}

/// A region a screen is happy for the tour to sit in.
///
/// [TourReserve] says "not here". This says "here is fine", and it exists
/// because "below the spotlight" is not the same thing as "somewhere empty".
/// On the chord step the space below the palette is the progression panel's
/// own header, so the instruction landed straight on it; the genuinely free
/// space is the empty drop area further down, and only the screen knows that.
class TourOpenRegion {
  TourOpenRegion._();

  static final Map<Object, (Rect, TourOpenAlign, String?)> _regions = {};

  static void put(
    Object owner,
    Rect globalRect,
    TourOpenAlign align,
    String? screenId,
  ) {
    final existing = _regions[owner];
    if (existing != null &&
        existing.$1 == globalRect &&
        existing.$2 == align &&
        existing.$3 == screenId) {
      return;
    }
    _regions[owner] = (globalRect, align, screenId);
  }

  static void remove(Object owner) => _regions.remove(owner);

  /// The tallest region on offer for [ownerScreenId], or null when that screen
  /// has not offered one. Scoped for the same reason as [TourReservedRegion].
  static (Rect, TourOpenAlign)? bestFor(String? ownerScreenId) {
    (Rect, TourOpenAlign)? best;
    for (final (rect, align, screenId) in _regions.values) {
      if (screenId != null && screenId != ownerScreenId) continue;
      if (best == null || rect.height > best.$1.height) best = (rect, align);
    }
    return best;
  }
}

/// Wrap a screen's genuinely empty area in this and the tour will prefer to sit
/// inside it rather than wherever it can squeeze past the spotlight.
class TourOpenSpace extends StatefulWidget {
  const TourOpenSpace({
    super.key,
    required this.child,
    this.align = TourOpenAlign.top,
    this.screenId,
  });

  final Widget child;
  final TourOpenAlign align;

  /// See [TourReserve.screenId].
  final String? screenId;

  @override
  State<TourOpenSpace> createState() => _TourOpenSpaceState();
}

class _TourOpenSpaceState extends State<TourOpenSpace> {
  final Object _token = Object();

  @override
  void dispose() {
    TourOpenRegion.remove(_token);
    super.dispose();
  }

  void _report() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    TourOpenRegion.put(
      _token,
      box.localToGlobal(Offset.zero) & box.size,
      widget.align,
      widget.screenId,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return widget.child;
  }
}

/// Fences a screen's bottom navigation while a tour is running.
///
/// The overlay is mounted inside `Scaffold.body`, and `bottomNavigationBar` is
/// a separate slot outside it, so the painted fence simply cannot reach the nav
/// bar. Without this you can tap straight out of a guided tour into another tab
/// and strand it. Wrap the bar:
///
/// ```dart
/// bottomNavigationBar: TourNavGuard(controller: _tour, child: AppNavBar(...)),
/// ```
///
/// Taps are swallowed and reported as mis-taps, so the instruction shakes and
/// points the user back at the control the step is about, rather than the tap
/// just doing nothing.
class TourNavGuard extends StatelessWidget {
  const TourNavGuard(
      {super.key, required this.controller, required this.child});

  /// Null when the tour infrastructure was never registered, in which case this
  /// is a pass-through.
  final TourController? controller;
  final Widget child;

  /// For the screens whose nav bar is itself conditional (hidden on a first
  /// run, say). Returns null straight through rather than forcing a zero-height
  /// bar into the Scaffold slot.
  static Widget? wrap({
    required TourController? controller,
    required Widget? child,
  }) =>
      child == null ? null : TourNavGuard(controller: controller, child: child);

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) return child;
    return ListenableBuilder(
      listenable: c.revision,
      builder: (_, __) {
        if (!c.isVisible.value) return child;
        return Stack(
          children: [
            IgnorePointer(child: child),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  c.reportMisTap();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
