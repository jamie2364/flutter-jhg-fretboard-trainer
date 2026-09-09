import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:fretboard/views/screens/saved/save_session_dialog.dart';
import 'package:fretboard/views/widgets/show_toast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/count_timer_widget.dart';

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

              // Modes shifter — Quick start hands mode-picking to the board,
              // so (and only so) the dictionaries-style top-left "MODES"
              // eyebrow appears here. A Customized / Random / resumed session
              // picked its mode deliberately, so nothing is shown.
              if (c.quickStartSession) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _BoardModeSwitcher(controller: c),
                  ),
                ),
                const SizedBox(height: 6),
              ] else
                const SizedBox(height: 6),

              // ── Fretboard fills full Expanded height at all times ────────
              // Both the expanded panel and the collapsed tile are Positioned
              // overlays so the GuitarBoard always gets the full space.
              Expanded(
                key: tourKeyFretboard,
                child: Stack(
                  children: [
                    // The fixed-pixel GuitarBoard fills the whole area and the
                    // tile floats OVER its lower portion (matches drills /
                    // dictionaries) — the neck runs behind the tile rather than
                    // being clipped above it. Auto-scroll keeps the active notes
                    // centred in the open area above the tile.
                    const Positioned.fill(
                      child: GuitarBoard(isPortrait: true),
                    ),

                    // One bottom overlay that animates between the expanded card
                    // and the collapsed tile. AnimatedSize grows/shrinks the
                    // height from the bottom edge while the contents cross-fade,
                    // so the swap reads as a smooth slide rather than a jump.
                    //
                    // The layoutBuilder pins the *outgoing* panel with a bottom
                    // Positioned so it no longer drives the Stack's size. Only
                    // the incoming child sets the height, which lets AnimatedSize
                    // begin easing toward the new height on the very first frame
                    // instead of holding at the tall height until the fade ends
                    // and then snapping down. The height and the cross-fade run
                    // over the same interval so they read as a single motion.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOutCubic,
                            switchOutCurve: Curves.easeInOutCubic,
                            layoutBuilder: (currentChild, previousChildren) =>
                                Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                for (final prev in previousChildren)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: prev,
                                  ),
                                if (currentChild != null) currentChild,
                              ],
                            ),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: _panelCollapsed
                                ? _CollapsedTile(
                                    key: const ValueKey('tile-collapsed'),
                                    controller: c,
                                    isReverse: isReverse,
                                    isInterval: isInterval,
                                    isChord: isChord,
                                    onExpand: () => _setCollapsed(false),
                                  )
                                : _ExpandedPanel(
                                    key: const ValueKey('tile-expanded'),
                                    controller: c,
                                    isReverse: isReverse,
                                    isInterval: isInterval,
                                    isChord: isChord,
                                    onCollapse: () => _setCollapsed(true),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Nav bar (shared AppNavBar, so height/placement stay
              // identical across the board and every other screen) ──────────
              AppNavBar(
                key: tourKeyNavBar,
                activeTab: AppTab.train,
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
    super.key,
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

    return JhgGlassTile.open(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // ── Header row: label + collapse arrow ──────────────────────
          Row(
            children: [
              Text(
                // Always the game type, so the user knows exactly what
                // they're practising (matters most in Random Practice,
                // where the type was rolled for them).
                isChord
                    ? (c.isChordLab
                        ? _chordLabHeader(c)
                        : c.isChordBuild
                            ? 'BUILD THE CHORD'
                            : 'NAME THE CHORD')
                    : isInterval
                        ? (c.isIntervalBuild
                            ? 'BUILD THE INTERVAL'
                            : 'NAME THE INTERVAL')
                        : isReverse
                            ? 'IDENTIFY THE NOTE'
                            : 'FIND THE NOTE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              // Skip — draw a fresh question, no score change. Only while a
              // round is running.
              if (c.isStart)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: JhgIconChipButton.compact(
                    icon: Icons.skip_next_rounded,
                    onTap: c.skipQuestion,
                    iconColor: Colors.white54,
                  ),
                ),
              // Listen — audio is no longer auto-played during a round;
              // tap to hear the current note/chord. Active only while a
              // round is running.
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: JhgIconChipButton.compact(
                  icon: Icons.volume_up_rounded,
                  onTap: c.isStart ? c.playCurrentPrompt : () {},
                  iconColor: c.isStart ? Colors.white54 : Colors.white24,
                ),
              ),
              JhgGlassChevron(onTap: onCollapse, expanded: true),
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

          // Idle: no explainer line — the header already names the game and
          // "Press play to start" guidance lives in the prompt widgets.
          if (!c.isStart && !c.isPaused) ...[
            const SizedBox(height: 4),
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

          // Chord Lab playing: per-round prompt + score (+ name grid)
          else if (c.isChordLab) ...[
            _ChordLabPanel(controller: c),
            const SizedBox(height: 14),
          ]

          // Identify mode playing: answer buttons
          else if (isReverse) ...[
            _ReverseChoicePanel(controller: c),
            const SizedBox(height: 14),
          ]

          // Find note mode playing: note badge (score now lives in the
          // bottom score bar).
          else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
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
            ),
            const SizedBox(height: 14),
          ],

          // ── Score bar — score sits below the options, in every mode ──
          if (c.isStart || c.isPaused) ...[
            _ScoreBar(controller: c),
            const SizedBox(height: 14),
          ],

          // ── Control row ──────────────────────────────────────────────
          _ControlRow(controller: c),
        ],
      ),
    );
  }
}

