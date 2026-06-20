import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/count_timer_widget.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavBg       = Color(0xFF1C1B1B);
const _kPanelBg     = Color(0xFF1E1D1D);
const _kPanelCard   = Color(0xFF1A1A1A);   // dictionaries card bg
const _kNavActive   = Color(0xFFFF5F40);
const _kNavInactive = Color(0xFF7A7A7A);

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
        final gameRunning = c.isStart || c.isPaused;

        // Auto-expand when game ends so mode chip reappears.
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

              // ── Timer — always at top ────────────────────────────────────
              KeyedSubtree(key: tourKeyTimer, child: CountTimerWidget()),

              // ── Fretboard fills full Expanded height at all times ────────
              // Both the expanded panel and the collapsed tile are Positioned
              // overlays so the GuitarBoard always gets the full space.
              Expanded(
                key: tourKeyFretboard,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 45.8),
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
                            onCollapse: () => _setCollapsed(true),
                            onModeTap: () => _showModeSwitcher(context, c),
                          ),
                        ),
                      ),

                    // Collapsed tile — tiny bottom-left corner card
                    if (_panelCollapsed)
                      Positioned(
                        bottom: 10,
                        left: 12,
                        width: 106,
                        child: _CollapsedTile(
                          controller: c,
                          isReverse: isReverse,
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

  // ── Mode selector bottom sheet ─────────────────────────────────────────────

  void _showModeSwitcher(BuildContext context, HomeController controller) {
    final isReverse = controller.currentGameMode.value == 'reverse';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('SELECT MODE',
                style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.4)),
            const SizedBox(height: 16),
            _ModeTile(
              icon: Icons.music_note_rounded,
              title: 'Find Note',
              subtitle: 'A note is shown — tap it on the fretboard',
              isSelected: !isReverse,
              onTap: () { controller.switchToFindMode(); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 12),
            _ModeTile(
              icon: Icons.quiz_rounded,
              title: 'Identify',
              subtitle: 'A fret lights up — choose the correct note',
              isSelected: isReverse,
              onTap: () { controller.switchToIdentifyMode(); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
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
                        ? (isReverse ? 'IDENTIFY MODE' : 'FIND NOTE MODE')
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
                      child: const Icon(LucideIcons.chevronLeft300,
                          color: Colors.white54, size: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Content: depends on game state ───────────────────────────

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
                          size: 15, color: JHGColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isReverse ? 'IDENTIFY MODE' : 'FIND NOTE MODE',
                          style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 13,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
                      ? 'A fret lights up — pick the correct note name'
                      : 'Find the note shown here on the fretboard',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 13,
                    fontWeight: FontWeight.w500, height: 1.4),
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
    final expandBtn = GestureDetector(
      onTap: onExpand,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Icon(LucideIcons.chevronRight300,
              color: Colors.white, size: 14),
        ),
      ),
    );

    // Play / Stop circle — same orange for both modes
    final playBtn = GestureDetector(
      onTap: c.isStart
          ? c.pauseGame
          : c.isPaused
              ? c.resumeGame
              : () { c.startTimer(); c.startTheGame(); },
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: JHGColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: JHGColors.primary.withValues(alpha: 0.45),
              blurRadius: 12, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          c.isStart ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white, size: 26,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _kPanelCard.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── IDENTIFY MODE ───────────────────────────────────────────
              if (isReverse) ...[
                // Header: label + expand
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPlaying ? 'Which?' : 'Identify',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFFFFB4A5),
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 0.1, height: 1.0,
                        ),
                      ),
                    ),
                    expandBtn,
                  ],
                ),
                const SizedBox(height: 12),
                // Single-column answer buttons (only when playing)
                if (showAnswers) ...[
                  ...c.reverseChoices.map((note) {
                    final s = _answerStyle(note, c);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: GestureDetector(
                        onTap: locked ? null : () => c.selectReverseAnswer(note),
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
                                  color: s.text, fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2)),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],
                // Play / Stop circle (centered)
                Center(child: playBtn),
              ]

              // ── FIND NOTE MODE ──────────────────────────────────────────
              else ...[
                // Expand button pinned to top-right
                Align(
                  alignment: Alignment.topRight,
                  child: expandBtn,
                ),
                const SizedBox(height: 14),
                // Note name — big, centered, with tinted background when playing
                Center(
                  child: Container(
                    padding: showNote
                        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 5)
                        : EdgeInsets.zero,
                    decoration: showNote
                        ? BoxDecoration(
                            color: JHGColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: JHGColors.primary.withValues(alpha: 0.30)),
                          )
                        : null,
                    child: Text(
                      showNote ? (c.highlightNode ?? '—') : 'Find Note',
                      maxLines: 1,
                      style: TextStyle(
                        color: showNote ? JHGColors.primary : const Color(0xFFFFB4A5),
                        fontSize: showNote ? 26 : 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: showNote ? -0.5 : 0.1,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Play / Stop circle (centered)
                Center(child: playBtn),
                // Score — centered below circle
                if (showNote) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SCORE',
                          style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      const SizedBox(width: 5),
                      Text(c.score.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
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
            height: 56, width: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Icon(
              _resolveTimerIcon(isReverse ? c.timerMode.value : mode),
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

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon, required this.title,
    required this.subtitle, required this.isSelected, required this.onTap,
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? JHGColors.primary.withValues(alpha: 0.12)
              : const Color(0xFF252525),
          borderRadius: BorderRadius.circular(18),
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
                        fontSize: 22, fontWeight: FontWeight.w700,
                        letterSpacing: -0.2, height: 1.1)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 13, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? JHGColors.primary.withValues(alpha: 0.16)
                    : const Color(0xFF2E2E2E),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: JHGColors.primary.withValues(alpha: 0.35))
                    : null,
              ),
              child: Icon(icon,
                  color: isSelected ? JHGColors.primary : Colors.white54,
                  size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom nav bar ───────────────────────────────────────────────────────────

class _FretboardNavBar extends StatelessWidget {
  const _FretboardNavBar({
    super.key, required this.safeBottom, required this.controller,
  });
  final double safeBottom;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final canOpenSettings = controller.currentGameMode.value != 'leaderboard';
    return Container(
      height: 56 + safeBottom,
      decoration: const BoxDecoration(
        color: _kNavBg,
        border: Border(top: BorderSide(color: Color(0xFF2E2E2E))),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: Row(
          children: [
            _NavItem(icon: Icons.music_note_rounded, isActive: true),
            _NavItem(
              icon: LucideIcons.trophy300,
              onTap: () {
                Get.to(() => LeadershipScreen(),
                    transition: Transition.noTransition,
                    duration: Duration.zero);
                if (isFreePlan) controller.interstitialAds?.showInterstitial();
              },
            ),
            _NavItem(
              key: tourKeyHeatmapNav,
              icon: Icons.insights_rounded,
              onTap: () => Get.to(
                () => const HeatmapScreen(),
                transition: Transition.noTransition,
                duration: Duration.zero,
              ),
            ),
            _NavItem(
              icon: LucideIcons.settings300,
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
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key, required this.icon,
    this.onTap, this.isActive = false, this.disabled = false,
  });
  final IconData icon;
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
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? _kNavActive.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
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
