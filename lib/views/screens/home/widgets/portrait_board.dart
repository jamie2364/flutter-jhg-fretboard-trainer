import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/count_timer_widget.dart';

// ── Palette — mirrors DrillsNavBar ───────────────────────────────────────────
const _kNavBg       = Color(0xFF1C1B1B);
const _kPanelBg     = Color(0xFF1E1D1D);
const _kNavActive   = Color(0xFFFF5F40); // == JHGColors.primary
const _kNavInactive = Color(0xFF7A7A7A);

class PortraitBoard extends StatelessWidget {
  const PortraitBoard({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isReverse   = controller.currentGameMode.value == 'reverse';
    final mode        = controller.currentGameMode.value;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ─── GUITAR BOARD ─────────────────────────────────────────────
          // No IgnorePointer here — scroll gestures must always reach
          // the SingleChildScrollView inside GuitarBoard. Tap-blocking
          // is handled inside GuitarBoard on the fret-press grid only.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 45.8),
              child: const GuitarBoard(isPortrait: true),
            ),
          ),

          // Gap between fretboard and timer
          const SizedBox(height: 6),
          CountTimerWidget(),
          const SizedBox(height: 8),

          // ─── BOTTOM PANEL ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _kNavBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Mode chip — only visible when idle ────────────────
                if (!controller.isStart && !controller.isPaused) ...[
                  GestureDetector(
                    onTap: () => _showModeSwitcher(context, controller),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kPanelBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isReverse
                                ? Icons.quiz_rounded
                                : Icons.music_note_rounded,
                            size: 14,
                            color: JHGColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isReverse ? 'IDENTIFY MODE' : 'FIND NOTE MODE',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Content area ──────────────────────────────────────
                if (!controller.isStart && !controller.isPaused) ...[
                  Text(
                    isReverse
                        ? 'A fret lights up — pick the correct note name'
                        : 'Find the note shown here on the fretboard',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (isReverse) ...[
                  _ReverseChoicePanel(controller: controller),
                  const SizedBox(height: 14),
                ] else ...[
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
                            color: JHGColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          controller.highlightNode ?? '',
                          style: GoogleFonts.poppins(
                            color: JHGColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('SCORE',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                )),
                            const SizedBox(width: 8),
                            Text(controller.score.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // ── Control row ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Timer-mode cycle — now always visible in both modes
                    GestureDetector(
                      onTap: controller.isStart || controller.isPaused
                          ? null
                          : controller.cycleGameMode,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          _resolveTimerIcon(isReverse
                              ? controller.timerMode.value
                              : mode),
                          color: controller.isStart || controller.isPaused
                              ? Colors.white24
                              : Colors.white60,
                          size: 24,
                        ),
                      ),
                    ),

                    // Play / Pause / Stop
                    GestureDetector(
                      onTap: controller.isStart
                          ? controller.pauseGame
                          : controller.isPaused
                              ? controller.resumeGame
                              : () {
                                  controller.startTimer();
                                  controller.startTheGame();
                                },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 78,
                        width: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: JHGColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: JHGColors.primary.withValues(
                                alpha: controller.isStart ? 0.45 : 0.18,
                              ),
                              blurRadius: controller.isStart ? 28 : 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          controller.isStart
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

                    // Reset
                    GestureDetector(
                      onTap: () => controller.resetGame(true),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white60,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),

          // ─── BOTTOM NAV BAR ───────────────────────────────────────────
          _FretboardNavBar(
            safeBottom: bottomInset,
            controller: controller,
          ),
        ],
      ),
    );
  }

  IconData _resolveTimerIcon(String mode) {
    switch (mode) {
      case 'countdown':   return LucideIcons.clock300;
      case 'leaderboard': return LucideIcons.trophy300;
      default:            return LucideIcons.timer300;
    }
  }

  // ── Mode switcher bottom sheet ─────────────────────────────────────────────
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
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SELECT MODE',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // FIND NOTE card
            _ModeTile(
              icon: Icons.music_note_rounded,
              title: 'Find Note',
              subtitle: 'A note is shown — tap it on the fretboard',
              isSelected: !isReverse,
              onTap: () {
                controller.switchToFindMode();
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),

            // IDENTIFY card
            _ModeTile(
              icon: Icons.quiz_rounded,
              title: 'Identify',
              subtitle: 'A fret lights up — choose the correct note',
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

// ─── MODE TILE (for bottom sheet) ────────────────────────────────────────────

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
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isSelected ? JHGColors.primary : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
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
              child: Icon(
                icon,
                color: isSelected ? JHGColors.primary : Colors.white54,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM NAV BAR ──────────────────────────────────────────────────────────

class _FretboardNavBar extends StatelessWidget {
  const _FretboardNavBar({
    required this.safeBottom,
    required this.controller,
  });

  final double safeBottom;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final canOpenSettings =
        controller.currentGameMode.value != 'leaderboard';

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
                    transition: Transition.leftToRight);
                if (isFreePlan) {
                  controller.interstitialAds?.showInterstitial();
                }
              },
            ),
            _NavItem(
              icon: Icons.insights_rounded,
              onTap: () => Get.to(
                () => const HeatmapScreen(),
                transition: Transition.downToUp,
              ),
            ),
            _NavItem(
              icon: LucideIcons.settings300,
              onTap: canOpenSettings
                  ? () {
                      controller.resetGame(false);
                      Get.to(() => SettingScreen(),
                          transition: Transition.rightToLeft);
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
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? Colors.white12
        : isActive
            ? _kNavActive
            : _kNavInactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

// ─── REVERSE MODE CHOICE PANEL ────────────────────────────────────────────────

class _ReverseChoicePanel extends StatelessWidget {
  const _ReverseChoicePanel({required this.controller});
  final HomeController controller;

  _BtnStyle _styleFor(String note) {
    final selected = controller.reverseSelectedNote;
    if (selected == null) {
      return _BtnStyle(
        bg: const Color(0xFF252525),
        border: Colors.white.withValues(alpha: 0.09),
        text: Colors.white,
      );
    }
    if (note == controller.highlightNode) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.18),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    if (note == selected && !controller.reverseWasCorrect) {
      return _BtnStyle(
        bg: JHGColors.primary.withValues(alpha: 0.18),
        border: JHGColors.primary,
        text: JHGColors.primary,
      );
    }
    return _BtnStyle(
      bg: const Color(0xFF1A1A1A),
      border: Colors.white.withValues(alpha: 0.04),
      text: Colors.white38,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.reverseChoices.isEmpty) return const SizedBox.shrink();

    final locked = controller.reverseSelectedNote != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Score + position hint
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SCORE',
                      style: GoogleFonts.inter(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      )),
                  const SizedBox(width: 6),
                  Text(controller.score.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
            Text(
              controller.reversePositionHint,
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          'WHICH NOTE IS THIS?',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: controller.reverseChoices.map((note) {
            final s = _styleFor(note);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: locked
                      ? null
                      : () => controller.selectReverseAnswer(note),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 60,
                    decoration: BoxDecoration(
                      color: s.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: s.border, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        note,
                        style: GoogleFonts.poppins(
                          color: s.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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

class _BtnStyle {
  const _BtnStyle(
      {required this.bg, required this.border, required this.text});
  final Color bg;
  final Color border;
  final Color text;
}