// ─── Collapsed bar — full-width, below the fretboard (matches drills/dict) ─────

/// Collapsed-tile prompt type.
///
/// [_kTileHero] is for the single thing the round is about (a note name, a
/// chord symbol, an interval). [_kTileLead] is the small word in front of it
/// ("Find", "Play"), and [_kTileAsk] is for a prompt that is a question rather
/// than a token, where the board itself is carrying the content.
const TextStyle _kTileHero = TextStyle(
  color: Color(0xFFFE5D43),
  fontSize: 28,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.5,
  height: 1.05,
);

const TextStyle _kTileLead = TextStyle(
  color: Color(0xFFF1F1F1),
  fontSize: 15,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
  height: 1.1,
);

const TextStyle _kTileAsk = TextStyle(
  color: Color(0xFFF1F1F1),
  fontSize: 19,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
  height: 1.1,
);

/// The hero token on its own. Scales down rather than clipping, so a long
/// interval name ("Perfect Fifth") still fits beside the tile's controls.
class _TileHero extends StatelessWidget {
  const _TileHero(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: _kTileHero),
    );
  }
}

/// A small lead word followed by the hero token, e.g. "Find" + "C#".
///
/// One rich Text rather than a Row, so the two sizes sit on a shared baseline
/// for free, and one FittedBox around the lot so a long token scales the whole
/// line down instead of clipping it.
class _TilePrompt extends StatelessWidget {
  const _TilePrompt({required this.lead, required this.hero});
  final String lead;
  final String hero;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$lead  ', style: _kTileLead),
          TextSpan(text: hero, style: _kTileHero),
        ]),
        maxLines: 1,
      ),
    );
  }
}

