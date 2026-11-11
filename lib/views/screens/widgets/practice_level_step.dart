// views/screens/widgets/practice_level_step.dart
//
// The "Level" step of the Customized Practice wizards.
//
// One tappable card per level, in the same glass-card language as the rest of
// the wizard. Each card carries the two things a player actually needs to
// choose: the promise in words, and a miniature neck with the level's fret
// window lit — the diagram is what makes "Frets 0–5 vs 0–15" land instantly
// instead of reading like an arbitrary number.
//
// The step owns only presentation. It reports the picked level to the wizard,
// which applies it to the controller and moves on; the wizard (not this widget)
// knows what the next step is.

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';

import 'package:fretboard/utils/levels.dart';

// Palette — matches mode_select_screen's wizard chrome exactly.
const Color _kPrimary = Color(0xFFFE5D43);
const Color _kOnSurface = Color(0xFFF1F1F1);
const Color _kMuted = Color(0xFF8A8A8A);

/// A single-select list of the three practice levels.
///
/// [eyebrow]/[subtitle] let each wizard number and phrase its own step without
/// this widget knowing the flow.
class PracticeLevelStep extends StatelessWidget {
  const PracticeLevelStep({
    super.key,
    required this.eyebrow,
    required this.subtitle,
    required this.selected,
    required this.onPick,
    this.onCustomize,
    this.customizeLabel = 'Fine-tune instead',
    this.footnote,
  });

  /// "STEP 3 · LEVEL".
  final String eyebrow;

  /// One line under the heading, e.g. "How far up the neck should we go?".
  final String subtitle;

  /// The level currently applied to the session (usually the last-used one), so
  /// its card reads as selected before the user touches anything.
  final PracticeLevel? selected;

  /// Called with the level the user tapped.
  final ValueChanged<PracticeLevel> onPick;

  /// Optional escape hatch that skips the preset and opens the fine-tuning
  /// step. Chords use it; Notes and Intervals have nothing to fine-tune.
  final VoidCallback? onCustomize;
  final String customizeLabel;

  /// Optional muted line under the cards ("You can change this later").
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heading(eyebrow, 'Choose a level', subtitle),
                      const SizedBox(height: 20),
                      for (var i = 0; i < PracticeLevel.values.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        PracticeLevelCard(
                          level: PracticeLevel.values[i],
                          selected: selected == PracticeLevel.values[i],
                          onTap: () => onPick(PracticeLevel.values[i]),
                        ),
                      ],
                      if (onCustomize != null) ...[
                        const SizedBox(height: 18),
                        // A literal tappable row rather than only a TextButton's
                        // onPressed: the label is the affordance, and wrapping
                        // the whole pill (with padding) means a near-miss still
                        // opens the fine-tuning step.
                        Center(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onCustomize,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Text(
                                customizeLabel,
                                style: JhgFonts.inter(
                                  color: _kPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (footnote != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          footnote!,
                          textAlign: TextAlign.center,
                          style: JhgFonts.inter(
                            color: _kMuted.withValues(alpha: 0.75),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heading(String eyebrowText, String title, String sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrowText,
          style: JhgFonts.inter(
            color: _kPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: JhgFonts.poppins(
            color: _kOnSurface,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sub,
          style: JhgFonts.inter(color: _kMuted, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

/// One level card: name, promise, unlocked-fret badge and the mini neck.
class PracticeLevelCard extends StatelessWidget {
  const PracticeLevelCard({
    super.key,
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final PracticeLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _kPrimary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // On a narrow phone the diagram gives up a few pixels before the
            // description has to wrap — losing a third of the neck picture is
            // worse than a narrower diagram, but overflowing the card is worse
            // than both.
            final compact = constraints.maxWidth < 300;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + window pill. Both are Flexible so a card whose
                      // text column runs narrower than the diagram's row cannot
                      // overflow — the pill truncates first, the name only if
                      // it must.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              level.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: JhgFonts.poppins(
                                color: selected ? _kPrimary : _kOnSurface,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: _FretBadge(
                                label: level.fretRangeLabel,
                                selected: selected),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        level.description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: JhgFonts.inter(
                          color: _kMuted.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            // A rising trend reads as "what this level adds"
                            // better than a plus, which looks like an action.
                            JhgIcons.trendUp,
                            size: 12,
                            color: selected ? _kPrimary : _kMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              level.unlocks,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: JhgFonts.inter(
                                color: selected
                                    ? _kPrimary.withValues(alpha: 0.9)
                                    : _kMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                // The window diagram: lit rows = playable frets. It is the whole
                // point of the card, so it sits at the top-right where the eye lands
                // after the level name.
                _LevelNeck(level: level, selected: selected, compact: compact),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The highest fret drawn in a card diagram. One shared extent for all three
/// cards so the windows are directly comparable (0–5 really is a third of 0–15,
/// rather than each card being scaled to fill its own box).
const int _kDiagramMaxFret = 15;

/// Tiny six-string neck with the level's playable frets filled coral.
class _LevelNeck extends StatelessWidget {
  const _LevelNeck({
    required this.level,
    required this.selected,
    this.compact = false,
  });

  final PracticeLevel level;
  final bool selected;

  /// Narrows the diagram on a tight card without changing its proportions.
  final bool compact;

  static const double _width = 64;
  static const double _widthCompact = 46;
  static const double _height = 48;
  static const int _rows = _kDiagramMaxFret + 1; // fret 0 … 15
  // Vertical padding inside the container, and the gap between fret rows. Both
  // are subtracted from the available height before the rows are sized — the
  // first version forgot the padding and overflowed the card by 10px.
  static const double _padV = 4;
  static const double _gap = 0.8;

  @override
  Widget build(BuildContext context) {
    final cap = level.fretCap;
    // Border is 1px on each side, so the padded content box is two pixels short
    // of [_height]. Every row is then an equal share of what is left.
    const available = _height - 2 * (1 + _padV) - (_rows - 1) * _gap;
    const rowHeight = available / _rows;
    final activeColor =
        selected ? _kPrimary : _kPrimary.withValues(alpha: 0.45);
    final inactiveColor = Colors.white.withValues(alpha: 0.05);

    return Semantics(
      label: '${level.label}: ${level.fretRangeLabel}',
      child: Container(
        width: compact ? _widthCompact : _width,
        height: _height,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? _kPrimary.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: _padV, horizontal: 6),
        child: Column(
          children: [
            for (var fret = 0; fret <= _kDiagramMaxFret; fret++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: fret == _kDiagramMaxFret ? 0 : _gap,
                ),
                // Fret 0 is the open string: a slightly brighter first bar so
                // the nut reads even without a label.
                child: Container(
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: fret <= cap ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The small "Frets 0–5" pill next to the level name.
class _FretBadge extends StatelessWidget {
  const _FretBadge({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? _kPrimary.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected
              ? _kPrimary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: JhgFonts.inter(
          color: selected ? _kPrimary : _kMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
