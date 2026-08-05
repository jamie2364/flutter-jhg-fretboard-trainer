import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:fretboard/views/screens/mode_select_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/count_timer_widget.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavBg       = Color(0xFF0F0F0F);
const _kPanelCard   = Color(0xFF1A1A1A);   // dictionaries card bg
// Nav bar: white for the active tab, muted white for the rest — matches the
// dictionaries / drills AppBottomNav (no coral on the icons).
const _kNavActive   = Colors.white;
const _kNavInactive = Colors.white38;

// ─────────────────────────────────────────────────────────────────────────────
// PortraitBoard
// Timer is always visible at the top.
// The fretboard fills all remaining space.
// The control panel floats OVER the fretboard as a blurred card (dict style).
// ─────────────────────────────────────────────────────────────────────────────

class PortraitBoard extends StatefulWidget {
  const PortraitBoard({super.key, required this.controller});
  final HomeController controller;

  @override
  State<PortraitBoard> createState() => _PortraitBoardState();
}

class _PortraitBoardState extends State<PortraitBoard> {
  bool _panelCollapsed = false;
  bool _prevGameRunning = false;
  Worker? _panelWorker;

  @override
  void initState() {
    super.initState();
    _panelWorker = ever(widget.controller.isBottomPanelExpanded, (bool exp) {
      if (mounted) setState(() => _panelCollapsed = !exp);
    });
  }

  @override
  void dispose() {
    _panelWorker?.dispose();
    super.dispose();
  }