class _CollapsedTile extends StatelessWidget {
  const _CollapsedTile({
    super.key,
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
    // Game type, not "… MODE" — so the user always sees what they're playing.
    final modeLabel = isChord
        ? (c.isChordLab
            ? _chordLabHeader(c)
            : c.isChordBuild
                ? 'BUILD THE CHORD'
                : 'NAME THE CHORD')
        : isInterval
            ? (c.isIntervalBuild ? 'BUILD THE INTERVAL' : 'NAME THE INTERVAL')
            : isReverse
                ? 'IDENTIFY THE NOTE'
                : 'FIND THE NOTE';
    final showAnswers =
        isReverse && isPlaying && c.reverseChoices.isNotEmpty;
    final showIntervalAnswers =
        c.isIntervalName && isPlaying && c.intervalChoicesList.isNotEmpty;
    final showChordAnswers =
        c.isChordName && isPlaying && c.chordChoicesList.isNotEmpty;
    final showChordBuildControls = c.isChordBuild && isPlaying;
    final showChordLabAnswers =
        c.isChordLabName && isPlaying && c.chordChoicesList.isNotEmpty;
    // Complete / Build rounds get a Clear control while collapsed; Remove has
    // nothing to clear.
    final showChordLabClear = c.isChordLab &&
        !c.isChordLabName &&
        isPlaying &&
        c.chordLabPrompt?.round != ChordLabRound.remove;
    final locked = c.reverseSelectedNote != null;
    final intervalLocked = c.intervalSelected != null;

    // Score + time as compact stat pills — legible at a glance and visually
    // separated from the prompt so the collapsed tile doesn't read as one
    // cramped block.
    Widget answerButton(String note) {
      final s = _answerStyle(note, c);
      final isWrongPick = c.reverseSelectedNote != null &&
          !c.reverseWasCorrect &&
          note == c.reverseSelectedNote;
      return _ShakeOnWrong(
        wrong: isWrongPick,
        child: GestureDetector(
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
          size: 18,
        ),
      ),
    );

    final expandBtn = JhgGlassChevron(onTap: onExpand, expanded: false);

    // Skip → draw a fresh question, no score change. Only while a round runs.
    final skipBtn = JhgIconChipButton(
      icon: Icons.skip_next_rounded,
      onTap: c.skipQuestion,
      size: 44,
      radius: 12,
      iconColor: Colors.white54,
      background: Colors.white.withValues(alpha: 0.04),
      borderColor: Colors.white.withValues(alpha: 0.16),
    );

    return JhgGlassTile.closed(
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
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // The prompt line. Whatever the player has to act on — a
                    // note, a chord symbol, an interval — is the hero and gets
                    // real size; the words around it stay small so they don't
                    // compete with it.
                    if (!isPlaying)
                      const Text(
                        'Tap play to start',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _kTileLead,
                      )
                    else if (isChord && c.isChordLab)
                      // Board rounds surface the target symbol; the name round
                      // asks for the name.
                      (c.isChordLabName
                          ? const Text('Which chord?',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _kTileAsk)
                          : _TileHero(c.chordLabPrompt?.target.symbol ?? '—'))
                    else if (isChord && c.isChordBuild)
                      _TilePrompt(
                          lead: 'Play', hero: c.chordPrompt?.symbol ?? '—')
                    else if (isChord)
                      const Text('Which chord?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _kTileAsk)
                    else if (isInterval && c.isIntervalBuild)
                      _TilePrompt(
                          lead: 'Play',
                          hero: c.intervalPrompt?.interval.name ?? '—')
                    else if (isInterval)
                      const Text('Which interval?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _kTileAsk)
                    else if (isReverse)
                      const Text('Which note is this?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _kTileAsk)
                    else
                      _TilePrompt(lead: 'Find', hero: c.highlightNode ?? '—'),                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Score + time now live in the bottom score bar; the header
              // stays a clean prompt + controls row.
              if (c.isStart) ...[
                skipBtn,
                const SizedBox(width: 7),
              ],
              playBtn,
              const SizedBox(width: 7),
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
          // Chord Lab NAME round: symbol grid stays usable while collapsed.
          if (showChordLabAnswers) ...[
            const SizedBox(height: 10),
            _ChordChoiceGrid(
              controller: c,
              locked: c.chordSelected != null,
              onPick: c.selectChordLabName,
            ),
          ],
          // Chord Lab Complete / Build rounds: a Clear control.
          if (showChordLabClear) ...[
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: c.clearChordLab,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.backspace_outlined,
                          color: Colors.white60, size: 15),
                      const SizedBox(width: 8),
                      Text('Clear',
                          style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Score bar — below the options, same in every mode.
          if (isPlaying) ...[
            const SizedBox(height: 12),
            _ScoreBar(controller: c, showTime: true),
          ],
        ],
      ),
    );
  }
}

// ── Answer-button colour helper (shared by tile + expanded panel) ─────────────

_BtnStyle _answerStyle(String note, HomeController c) {
  final selected = c.reverseSelectedNote;
  final neutral = _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.08),
    border: Colors.white.withValues(alpha: 0.12),
    text: Colors.white,
  );
  if (selected == null) return neutral;
  // Correct pick → reveal green and fade the rest as the round ends.
  if (c.reverseWasCorrect) {
    if (note == c.highlightNode) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.20),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.03),
      border: Colors.white.withValues(alpha: 0.05),
      text: Colors.white30,
    );
  }
  // Wrong pick → flash only the tapped button; leave the others tappable so
  // the user can keep guessing (we never reveal the correct answer).
  if (note == selected) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return neutral;
}

