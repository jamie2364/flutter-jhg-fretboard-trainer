import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/home/widgets/web_guitar_board.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:fretboard/views/widgets/count_timer_widget.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette (mirrors portrait_board.dart) ─────────────────────────────────────
const _kNavBg = Color(0xFF0F0F0F);
const _kPanelBg = Color(0xFF1E1D1D);

// ── Web-specific sizing ───────────────────────────────────────────────────────
const double _webFretboardWidth = 191.0;
const double _webFretNumberGutter = 31.0;

// ─────────────────────────────────────────────────────────────────────────────
// WebBoard — mirrors PortraitBoard exactly, uses WebPortraitGuitarBoard.
// Timer is always visible at the top.
// The fretboard fills all remaining space.
// The control panel floats OVER the fretboard as a blurred card.
// ─────────────────────────────────────────────────────────────────────────────

class WebBoard extends StatefulWidget {
  const WebBoard({super.key, required this.controller});
  final HomeController controller;

  @override
  State<WebBoard> createState() => _WebBoardState();
}

class _WebBoardState extends State<WebBoard> {
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
        final gameRunning = c.isStart || c.isPaused;

        // Auto-collapse when game starts so the fretboard fills full height
        // and the collapsed tile (with the note/answers) appears on the left.
        if (!_prevGameRunning && gameRunning && !_panelCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_panelCollapsed) _setCollapsed(true);
          });
        }
        // Auto-expand when game ends so the mode chip reappears.
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
              // ── Timer — always at top ──────────────────────────────────────
              KeyedSubtree(key: tourKeyTimer, child: const CountTimerWidget()),

              // ── Fretboard fills full Expanded height at all times ──────────
              // Both the expanded panel and the collapsed tile are Positioned
              // overlays so the guitar board always gets the full space.
              Expanded(
                key: tourKeyFretboard,
                child: Stack(
                  children: [
                    // Fretboard + collapsed tile in a centred Row so the
                    // tile appears to the left of the neck without overlapping it.
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final boardHeight = (constraints.maxHeight - 42)
                              .clamp(260.0, 640.0)
                              .toDouble();
                          return Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Left zone: collapsed tile or symmetry spacer
                                SizedBox(
                                  width: 112,
                                  child: _panelCollapsed
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: Align(
                                            alignment: Alignment.bottomLeft,
                                            child: SizedBox(
                                              width: 106,
                                              child: _CollapsedTile(
                                                controller: c,
                                                isReverse: isReverse,
                                                onExpand: () =>
                                                    _setCollapsed(false),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                // Fretboard
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: _webFretboardWidth +
                                          _webFretNumberGutter,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _WebStringLabels(
                                            width: _webFretboardWidth),
                                      ),
                                    ),
                                    IgnorePointer(
                                      ignoring: !c.isStart,
                                      child: WebPortraitGuitarBoard(
                                        boardWidth: _webFretboardWidth,
                                        boardHeight: boardHeight,
                                      ),
                                    ),
                                  ],
                                ),
                                // Right spacer mirrors left for visual centering
                                const SizedBox(width: 112),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Expanded floating card
                    if (!_panelCollapsed)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: _ExpandedPanel(
                                controller: c,
                                isReverse: isReverse,
                                onCollapse: () => _setCollapsed(true),
                                onModeTap: () => _showModeSwitcher(context, c),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Nav bar ────────────────────────────────────────────────────
              AppNavBar(
                // The web board is the training screen, so Practice is the
                // active tab — marking it Home made the Home tab a no-op
                // (the bar ignores taps on the tab already showing).
                activeTab: AppTab.train,
                controller: c,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mode selector bottom sheet ───────────────────────────────────────────────

  void _showModeSwitcher(BuildContext context, HomeController controller) {
    final isReverse = controller.currentGameMode.value == 'reverse';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kNavBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('SELECT MODE',
                style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
            const SizedBox(height: 16),
            _ModeTile(
              icon: Icons.music_note_rounded,
              title: 'Find Note',
              subtitle: 'A note is shown. Tap it on the fretboard.',
              isSelected: !isReverse,
              onTap: () {
                controller.switchToFindMode();
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            _ModeTile(
              icon: Icons.quiz_rounded,
              title: 'Identify',
              subtitle: 'A fret lights up. Choose the correct note.',
              isSelected: isReverse,
              onTap: () {
                controller.switchToIdentifyMode();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── String labels above the fretboard ───────────────────────────────────────

class _WebStringLabels extends StatelessWidget {
  const _WebStringLabels({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    const chipSize = 22.0;
    final centers = WebPortraitGuitarBoard.stringCenters(width);

    return SizedBox(
      width: width,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(AppStrings.guitarStrings.length, (index) {
          return Positioned(
            left: centers[index] - chipSize / 2,
            top: 7,
            child: Container(
              height: chipSize,
              width: chipSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.24),
                shape: BoxShape.circle,
                border: Border.all(
                  color: JHGColors.primary.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -0.4),
                  child: Text(
                    AppStrings.guitarStrings[index],
                    textAlign: TextAlign.center,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Expanded floating card ───────────────────────────────────────────────────
// Blurred glass card that overlays the bottom of the fretboard.

class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({
    required this.controller,
    required this.isReverse,
    required this.onCollapse,
    required this.onModeTap,
  });

  final HomeController controller;
  final bool isReverse;
  final VoidCallback onCollapse;
  final VoidCallback onModeTap;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return JhgGlassTile.open(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row: label + collapse arrow ────────────────────────
          Row(
            children: [
              Text(
                isReverse ? 'IDENTIFY THE NOTE' : 'FIND THE NOTE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              JhgIconChipButton.compact(
                icon: Icons.chevron_left_rounded,
                onTap: onCollapse,
                iconColor: Colors.white54,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Content: depends on game state ─────────────────────────────

          // Idle: mode chip + hint
          if (!c.isStart && !c.isPaused) ...[
            GestureDetector(
              onTap: onModeTap,
              child: Container(
                key: tourKeyModeChip,
                height: 44,
                decoration: BoxDecoration(
                  color: _kPanelBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isReverse
                          ? Icons.quiz_rounded
                          : Icons.music_note_rounded,
                      size: 15,
                      color: JHGColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isReverse ? 'IDENTIFY THE NOTE' : 'FIND THE NOTE',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Colors.white38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isReverse
                  ? 'A fret lights up. Pick the correct note name.'
                  : 'Find the note shown here on the fretboard.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ),
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
                          color: JHGColors.primary,
                          fontSize: 28,
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
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1)),
                    const SizedBox(width: 8),
                    Text(c.score.toString(),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── Control row ───────────────────────────────────────────────
          _ControlRow(controller: c),
        ],
      ),
    );
  }
}

// ─── Collapsed left-side tile ─────────────────────────────────────────────────

class _CollapsedTile extends StatelessWidget {
  const _CollapsedTile({
    required this.controller,
    required this.isReverse,
    required this.onExpand,
  });

  final HomeController controller;
  final bool isReverse;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isPlaying = c.isStart || c.isPaused;
    final showNote = isPlaying && !isReverse;
    final showAnswers = isPlaying && isReverse && c.reverseChoices.isNotEmpty;
    final locked = c.reverseSelectedNote != null;

    // Expand arrow — shared
    final expandBtn = Padding(
      padding: const EdgeInsets.all(4),
      child: JhgIconChipButton.compact(
        icon: Icons.chevron_right_rounded,
        onTap: onExpand,
      ),
    );

    // Play / Stop circle
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: JHGColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: JHGColors.primary.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          c.isStart ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );

    return JhgGlassTile.closed(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── IDENTIFY MODE ──────────────────────────────────────────────
          if (isReverse) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPlaying ? 'Which?' : 'Identify',
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFFE5D43),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      height: 1.0,
                    ),
                  ),
                ),
                expandBtn,
              ],
            ),
            const SizedBox(height: 12),
            if (showAnswers) ...[
              ...c.reverseChoices.map((note) {
                final s = _answerStyle(note, c);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: GestureDetector(
                    onTap:
                        locked ? null : () => c.selectReverseAnswer(note),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      height: 38,
                      decoration: BoxDecoration(
                        color: s.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: s.border, width: 1.4),
                      ),
                      child: Center(
                        child: Text(note,
                            style: TextStyle(
                                color: s.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2)),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
            ],
            Center(child: playBtn),
          ]

          // ── FIND NOTE MODE ─────────────────────────────────────────────
          else ...[
            Align(
              alignment: Alignment.topRight,
              child: expandBtn,
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: showNote
                    ? const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5)
                    : EdgeInsets.zero,
                decoration: showNote
                    ? BoxDecoration(
                        color: JHGColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                JHGColors.primary.withValues(alpha: 0.30)),
                      )
                    : null,
                child: Text(
                  showNote ? (c.highlightNode ?? '—') : 'Find Note',
                  maxLines: 1,
                  style: TextStyle(
                    color: showNote
                        ? JHGColors.primary
                        : const Color(0xFFFE5D43),
                    fontSize: showNote ? 26 : 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: showNote ? -0.5 : 0.1,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: playBtn),
            if (showNote) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SCORE',
                      style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(width: 5),
                  Text(c.score.toString(),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Answer-button colour helper ───────────────────────────────────────────────

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

// ─── Shared control row ───────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  final HomeController controller;
  const _ControlRow({required this.controller});

  IconData _resolveTimerIcon(String mode) {
    switch (mode) {
      case 'countdown':
        return Icons.schedule_rounded;
      case 'leaderboard':
        return Icons.emoji_events_rounded;
      default:
        return Icons.timer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isReverse = c.currentGameMode.value == 'reverse';
    final mode = c.currentGameMode.value;
    final disabled = c.isStart || c.isPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Timer-mode cycle
        GestureDetector(
          onTap: disabled ? null : c.cycleGameMode,
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              _resolveTimerIcon(isReverse ? c.timerMode.value : mode),
              color: disabled ? Colors.white24 : Colors.white60,
              size: 22,
            ),
          ),
        ),

        // Play / Stop / Resume
        GestureDetector(
          onTap: c.isStart
              ? c.pauseGame
              : c.isPaused
                  ? c.resumeGame
                  : () {
                      c.startTimer();
                      c.startTheGame();
                    },
          child: AnimatedContainer(
            key: tourKeyPlayButton,
            duration: const Duration(milliseconds: 200),
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: JHGColors.primary,
              boxShadow: [
                BoxShadow(
                  color: JHGColors.primary
                      .withValues(alpha: c.isStart ? 0.50 : 0.22),
                  blurRadius: c.isStart ? 28 : 14,
                ),
              ],
            ),
            child: Icon(
              c.isStart ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        // Reset
        GestureDetector(
          onTap: () => c.resetGame(true),
          child: Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? JHGColors.primary.withValues(alpha: 0.12)
              : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? JHGColors.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          color: isSelected ? JHGColors.primary : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.1)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? JHGColors.primary.withValues(alpha: 0.16)
                    : const Color(0xFF2E2E2E),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: JHGColors.primary.withValues(alpha: 0.35))
                    : null,
              ),
              child: Icon(icon,
                  color: isSelected ? JHGColors.primary : Colors.white54,
                  size: 18),
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
                Text('SCORE',
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(width: 6),
                Text(controller.score.toString(),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            if (controller.identifyShowPositionHint)
              Text(controller.reversePositionHint,
                  style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
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
                      child: Text(note,
                          style: GoogleFonts.poppins(
                              color: s.text,
                              fontSize: 16,
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
