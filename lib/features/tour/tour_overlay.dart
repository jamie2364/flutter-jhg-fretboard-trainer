import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tour_controller.dart';
import 'tour_step.dart';

class TourOverlay extends StatefulWidget {
  final TourController controller;
  const TourOverlay({super.key, required this.controller});

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with TickerProviderStateMixin {
  Rect? _targetRect;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;

  Worker? _stepWorker;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.currentTourStep.onActivate?.call();
        _refreshTargetRect();
        _fadeCtrl.forward();
      }
    });

    _stepWorker = ever<int>(widget.controller.currentStep, (_) {
      if (!mounted) return;
      _fadeCtrl.reverse().whenComplete(() {
        if (!mounted) return;
        widget.controller.currentTourStep.onActivate?.call();
        _pulseCtrl.reset();
        _pulseCtrl.repeat();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _refreshTargetRect();
          _fadeCtrl.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _stepWorker?.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _refreshTargetRect() {
    if (!mounted) return;
    final key = widget.controller.currentTourStep.targetKey;
    if (key?.currentContext == null) {
      setState(() => _targetRect = null);
      return;
    }
    try {
      final targetBox = key!.currentContext!.findRenderObject() as RenderBox?;
      if (targetBox == null || !targetBox.hasSize) {
        setState(() => _targetRect = null);
        return;
      }
      final overlayBox = context.findRenderObject() as RenderBox?;
      if (overlayBox == null) {
        setState(() => _targetRect = null);
        return;
      }
      final offset = targetBox.localToGlobal(Offset.zero) -
          overlayBox.localToGlobal(Offset.zero);
      setState(() => _targetRect = offset & targetBox.size);
    } catch (_) {
      setState(() => _targetRect = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!widget.controller.isVisible.value) return const SizedBox.shrink();

      final step = widget.controller.currentTourStep;
      final size = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      final spotlight = _targetRect?.inflate(step.spotlightPadding);

      return Material(
        type: MaterialType.transparency,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SizedBox.expand(
            child: Stack(
              children: [
                // 1. Dark backdrop with spotlight cutout (IgnorePointer —
                //    does NOT block user taps to widgets below).
                if (step.showBackdrop)
                  IgnorePointer(
                    child: CustomPaint(
                      size: size,
                      painter: _OverlayPainter(spotlight: spotlight),
                    ),
                  ),

                // 2. Full-screen tap blocker (only when requested).
                if (step.blockBackground)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: spotlight == null
                        ? null
                        : (TapUpDetails d) {
                            if (spotlight.contains(d.localPosition)) {
                              step.onSpotlightTap?.call();
                            }
                          },
                    child: const SizedBox.expand(),
                  ),

                // 3. Pulsing ring around spotlight.
                if (spotlight != null)
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => CustomPaint(
                        size: size,
                        painter: _PulseRingPainter(
                            rect: spotlight, progress: _pulseCtrl.value),
                      ),
                    ),
                  ),

                // 4. Skip button — top-right, always accessible.
                Positioned(
                  top: padding.top + 10,
                  right: kIsWeb
                      ? ((size.width - 520.0) / 2.0 + 12.0)
                          .clamp(12.0, double.infinity)
                      : 14.0,
                  child: GestureDetector(
                    onTap: widget.controller.skip,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Floating label card.
                _buildLabel(step, size, padding, spotlight),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLabel(
      TourStep step, Size size, EdgeInsets padding, Rect? spotlight) {
    const hPad = 28.0;
    const estimatedCardH = 230.0;
    final cardW = (size.width - hPad * 2).clamp(0.0, 400.0);
    final hasSpotlight = spotlight != null;

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepDots(
          current: widget.controller.currentStep.value,
          total: widget.controller.totalSteps,
        ),
        const SizedBox(height: 12),
        Text(
          step.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                  color: Colors.black87,
                  blurRadius: 16,
                  offset: Offset(0, 2)),
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (step.subtitleBuilder != null)
          step.subtitleBuilder!()
        else if (step.subtitle != null)
          Text(
            step.subtitle!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 13,
              height: 1.5,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 10)
              ],
            ),
          ),
        // Show action button when the step isn't waiting for the user to
        // interact with the UI directly, OR when there is no spotlight to
        // tap (user would otherwise have no way to advance).
        if (!step.isInteractive || !hasSpotlight) ...[
          const SizedBox(height: 14),
          _ActionButton(
            label: step.actionLabel ??
                (widget.controller.isLastStep ? 'Start Playing  🎸' : 'Next  →'),
            onTap: step.onActionTap ?? widget.controller.next,
          ),
        ],
      ],
    );

    // Always position the label at the screen centre so it appears in a
    // consistent, predictable location regardless of where the spotlight is.
    // labelYOffset (set per step) shifts the card up (negative) or down.
    // On web, use a smaller upward bias (-40) since the layout is taller.
    // Spotlight steps: try below → above → centre.
    double baseY;
    bool needsDarkCard = false;

    if (hasSpotlight) {
      final double belowY = spotlight.bottom + 16;
      final double aboveY = spotlight.top - estimatedCardH - 16;
      final bool fitsBelow = belowY + estimatedCardH < size.height - 24;
      final bool fitsAbove = aboveY > padding.top + 8;

      if (fitsBelow) {
        baseY = belowY;
      } else if (fitsAbove) {
        baseY = aboveY;
      } else {
        baseY = size.height / 2 - estimatedCardH / 2;
        needsDarkCard = true;
      }
    } else {
      final double baseOffset = kIsWeb ? -40.0 : -90.0;
      baseY = size.height / 2 + baseOffset;
    }

    final double top = (baseY + step.labelYOffset)
        .clamp(padding.top + 20.0, size.height - estimatedCardH - 8.0);
    final double left =
        ((size.width - cardW) / 2).clamp(hPad, size.width - cardW - hPad);

    final Widget card = Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: needsDarkCard || !step.showBackdrop
            ? Colors.black.withValues(alpha: 0.90)
            : Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: cardContent,
    );

    // Interactive steps with no backdrop: card is visible but taps pass
    // through to the underlying UI (fretboard / answer buttons).
    final bool passThrough =
        step.isInteractive && !step.showBackdrop && !step.blockBackground;

    return Positioned(
      left: left,
      top: top,
      width: cardW,
      child: passThrough ? IgnorePointer(child: card) : card,
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final Rect? spotlight;
  const _OverlayPainter({this.spotlight});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xCC000000);
    if (spotlight == null) {
      canvas.drawRect(Offset.zero & size, bg);
      return;
    }
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, bg);
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlight!, const Radius.circular(20)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.spotlight != spotlight;
}

class _PulseRingPainter extends CustomPainter {
  final Rect rect;
  final double progress;
  const _PulseRingPainter({required this.rect, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final expand = progress * 14;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(expand),
        Radius.circular(20 + expand * 0.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = JHGColors.primary.withValues(alpha: opacity * 0.9),
    );
  }

  @override
  bool shouldRepaint(_PulseRingPainter old) => old.progress != progress;
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                active ? Colors.white : Colors.white.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? JHGColors.primary
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: JHGColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white38,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