// ─── In-board Modes shifter ───────────────────────────────────────────────────
// The dictionaries / drills canvas switcher, matched in shape: a coral "MODES"
// eyebrow over the current mode name in white with a chevron, sitting top-left
// over the neck. Tapping opens a frosted picker; choosing a mode swaps the whole
// game in place (via the controller's switchTo* methods), keeping the last-used
// game type / difficulty for Intervals and Chords.
//
// Only shown for a Quick start session — see PortraitBoard.
class _BoardModeSwitcher extends StatelessWidget {
  const _BoardModeSwitcher({required this.controller});
  final HomeController controller;

  static const _kModes = <(String, String, IconData)>[
    ('Notes', 'Find and name notes on the neck', Icons.music_note_rounded),
    ('Intervals', 'Name and build every interval', Icons.straighten_rounded),
    ('Chords', 'Name and build chord shapes', Icons.grid_goldenratio_rounded),
  ];

  // Chord Lab is a specialised chord flow; it still reads as "Chords" here.
  int get _activeIndex => controller.isIntervalMode
      ? 1
      : controller.isChordMode
          ? 2
          : 0;

  void _select(int i) {
    if (i == _activeIndex) return;
    switch (i) {
      case 0:
        controller.switchToFindMode();
        break;
      case 1:
        controller.switchToIntervalMode();
        break;
      case 2:
        controller.switchToChordMode();
        break;
    }
  }

