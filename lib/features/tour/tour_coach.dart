import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tour_step.dart';

/// Where the coach text is sitting, which decides how its wash feathers.
enum CoachAnchor {
  /// Nothing to dodge, so the wash runs right to the screen's top edge and
  /// fades downward.
  screenTop,

  /// Sitting mid-screen, under the screen's own heading or under the spotlight.
  /// The wash feathers in from nothing at both ends so it draws no edge at all.
  inline,
}

/// The tour's instruction layer. Deliberately **not** a card, a tile, a panel or
/// a box.
///
/// A solid container has to live somewhere, and wherever you put it, it covers
/// a control. Pinning it to the bottom put it straight over a wizard's Next
/// button; letting it chase each target is what made the old tours feel like
/// they were flapping around the screen. So there is no container. The
/// instruction is bare type sitting on a soft darkening that fades out to
/// nothing at both ends. No border, no corner radius, no drop shadow, nothing
/// with an edge, and it bleeds off both sides of the screen so it reads as the
/// screen dimming rather than as an object placed on top of it.
///
/// Because it has no edges, overlapping is survivable: whatever is underneath
/// stays visible and, on a non-blocking step, stays tappable.
class TourCoach extends StatefulWidget {
  const TourCoach({
    super.key,
    required this.step,
    required this.anchor,
    required this.completed,
    required this.misTapTick,
    required this.onSkip,
    required this.onAction,
    this.showSkip = true,
    this.topInset = 0,
  });

  final TourStep step;
  final CoachAnchor anchor;
  final bool completed;

  /// Increments on every blocked tap. Each change nudges the text.
  final int misTapTick;

  final VoidCallback onSkip;
  final VoidCallback onAction;
  final bool showSkip;

  /// Extra top padding when the wash is run right up to the screen's top edge,
  /// so the darkening covers the status bar area too and the progress hairline
  /// sits on it rather than floating above a gap.
  final double topInset;

  /// Side gutter. Matches the suite's 24 content inset rather than the old
  /// card's 20, because this is text on the screen, not a floating object.
  static const double gutter = 24;

  /// How much vertical room the text block is assumed to want. Used only to
  /// work out whether a spotlight would land on it.
  static const double budget = 190;

  @override
  State<TourCoach> createState() => _TourCoachState();
}

class _TourCoachState extends State<TourCoach> with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _breathe;

  /// Soft black halo under every glyph. With no panel behind it this is what
  /// keeps the type readable where the wash has already faded out.
  static const List<Shadow> _glow = [
    Shadow(color: Colors.black, blurRadius: 12),
    Shadow(color: Colors.black, blurRadius: 4),
  ];

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void didUpdateWidget(TourCoach old) {
    super.didUpdateWidget(old);
    if (widget.misTapTick != old.misTapTick) _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        final dx = t == 0
            ? 0.0
            : math.sin(t * math.pi * 4) * 7 * (1 - Curves.easeOut.transform(t));
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      // Wrapped in its own transparent Material. Without one, a host screen
      // that has no Material ancestor above the overlay renders every glyph
      // with Flutter's yellow "missing Material" underline, which is exactly
      // what happened on the dictionaries fretboard. The tour should not care
      // what the screen it is sitting on happens to provide.
      child: Material(
        type: MaterialType.transparency,
        child: _wash(child: _text()),
      ),
    );
  }

  /// The feathered darkening behind the type. Full-bleed, no radius, fading to
  /// fully transparent at both ends so it never draws an edge.
  Widget _wash({required Widget child}) {
    final top = widget.anchor == CoachAnchor.screenTop;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Anchored at the top the wash starts solid, so the screen's own
          // heading underneath fades away instead of fighting the instruction.
          // Anchored mid-screen it feathers in from nothing at both ends.
          // Near-opaque wherever the type actually sits, fading to nothing
          // well outside it. The earlier ramp reached full strength only in the
          // middle of the block, so on a busy screen the title and the last
          // body line were sitting in the feather and the controls underneath
          // ghosted straight through them.
          colors: top
              ? const [
                  Color(0xF71A1A1A),
                  Color(0xF71A1A1A),
                  Color(0xB01A1A1A),
                  Color(0x001A1A1A),
                ]
              : const [
                  Color(0x001A1A1A),
                  Color(0xF51A1A1A),
                  Color(0xF51A1A1A),
                  Color(0x001A1A1A),
                ],
          stops:
              top ? const [0.0, 0.62, 0.86, 1.0] : const [0.0, 0.17, 0.83, 1.0],
        ),
      ),
      child: Padding(
        // Generous bottom padding is the feather: the type stops well before
        // the gradient does, so there is no visible boundary anywhere near it.
        // The vertical padding IS the feather: the type stops well before the
        // gradient does, so the fade happens over empty space rather than over
        // words.
        padding: EdgeInsets.fromLTRB(
          TourCoach.gutter,
          (top ? 12 : 30) + widget.topInset,
          TourCoach.gutter,
          top ? 40 : 34,
        ),
        child: child,
      ),
    );
  }

  Widget _text() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, if (current != null) current],
      ),
      child: Column(
        key: ValueKey(widget.step.title),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.step.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.4,
              shadows: _glow,
            ),
          ),
          if (widget.step.body != null) ...[
            const SizedBox(height: 7),
            Text(
              widget.step.body!,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14.5,
                height: 1.45,
                shadows: _glow,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _footer(),
        ],
      ),
    );
  }

  Widget _footer() {
    return Row(
      children: [
        if (widget.step.actionLabel != null)
          _pill(widget.step.actionLabel!)
        else
          _cue(),
        const Spacer(),
        if (widget.showSkip)
          GestureDetector(
            onTap: widget.onSkip,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                'Skip tour',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: _glow,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _pill(String label) {
    return GestureDetector(
      onTap: widget.onAction,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: JHGColors.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// The live cue: a breathing coral dot and a verb, never a Next button. This
  /// is what makes the tour interactive rather than a slideshow. The app is
  /// visibly waiting for the user, and there is nothing to click past.
  Widget _cue() {
    if (widget.step.cue == TourCue.none) return const SizedBox.shrink();

    const done = Color(0xFF4CAF50);
    final label = widget.completed ? 'Nice' : widget.step.cue.label;
    final colour = widget.completed ? done : JHGColors.primary;

    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, _) {
        final wave = widget.completed
            ? 1.0
            : 0.45 +
                0.55 * (0.5 - 0.5 * math.cos(_breathe.value * 2 * math.pi));
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colour.withValues(alpha: wave),
                boxShadow: [
                  BoxShadow(
                    color: colour.withValues(alpha: wave * 0.55),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Text(
              label,
              style: GoogleFonts.inter(
                color: colour,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                shadows: _glow,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The progress indicator: a hairline pinned to the very top edge of the
/// screen, full bleed.
///
/// It lives here because it is the one piece of tour chrome that can be in a
/// fixed position honestly. It is 2px tall and sits above everything, so it
/// cannot cover a control no matter what screen the tour is on.
class TourProgressLine extends StatelessWidget {
  const TourProgressLine({super.key, required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = ((index + 1) / math.max(total, 1)).clamp(0.0, 1.0);
    return SizedBox(
      height: 2,
      child: Stack(
        children: [
          Container(color: Colors.white.withValues(alpha: 0.10)),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            widthFactor: progress,
            alignment: Alignment.centerLeft,
            child: Container(color: JHGColors.primary),
          ),
        ],
      ),
    );
  }
}