  void _setCollapsed(bool v) {
    setState(() => _panelCollapsed = v);
    widget.controller.isBottomPanelExpanded.value = !v;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GetBuilder<HomeController>(
      builder: (c) {
        final isReverse = c.currentGameMode.value == 'reverse';
        final isInterval = c.currentGameMode.value == 'interval';
        final isChord = c.currentGameMode.value == 'chord';
        final gameRunning = c.isStart || c.isPaused;

        // Auto-collapse when the game starts (more fretboard); auto-expand
        // again when it ends. Applies to every mode.
        if (!_prevGameRunning && gameRunning && !_panelCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_panelCollapsed) _setCollapsed(true);
          });
        }
        if (_prevGameRunning && !gameRunning && _panelCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _panelCollapsed) _setCollapsed(false);
          });
        }
        _prevGameRunning = gameRunning;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // Small top breathing room (the mode switcher used to live here;
              // mode is now chosen from the Home tab in the nav bar).
              const SizedBox(height: 6),

              // ── Fretboard fills full Expanded height at all times ────────
              // Both the expanded panel and the collapsed tile are Positioned
              // overlays so the GuitarBoard always gets the full space.
              Expanded(
                key: tourKeyFretboard,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(
                          // The fixed-pixel GuitarBoard self-centres (board +
                          // 26px number gutter), so no extra left offset is
                          // needed here — matches the dictionaries layout.
                          // Reserve room for the collapsed bar so the board
                          // doesn't stretch underneath it (matches dictionaries).
                          // The bar is taller in identify mode (answer buttons).
                          // When the expanded panel is open, keep a 12px gap so
                          // the board ends level with the panel's bottom and
                          // never peeks under it onto the nav bar (matches the
                          // drills / dictionaries floating-panel layout).
                          bottom: _panelCollapsed
                              ? (c.isStart || c.isPaused)
                                  // Interval / chord NAME need room for the 2×2
                                  // choice grid; chord BUILD needs its controls.
                                  ? (c.isIntervalName || c.isChordName
                                      ? 210
                                      : isReverse
                                          ? 148
                                          : c.isChordBuild
                                              ? 104
                                              : 84)
                                  : 84
                              : 12,
                        ),
                        child: const GuitarBoard(isPortrait: true),
                      ),
                    ),

                    // Expanded floating card
                    if (!_panelCollapsed)
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: _ExpandedPanel(
                            controller: c,
                            isReverse: isReverse,
                            isInterval: isInterval,
                            isChord: isChord,
                            onCollapse: () => _setCollapsed(true),
                          ),
                        ),
                      ),

                    // Collapsed tile — full-width bar below the fretboard
                    // (matches drills / dictionaries).
                    if (_panelCollapsed)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: _CollapsedTile(
                          controller: c,
                          isReverse: isReverse,
                          isInterval: isInterval,
                          isChord: isChord,
                          onExpand: () => _setCollapsed(false),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Nav bar ──────────────────────────────────────────────────
              _FretboardNavBar(
                key: tourKeyNavBar,
                safeBottom: bottomInset,
                controller: c,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Expanded floating card ────────────────────────────────────────────────────
// Blurred glass card that overlays the bottom of the fretboard.
// Uses dictionaries' ClipRRect → BackdropFilter → Container pattern.

class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({
    required this.controller,
    required this.isReverse,
    required this.isInterval,
    required this.isChord,
    required this.onCollapse,
  });

  final HomeController controller;
  final bool isReverse;
  final bool isInterval;
  final bool isChord;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _kPanelCard.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Header row: label + collapse arrow ──────────────────────
              Row(
                children: [
                  Text(
                    !c.isStart && !c.isPaused
                        ? (isChord
                            ? 'CHORD MODE'
                            : isInterval
                                ? 'INTERVALS MODE'
                                : isReverse
                                    ? 'IDENTIFY MODE'
                                    : 'FIND NOTE MODE')
                        : isChord
                            ? (c.isChordBuild
                                ? 'BUILD THE CHORD'
                                : 'NAME THE CHORD')
                            : isInterval
                                ? (c.isIntervalBuild
                                    ? 'BUILD THE INTERVAL'
                                    : 'NAME THE INTERVAL')
                                : isReverse
                                    ? 'WHICH NOTE IS THIS?'
                                    : 'FIND THE NOTE',
                    style: const TextStyle(
                      color: Color(0xFFE3BEB7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCollapse,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: const Icon(LucideIcons.chevronDown300,
                          color: Colors.white54, size: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Timer — lives in the tile now (not the top) ──────────────
              Center(
                child: KeyedSubtree(
                  key: tourKeyTimer,
                  child: const CountTimerWidget(),
                ),
              ),
              const SizedBox(height: 14),

              // ── Content: depends on game state ───────────────────────────

              // Idle: hint only. Mode + difficulty are chosen before this
              // screen (startup / interval setup wizard).
              if (!c.isStart && !c.isPaused) ...[
                Text(
                  isChord
                      ? (c.isChordBuild
                          ? 'A chord name shows — tap the frets to build the shape'
                          : 'A chord lights up — name it from the choices')
                      : isInterval
                          ? (c.isIntervalBuild
                              ? 'A root note lights up — tap the fret an interval away'
                              : 'Two notes light up — name the interval between them')
                          : isReverse
                              ? 'A fret lights up — pick the correct note name'
                              : 'Find the note shown here on the fretboard',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 13,
                    fontWeight: FontWeight.w500, height: 1.4),
                ),
                const SizedBox(height: 14),
              ]

              // Interval NAME playing: 2×2 interval-name grid
              else if (c.isIntervalName) ...[
                _IntervalChoicePanel(controller: c),
                const SizedBox(height: 14),
              ]

              // Interval BUILD playing: the target interval to play + score
              else if (c.isIntervalBuild) ...[
                _IntervalBuildPrompt(controller: c),
                const SizedBox(height: 14),
              ]

              // Chord NAME playing: choice grid of chord symbols
              else if (c.isChordName) ...[
                _ChordChoicePanel(controller: c),
                const SizedBox(height: 14),
              ]

              // Chord BUILD playing: the chord to place + score + controls
              else if (c.isChordBuild) ...[
                _ChordBuildPrompt(controller: c),
                const SizedBox(height: 14),
              ]

              // Identify mode playing: answer buttons
              else if (isReverse) ...[
                _ReverseChoicePanel(controller: c),
                const SizedBox(height: 14),
              ]

              // Find note mode playing: note badge + score
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        color: JHGColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: JHGColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(c.highlightNode ?? '',
                          style: GoogleFonts.poppins(
                            color: JHGColors.primary, fontSize: 28,
                            fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('SCORE',
                            style: GoogleFonts.inter(
                              color: Colors.white38, fontSize: 11,
                              fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                        const SizedBox(width: 8),
                        Text(c.score.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // ── Control row ──────────────────────────────────────────────
              _ControlRow(controller: c),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Collapsed bar — full-width, below the fretboard (matches drills/dict) ─────

class _CollapsedTile extends StatelessWidget {
  const _CollapsedTile({
    required this.controller,
    required this.isReverse,
    required this.isInterval,
    required this.isChord,
    required this.onExpand,
  });

  final HomeController controller;
  final bool isReverse;
  final bool isInterval;
  final bool isChord;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isPlaying = c.isStart || c.isPaused;
    final modeLabel = isChord
        ? 'CHORD MODE'
        : isInterval
            ? 'INTERVALS MODE'
            : isReverse
                ? 'IDENTIFY MODE'
                : 'FIND NOTE MODE';
    final showAnswers =
        isReverse && isPlaying && c.reverseChoices.isNotEmpty;
    final showIntervalAnswers =
        c.isIntervalName && isPlaying && c.intervalChoicesList.isNotEmpty;
    final showChordAnswers =
        c.isChordName && isPlaying && c.chordChoicesList.isNotEmpty;
    final showChordBuildControls = c.isChordBuild && isPlaying;
    final locked = c.reverseSelectedNote != null;
    final intervalLocked = c.intervalSelected != null;

    // Compact time pill — the clock now lives here when the tile is collapsed.
    final timeChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer300,
              size: 13, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 5),
          Text(
            c.formatTime(c.secondsRemaining.value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    // Compact score pill — shown collapsed in every mode so the running total
    // stays visible without expanding the panel.
    final scoreChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded,
              size: 13, color: JHGColors.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            c.score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    Widget answerButton(String note) {
      final s = _answerStyle(note, c);
      return GestureDetector(
        onTap: locked ? null : () => c.selectReverseAnswer(note),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: s.border, width: 1.4),
          ),
          child: Center(
            child: Text(
              note,
              style: TextStyle(
                color: s.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      );
    }

    final playBtn = GestureDetector(
      onTap: c.isStart
          ? c.pauseGame
          : c.isPaused
              ? c.resumeGame
              : () {
                  c.startTimer();
                  c.startTheGame();
                },
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: JHGColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: JHGColors.primary.withValues(alpha: 0.40),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          c.isStart ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );

    final expandBtn = GestureDetector(
      onTap: onExpand,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Icon(LucideIcons.chevronUp300,
            color: Colors.white54, size: 18),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _kPanelCard.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBC8C6),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (!isPlaying)
                          const Text(
                            'Tap play to start',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFFE5D43),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          )
                        else if (isChord && c.isChordBuild)
                          Row(
                            children: [
                              const Text(
                                'Play',
                                style: TextStyle(
                                  color: Color(0xFFE5E2E1),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  c.chordPrompt?.symbol ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFE5D43),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (isChord)
                          const Text(
                            'Which chord?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFE5E2E1),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          )
                        else if (isInterval && c.isIntervalBuild)
                          Row(
                            children: [
                              const Text(
                                'Play',
                                style: TextStyle(
                                  color: Color(0xFFE5E2E1),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  c.intervalPrompt?.interval.name ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFE5D43),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (isInterval)
                          const Text(
                            'Which interval?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFE5E2E1),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          )
                        else if (isReverse)
                          const Text(
                            'Which note is this?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFE5E2E1),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.1,
                            ),
                          )
                        else
                          // Find mode: "Find" white, the target note coral —
                          // same size, note is bolder so it still stands out.
                          Row(
                            children: [
                              const Text(
                                'Find',
                                style: TextStyle(
                                  color: Color(0xFFE5E2E1),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.highlightNode ?? '—',
                                style: const TextStyle(
                                  color: Color(0xFFFE5D43),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (isPlaying) ...[
                    scoreChip,
                    const SizedBox(width: 6),
                    timeChip,
                    const SizedBox(width: 8),
                  ],
                  playBtn,
                  const SizedBox(width: 8),
                  expandBtn,
                ],
              ),
              // Identify mode: answer choices stay usable while collapsed.
              if (showAnswers) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0; i < c.reverseChoices.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: answerButton(c.reverseChoices[i])),
                    ],
                  ],
                ),
              ],
              // Interval NAME mode: 2×2 grid stays usable while collapsed.
              if (showIntervalAnswers) ...[
                const SizedBox(height: 10),
                _IntervalChoiceGrid(
                  controller: c,
                  locked: intervalLocked,
                ),
              ],
              // Chord NAME mode: 2×2 symbol grid stays usable while collapsed.
              if (showChordAnswers) ...[
                const SizedBox(height: 10),
                _ChordChoiceGrid(
                  controller: c,
                  locked: c.chordSelected != null,
                ),
              ],
              // Chord BUILD mode: clear / reveal controls while collapsed.
              if (showChordBuildControls) ...[
                const SizedBox(height: 10),
                _ChordBuildControls(controller: c),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Answer-button colour helper (shared by tile + expanded panel) ─────────────

_BtnStyle _answerStyle(String note, HomeController c) {
  final selected = c.reverseSelectedNote;
  if (selected == null) {
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.08),
      border: Colors.white.withValues(alpha: 0.12),
      text: Colors.white,
    );
  }
  if (note == c.highlightNode) {
    return _BtnStyle(
      bg: JHGColors.green.withValues(alpha: 0.20),
      border: JHGColors.green,
      text: JHGColors.green,
    );
  }
  if (note == selected && !c.reverseWasCorrect) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.03),
    border: Colors.white.withValues(alpha: 0.05),
    text: Colors.white30,
  );
}

// ─── Shared control row ───────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  final HomeController controller;
  const _ControlRow({required this.controller});

  IconData _resolveTimerIcon(String mode) {
    switch (mode) {
      case 'countdown':   return LucideIcons.clock300;
      case 'leaderboard': return LucideIcons.trophy300;
      default:            return LucideIcons.timer300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isChoiceMode = c.isChoiceMode;
    final mode = c.currentGameMode.value;
    final disabled = c.isStart || c.isPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [

        // Timer-mode cycle
        GestureDetector(
          onTap: disabled ? null : c.cycleGameMode,
          child: Container(
            height: 56, width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              _resolveTimerIcon(isChoiceMode ? c.timerMode.value : mode),
              color: disabled ? Colors.white24 : Colors.white60, size: 22,
            ),
          ),
        ),

        // Play / Stop / Resume
        GestureDetector(
          onTap: c.isStart
              ? c.pauseGame
              : c.isPaused
                  ? c.resumeGame
                  : () { c.startTimer(); c.startTheGame(); },
          child: AnimatedContainer(
            key: tourKeyPlayButton,
            duration: const Duration(milliseconds: 200),
            height: 72, width: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JHGColors.primary,
              boxShadow: [
                BoxShadow(
                  color: JHGColors.primary.withValues(
                      alpha: c.isStart ? 0.50 : 0.22),
                  blurRadius: c.isStart ? 28 : 14,
                ),
              ],
            ),
            child: Icon(
              c.isStart ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white, size: 36,
            ),
          ),
        ),

        // Reset
        GestureDetector(
          onTap: () => c.resetGame(true),
          child: Container(
            height: 56, width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white60, size: 22),
          ),
        ),
      ],
    );
  }
}

// ─── Mode tile (bottom sheet) ─────────────────────────────────────────────────

class _FretboardNavBar extends StatelessWidget {
  const _FretboardNavBar({
    super.key, required this.safeBottom, required this.controller,
  });
  final double safeBottom;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    // Mid-session, Leaders/Stats are locked so the running game can't be
    // abandoned. Home and Train reset/return deliberately, so they stay open.
    // Settings is additionally locked in leaderboard mode.
    final sessionActive = controller.sessionActive;
    final canOpenSettings =
        controller.currentGameMode.value != 'leaderboard' && !sessionActive;
    return Container(
      height: 56 + safeBottom,
      decoration: BoxDecoration(
        color: _kNavBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 568),
          child: Padding(
            padding: EdgeInsets.only(bottom: safeBottom),
            child: Row(
              children: [
                // Home → the very first screen, where the user picks a mode.
                _NavItem(
                  icon: LucideIcons.home300,
                  label: 'Home',
                  isActive: false,
                  onTap: () {
                    controller.resetGame(false);
                    Get.off(() => const ModeSelectScreen(),
                        transition: Transition.noTransition,
                        duration: Duration.zero);
                  },
                ),
                // Train → the main training board (this screen).
                _NavItem(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Train',
                  isActive: true,
                  onTap: () => Get.until((route) => route.isFirst),
                ),
                _NavItem(
                  icon: LucideIcons.trophy300,
                  label: 'Leaders',
                  disabled: sessionActive,
                  onTap: sessionActive
                      ? null
                      : () {
                          Get.to(() => LeadershipScreen(),
                              transition: Transition.noTransition,
                              duration: Duration.zero);
                          if (isFreePlan) {
                            controller.interstitialAds?.showInterstitial();
                          }
                        },
                ),
                _NavItem(
                  key: tourKeyHeatmapNav,
                  icon: Icons.insights_rounded,
                  label: 'Stats',
                  disabled: sessionActive,
                  onTap: sessionActive
                      ? null
                      : () => Get.to(
                            () => const HeatmapScreen(),
                            transition: Transition.noTransition,
                            duration: Duration.zero,
                          ),
                ),
                _NavItem(
                  icon: LucideIcons.settings300,
                  label: 'Settings',
                  onTap: canOpenSettings
                      ? () {
                          controller.resetGame(false);
                          Get.to(() => SettingScreen(),
                              transition: Transition.noTransition,
                              duration: Duration.zero);
                          if (isFreePlan) {
                            controller.interstitialAds?.showInterstitial();
                          }
                        }
                      : null,
                  disabled: !canOpenSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key, required this.icon, required this.label,
    this.onTap, this.isActive = false, this.disabled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? Colors.white12
        : isActive ? _kNavActive : _kNavInactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 10,
                decoration: TextDecoration.none,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reverse mode choice panel ────────────────────────────────────────────────

class _ReverseChoicePanel extends StatelessWidget {
  const _ReverseChoicePanel({required this.controller});
  final HomeController controller;


  @override
  Widget build(BuildContext context) {
    if (controller.reverseChoices.isEmpty) return const SizedBox.shrink();
    final locked = controller.reverseSelectedNote != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('SCORE', style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(width: 6),
                Text(controller.score.toString(), style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 15,
                  fontWeight: FontWeight.bold)),
              ]),
            ),
            if (controller.identifyShowPositionHint)
              Text(controller.reversePositionHint, style: GoogleFonts.inter(
                color: Colors.white38, fontSize: 10,
                fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: controller.reverseChoices.map((note) {
            final s = _answerStyle(note, controller);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: locked ? null : () => controller.selectReverseAnswer(note),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 58,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: s.border, width: 1.5),
                    ),
                    child: Center(
                      child: Text(note, style: GoogleFonts.poppins(
                        color: s.text, fontSize: 16,
                        fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BtnStyle {
  const _BtnStyle({required this.bg, required this.border, required this.text});
  final Color bg;
  final Color border;
  final Color text;
}

// ─── Interval mode ───────────────────────────────────────────────────────────

// Small score chip reused by the interval panels.
Widget _intervalScoreChip(HomeController c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('SCORE',
            style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(width: 6),
        Text(c.score.toString(),
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
    );

// Expanded-panel version: score chip above the 2×2 name grid.
class _IntervalChoicePanel extends StatelessWidget {
  const _IntervalChoicePanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.intervalChoicesList.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _intervalScoreChip(c),
        ]),
        const SizedBox(height: 12),
        _IntervalChoiceGrid(controller: c, locked: c.intervalSelected != null),
      ],
    );
  }
}

// 2×2 grid of interval-name choices (names are too long for a single row).
// Shared by the expanded panel and the collapsed tile.
class _IntervalChoiceGrid extends StatelessWidget {
  const _IntervalChoiceGrid({required this.controller, required this.locked});
  final HomeController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final choices = c.intervalChoicesList;
    if (choices.isEmpty) return const SizedBox.shrink();

    Widget button(MusicInterval choice) {
      final s = _intervalStyle(choice, c);
      return GestureDetector(
        onTap: locked ? null : () => c.selectIntervalAnswer(choice),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: s.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            choice.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: s.text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    Widget row(int a, int b) => Row(
          children: [
            Expanded(child: button(choices[a])),
            const SizedBox(width: 10),
            if (b < choices.length)
              Expanded(child: button(choices[b]))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, 1),
        const SizedBox(height: 10),
        row(2, 3),
      ],
    );
  }
}

// Build mode: shows the interval to play (relative to the coral root note) plus
// the score, with a plain-language instruction so the task is unambiguous.
class _IntervalBuildPrompt extends StatelessWidget {
  const _IntervalBuildPrompt({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final name = c.intervalPrompt?.interval.name ?? '—';
    final rootNote = c.intervalRootIndex != null
        ? (fretList[c.intervalRootIndex!].note ?? '')
        : '';
    final direction = c.intervalDifficulty == IntervalDifficulty.hard
        ? 'above or below'
        : 'above';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: JHGColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('PLAY A',
                    style: GoogleFonts.inter(
                      color: JHGColors.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    )),
                const SizedBox(width: 10),
                Text(name,
                    style: GoogleFonts.poppins(
                      color: JHGColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
            ),
            const SizedBox(width: 12),
            _intervalScoreChip(c),
          ],
        ),
        const SizedBox(height: 8),
        // Plain-language instruction referencing the coral note on the neck.
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 12.5, height: 1.35),
            children: [
              const TextSpan(text: 'Tap the note '),
              TextSpan(
                text: name.toLowerCase(),
                style: const TextStyle(
                    color: Color(0xFFE5E2E1), fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' $direction the '),
              const TextSpan(
                text: 'coral',
                style: TextStyle(
                    color: Color(0xFFFE5D43), fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: rootNote.isEmpty ? ' note' : ' note ($rootNote)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Interval answer-button colours: neutral until locked, then green for the
// correct interval and coral for a wrong pick.
_BtnStyle _intervalStyle(MusicInterval choice, HomeController c) {
  final selected = c.intervalSelected;
  final correct = c.intervalPrompt?.interval;
  if (selected == null || correct == null) {
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.08),
      border: Colors.white.withValues(alpha: 0.12),
      text: Colors.white,
    );
  }
  if (choice.semitones == correct.semitones) {
    return _BtnStyle(
      bg: JHGColors.green.withValues(alpha: 0.20),
      border: JHGColors.green,
      text: JHGColors.green,
    );
  }
  if (choice.semitones == selected.semitones && !c.intervalWasCorrect) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.03),
    border: Colors.white.withValues(alpha: 0.05),
    text: Colors.white30,
  );
}

// ─── Chord mode ──────────────────────────────────────────────────────────────

// Chord-symbol button colours: neutral until an answer is locked, then green
// for the correct symbol and coral for a wrong pick.
_BtnStyle _chordSymbolStyle(String symbol, HomeController c) {
  final selected = c.chordSelected;
  final correct = c.chordPrompt?.symbol;
  if (selected == null || correct == null) {
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.08),
      border: Colors.white.withValues(alpha: 0.12),
      text: Colors.white,
    );
  }
  if (symbol == correct) {
    return _BtnStyle(
      bg: JHGColors.green.withValues(alpha: 0.20),
      border: JHGColors.green,
      text: JHGColors.green,
    );
  }
  if (symbol == selected && !c.chordWasCorrect) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.03),
    border: Colors.white.withValues(alpha: 0.05),
    text: Colors.white30,
  );
}

// Expanded-panel version: score chip above the 2×2 symbol grid.
class _ChordChoicePanel extends StatelessWidget {
  const _ChordChoicePanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.chordChoicesList.isEmpty) {
      return _chordLoadingHint(c);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _intervalScoreChip(c),
        ]),
        const SizedBox(height: 12),
        _ChordChoiceGrid(controller: c, locked: c.chordSelected != null),
      ],
    );
  }
}

// 2×2 grid of chord-symbol choices — shared by the expanded panel and the
// collapsed tile.
class _ChordChoiceGrid extends StatelessWidget {
  const _ChordChoiceGrid({required this.controller, required this.locked});
  final HomeController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final choices = c.chordChoicesList;
    if (choices.isEmpty) return const SizedBox.shrink();

    Widget button(String symbol) {
      final s = _chordSymbolStyle(symbol, c);
      return GestureDetector(
        onTap: locked ? null : () => c.selectChordAnswer(symbol),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: s.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            symbol,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: s.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    Widget row(int a, int b) => Row(
          children: [
            Expanded(child: button(choices[a])),
            const SizedBox(width: 10),
            if (b < choices.length)
              Expanded(child: button(choices[b]))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, 1),
        if (choices.length > 2) ...[
          const SizedBox(height: 10),
          row(2, 3),
        ],
      ],
    );
  }
}

// Build mode: the chord symbol to place + score + a plain-language instruction,
// with Clear / Reveal controls underneath.
class _ChordBuildPrompt extends StatelessWidget {
  const _ChordBuildPrompt({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.chordPrompt == null) return _chordLoadingHint(c);
    final shape = c.chordPrompt!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: JHGColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('PLAY',
                    style: GoogleFonts.inter(
                      color: JHGColors.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    )),
                const SizedBox(width: 10),
                Text(shape.symbol,
                    style: GoogleFonts.poppins(
                      color: JHGColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
            ),
            const SizedBox(width: 12),
            _intervalScoreChip(c),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${shape.qualityName} — tap the frets to build the shape',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: Colors.white54, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 12),
        _ChordBuildControls(controller: c),
      ],
    );
  }
}

// Notes-placed counter + Clear + Reveal, used in both the expanded panel and
// the collapsed tile.
class _ChordBuildControls extends StatelessWidget {
  const _ChordBuildControls({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final placed = c.chordTapped.length;
    final done = c.chordBuildDone;

    Widget pill({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      Color? tint,
    }) {
      final color = tint ?? Colors.white70;
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: onTap == null ? 0.03 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 15,
                color: onTap == null ? Colors.white24 : color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                  color: onTap == null ? Colors.white24 : color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
          ]),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$placed placed',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        pill(
          icon: Icons.backspace_rounded,
          label: 'Clear',
          onTap: (placed == 0 || done) ? null : c.clearChordBuild,
        ),
        const SizedBox(width: 8),
        pill(
          icon: Icons.visibility_rounded,
          label: 'Reveal',
          tint: JHGColors.primary,
          onTap: done ? null : c.revealChordBuild,
        ),
      ],
    );
  }
}

// Shown while the chord library is still parsing on the first play.
Widget _chordLoadingHint(HomeController c) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      c.chordCatalogLoading ? 'Loading chords…' : 'Getting the next chord…',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