  void _openPicker(BuildContext context) {
    final active = _activeIndex;
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: LucideIcons.layoutGrid,
        title: 'Switch mode',
        description: 'Switching starts a fresh round. Whatever you set up '
            'for each mode is kept.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _kModes.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _ModeOption(
                label: _kModes[i].$1,
                subtitle: _kModes[i].$2,
                icon: _kModes[i].$3,
                isActive: i == active,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _select(i);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeName = _kModes[_activeIndex].$1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPicker(context),
      // Boxless, matching the dictionaries canvas switcher: a small coral
      // eyebrow above the current mode name, left-aligned, with a coral
      // chevron dot signalling the tap.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'MODES',
            style: TextStyle(
              color: JHGColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                modeName,
                style: const TextStyle(
                  color: Color(0xFFF1F1F1),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: JHGColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.chevronsUpDown,
                  color: JHGColors.primary,
                  size: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One row in the Modes picker — icon chip, name + blurb, and a coral tick on
/// the mode that's already running.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? JHGColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive
                ? JHGColors.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isActive ? JHGColors.primary : Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: isActive ? JHGColors.primary : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(Icons.check_rounded,
                  color: JHGColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}


// ─── Shared control row ───────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  final HomeController controller;
  const _ControlRow({required this.controller});

  IconData _resolveTimerIcon(String mode) {
    switch (mode) {
      case 'countdown':   return LucideIcons.clock;
      case 'leaderboard': return LucideIcons.trophy;
      default:            return LucideIcons.timer;
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
              // Tapping while running pauses (Reset is the separate control),
              // so show a pause glyph — a stop icon promised something else.
              c.isStart ? Icons.pause_rounded : Icons.play_arrow_rounded,
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


// ─── Shared bottom score bar ──────────────────────────────────────────────────
// One clean, full-width strip that lives at the BOTTOM of the tile (below the
// answer options), so the score reads the same in every mode and never crowds
// the prompt. "Score:" is white; the number is coral. On the collapsed tile it
// also carries the running time on the right.
class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.controller, this.showTime = false});
  final HomeController controller;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            'Score:',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            c.score.toString(),
            style: GoogleFonts.poppins(
              color: JHGColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const Spacer(),
          if (showTime) ...[
            Icon(LucideIcons.timer,
                size: 14, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(
              c.formatTime(c.secondsRemaining.value),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Manual save — snapshot the session so it can be resumed later.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              if (!c.sessionActive) {
                showCustomToast(
                  context: context,
                  message: 'Start a round first, then you can save it.',
                  isError: true,
                );
                return;
              }
              final result = await showSaveSessionDialog(
                context,
                defaultName: c.defaultSessionName(),
              );
              if (result == null) return; // backed out
              final saved = await c.saveCurrentSession(
                customName: result.name,
                folderId: result.folderId,
              );
              if (!context.mounted) return;
              showCustomToast(
                context: context,
                message: saved
                    ? 'Saved. Find it under Saved in the bar below.'
                    : 'Could not save that one. Give it another go.',
                isError: !saved,
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
                border:
                    Border.all(color: JHGColors.primary.withValues(alpha: 0.35)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.save,
                    size: 14, color: JHGColors.primary),
                const SizedBox(width: 5),
                Text(
                  'Save',
                  style: GoogleFonts.inter(
                    color: JHGColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ),
        ],
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
        if (controller.identifyShowPositionHint) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Text(controller.reversePositionHint,
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: controller.reverseChoices.map((note) {
            final s = _answerStyle(note, controller);
            final isWrongPick = controller.reverseSelectedNote != null &&
                !controller.reverseWasCorrect &&
                note == controller.reverseSelectedNote;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _ShakeOnWrong(
                  wrong: isWrongPick,
                  child: GestureDetector(
                    onTap: locked
                        ? null
                        : () => controller.selectReverseAnswer(note),
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
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Horizontal shake played once when [wrong] flips true (mirrors the Ear
// Training answer feedback). Paired with the coral colour flash + buzzer SFX.
class _ShakeOnWrong extends StatefulWidget {
  const _ShakeOnWrong({required this.wrong, required this.child});
  final bool wrong;
  final Widget child;

  @override
  State<_ShakeOnWrong> createState() => _ShakeOnWrongState();
}

class _ShakeOnWrongState extends State<_ShakeOnWrong>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    if (widget.wrong) _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _ShakeOnWrong old) {
    super.didUpdateWidget(old);
    if (widget.wrong && !old.wrong) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(sin(4 * pi * _ctrl.value) * 5, 0),
          child: child,
        ),
        child: widget.child,
      );
}

class _BtnStyle {
  const _BtnStyle({required this.bg, required this.border, required this.text});
  final Color bg;
  final Color border;
  final Color text;
}

// ─── Interval mode ───────────────────────────────────────────────────────────

// Expanded-panel version: the 2×2 interval-name grid (score now lives in the
// shared bottom score bar).
class _IntervalChoicePanel extends StatelessWidget {
  const _IntervalChoicePanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.intervalChoicesList.isEmpty) return const SizedBox.shrink();
    return _IntervalChoiceGrid(controller: c, locked: c.intervalSelected != null);
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
      final isWrongPick = c.intervalSelected != null &&
          !c.intervalWasCorrect &&
          choice.semitones == c.intervalSelected!.semitones;
      return _ShakeOnWrong(
        wrong: isWrongPick,
        child: GestureDetector(
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
                    color: Color(0xFFF1F1F1), fontWeight: FontWeight.w700),
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
  final neutral = _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.08),
    border: Colors.white.withValues(alpha: 0.12),
    text: Colors.white,
  );
  if (selected == null || correct == null) return neutral;
  // Correct pick → reveal green and fade the rest as the round ends.
  if (c.intervalWasCorrect) {
    if (choice.semitones == correct.semitones) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.20),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.03),
      border: Colors.white.withValues(alpha: 0.05),
      text: Colors.white30,
    );
  }
  // Wrong pick → flash only the tapped choice; leave the others tappable so
  // the user can keep guessing (we never reveal the correct answer).
  if (choice.semitones == selected.semitones) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return neutral;
}

// ─── Chord mode ──────────────────────────────────────────────────────────────

// Chord-symbol button colours: neutral until an answer is locked, then green
// for the correct symbol and coral for a wrong pick.
_BtnStyle _chordSymbolStyle(String symbol, HomeController c) {
  final selected = c.chordSelected;
  // Chord Lab name rounds keep their target on chordLabPrompt, not chordPrompt.
  final correct = c.chordPrompt?.symbol ?? c.chordLabPrompt?.target.symbol;
  final neutral = _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.08),
    border: Colors.white.withValues(alpha: 0.12),
    text: Colors.white,
  );
  if (selected == null || correct == null) return neutral;
  // Correct pick → reveal green and fade the rest as the round ends.
  if (c.chordWasCorrect) {
    if (symbol == correct) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.20),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.03),
      border: Colors.white.withValues(alpha: 0.05),
      text: Colors.white30,
    );
  }
  // Wrong pick → flash only the tapped symbol; leave the others tappable so
  // the user can keep guessing (we never reveal the correct answer).
  if (symbol == selected) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return neutral;
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
    return _ChordChoiceGrid(controller: c, locked: c.chordSelected != null);
  }
}

// ── Chord Lab ────────────────────────────────────────────────────────────────

/// Header eyebrow for the current Chord Lab round.
String _chordLabHeader(HomeController c) {
  final p = c.chordLabPrompt;
  if (p == null) return 'CHORD LAB';
  switch (p.round) {
    case ChordLabRound.name:
      return 'NAME THIS CHORD';
    case ChordLabRound.complete:
      return 'COMPLETE THE CHORD';
    case ChordLabRound.remove:
      return 'REMOVE THE EXTRA NOTE';
    case ChordLabRound.build:
      return 'BUILD THIS CHORD';
  }
}

String _chordLabHint(ChordLabRound round) {
  switch (round) {
    case ChordLabRound.name:
      return 'Pick its name.';
    case ChordLabRound.complete:
      return 'Tap the missing note(s).';
    case ChordLabRound.remove:
      return "Tap the note that doesn't belong.";
    case ChordLabRound.build:
      return 'Build it inside the band.';
  }
}

/// Panel body for a Chord Lab round: score (+ target symbol on board rounds), a
/// one-line task hint, and either the name grid or a Clear control.
class _ChordLabPanel extends StatelessWidget {
  const _ChordLabPanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p = c.chordLabPrompt;
    if (p == null) return _chordLoadingHint(c);
    final isName = p.round == ChordLabRound.name;
    final showClear = p.round == ChordLabRound.complete ||
        p.round == ChordLabRound.build;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isName) ...[
          Center(child: _labSymbolChip(p.target.symbol)),
          const SizedBox(height: 10),
        ],
        Text(
          _chordLabHint(p.round),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        if (isName)
          _ChordChoiceGrid(
            controller: c,
            locked: c.chordSelected != null,
            onPick: c.selectChordLabName,
          )
        else if (showClear)
          _labClearButton(c),
      ],
    );
  }

  Widget _labSymbolChip(String symbol) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: JHGColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JHGColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          symbol,
          style: GoogleFonts.poppins(
            color: JHGColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _labClearButton(HomeController c) => GestureDetector(
        onTap: c.clearChordLab,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.backspace_outlined,
                  color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Text('Clear',
                  style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// 2×2 grid of chord-symbol choices — shared by the expanded panel and the
// collapsed tile.
class _ChordChoiceGrid extends StatelessWidget {
  const _ChordChoiceGrid({
    required this.controller,
    required this.locked,
    this.onPick,
  });
  final HomeController controller;
  final bool locked;

  /// Defaults to the Name-mode handler; Chord Lab passes selectChordLabName.
  final void Function(String symbol)? onPick;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final choices = c.chordChoicesList;
    if (choices.isEmpty) return const SizedBox.shrink();
    final pick = onPick ?? c.selectChordAnswer;

    Widget button(String symbol) {
      final s = _chordSymbolStyle(symbol, c);
      final isWrongPick = c.chordSelected != null &&
          !c.chordWasCorrect &&
          symbol == c.chordSelected;
      return _ShakeOnWrong(
        wrong: isWrongPick,
        child: GestureDetector(
          onTap: locked ? null : () => pick(symbol),
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
          ],
        ),
        const SizedBox(height: 8),
        Text(
          shape.qualityName,
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
    final revealed = c.chordBuildReveal != null;

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

    // After a reveal the shape is shown with note names on the neck; the Reveal
    // control turns into a solid coral "Next" so the user moves on when ready
    // (the round no longer skips itself).
    if (revealed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: c.nextBuildChord,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                color: JHGColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: JHGColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Next',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 17),
              ]),
            ),
          ),
        ],
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

// Placeholder copy for the chord panel: distinguishes the (rare) parse wait
// from the idle "not started yet" state so an idle board never looks stuck.
Widget _chordLoadingHint(HomeController c) {
  final String hint;
  if (c.chordCatalogLoading) {
    hint = 'Loading chords…';
  } else if (!c.isStart) {
    hint = 'Press play to start';
  } else {
    hint = 'Getting the next chord…';
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      hint,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
