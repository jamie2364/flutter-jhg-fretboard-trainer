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
import 'package:fretboard/views/screens/mode_select_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/count_timer_widget.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kNavBg       = Color(0xFF0F0F0F);
const _kPanelCard   = Color(0xFF1A1A1A);   // dictionaries card bg
const _kNavActive   = Color(0xFFFE5D43);
const _kNavInactive = Color(0xFF9E9A98);

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

        // Auto-collapse when the game starts (more fretboard); auto-expand
        // again when it ends.
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

              // ── Top: mode switcher (left) — replaces the big top timer ────
              _ModeSwitcherBar(controller: c, isReverse: isReverse),

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
                          left: 45.8,
                          // Reserve room for the collapsed bar so the board
                          // doesn't stretch underneath it (matches dictionaries).
                          // The bar is taller in identify mode (answer buttons).
                          bottom: _panelCollapsed
                              ? (isReverse && (c.isStart || c.isPaused)
                                  ? 148
                                  : 84)
                              : 0,
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

// ─── Top-left mode switcher (matches dictionaries / drills) ───────────────────
// Tapping toggles between Find Note and Identify.
class _ModeSwitcherBar extends StatelessWidget {
  const _ModeSwitcherBar({required this.controller, required this.isReverse});

  final HomeController controller;
  final bool isReverse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Opens the mode-select screen (matches dictionaries).
            onTap: () =>
                Get.to(() => const ModeSelectScreen(fromSwitcher: true)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isReverse ? 'Identify' : 'Find Note',
                      style: const TextStyle(
                        color: Color(0xFFFE5D43),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.chevronDown300,
                      color: Color(0xFFFE5D43),
                      size: 16,
                    ),
                  ],
                ),
                Text(
                  'TAP TO SWITCH MODE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
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
  });

  final HomeController controller;
  final bool isReverse;
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

              // Idle: hint only (mode is chosen on the startup screen)
              if (!c.isStart && !c.isPaused) ...[
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

// ─── Collapsed bar — full-width, below the fretboard (matches drills/dict) ─────

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
    final modeLabel = isReverse ? 'IDENTIFY MODE' : 'FIND NOTE MODE';
    final showAnswers =
        isReverse && isPlaying && c.reverseChoices.isNotEmpty;
    final locked = c.reverseSelectedNote != null;

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

class _FretboardNavBar extends StatelessWidget {
  const _FretboardNavBar({
    super.key, required this.safeBottom, required this.controller,
  });
  final double safeBottom;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    // Mid-session, every tab except Home is locked so the running game can't be
    // abandoned. Settings is additionally locked in leaderboard mode.
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
                _NavItem(
                  icon: LucideIcons.home300,
                  label: 'Home',
                  isActive: true,
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
