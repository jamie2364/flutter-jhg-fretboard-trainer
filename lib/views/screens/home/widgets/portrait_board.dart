import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/count_timer_widget.dart';

class PortraitBoard extends StatelessWidget {
  const PortraitBoard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── TOP NAV ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Trophy / Leaderboard
                GestureDetector(
                  onTap: () {
                    Get.to(() => LeadershipScreen(),
                        transition: Transition.leftToRight);
                    if (isFreePlan) {
                      controller.interstitialAds?.showInterstitial();
                    }
                  },
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.trophy300,
                        color: Colors.white70, size: 20),
                  ),
                ),

                // Mode indicator pill — tap to cycle when not playing
                Obx(() => GestureDetector(
                      onTap: controller.isStart
                          ? null
                          : controller.isPaused
                              ? null
                              : () => controller.cycleGameMode(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: controller.isStart
                                ? Colors.transparent
                                : JHGColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _modeIcon(controller.currentGameMode.value),
                              color: controller.isStart
                                  ? Colors.white38
                                  : JHGColors.primary,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _modeLabel(controller.currentGameMode.value),
                              style: GoogleFonts.inter(
                                color: controller.isStart
                                    ? Colors.white38
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),

                // Settings
                Obx(() => GestureDetector(
                      onTap: controller.currentGameMode.value != 'leaderboard'
                          ? () {
                              controller.resetGame(false);
                              Get.to(() => SettingScreen(),
                                  transition: Transition.rightToLeft);
                              if (isFreePlan) {
                                controller.interstitialAds?.showInterstitial();
                              }
                            }
                          : null,
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.settings300,
                          color:
                              controller.currentGameMode.value != 'leaderboard'
                                  ? Colors.white70
                                  : Colors.white24,
                          size: 20,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          // ─── GUITAR BOARD ─────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 45.8),
              child: IgnorePointer(
                ignoring: !controller.isStart,
                child: const GuitarBoard(isPortrait: true),
              ),
            ),
          ),

          SizedBox(height: height * 0.01),

          // Timer lives OUTSIDE the panel so it never eats into the fretboard
          CountTimerWidget(),

          SizedBox(height: height * 0.006),

          // ─── BOTTOM PANEL ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 14, 20, bottomInset > 0 ? bottomInset : 20),
            child: Column(
              children: [
                // Note target + score — no Rx here, parent GetBuilder rebuilds on isStart change
                if (controller.isStart)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: JHGColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: JHGColors.primary.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            '${controller.highlightNode ?? ""}',
                            style: GoogleFonts.poppins(
                              color: JHGColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SCORE',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                controller.score.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action row — Obx valid: always reads currentGameMode.value first
                Obx(() {
                  final mode = controller.currentGameMode.value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Left: Mode-cycle icon. Disabled while running/paused.
                        GestureDetector(
                          onTap: controller.isStart || controller.isPaused
                              ? null
                              : () => controller.cycleGameMode(),
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Icon(
                              _modeIcon(mode),
                              color: controller.isStart || controller.isPaused
                                  ? Colors.white24
                                  : Colors.white54,
                              size: 22,
                            ),
                          ),
                        ),

                        // Center: Play / Stop circle
                        GestureDetector(
                          onTap: controller.isStart
                              ? () => controller.pauseGame()
                              : controller.isPaused
                                  ? () => controller.resumeGame()
                                  : () {
                                      controller.startTimer();
                                      controller.startTheGame();
                                    },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 68,
                            width: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: JHGColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: JHGColors.primary.withValues(
                                    alpha: controller.isStart ? 0.40 : 0.15,
                                  ),
                                  blurRadius: controller.isStart ? 22 : 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              controller.isStart
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),

                        // Right: Full reset
                        GestureDetector(
                          onTap: () => controller.resetGame(true),
                          child: Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: Colors.white54, size: 22),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'stopwatch':
        return LucideIcons.timer300;
      case 'countdown':
        return LucideIcons.clock300;
      case 'leaderboard':
        return LucideIcons.trophy300;
      default:
        return LucideIcons.timer300;
    }
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'stopwatch':
        return 'STOPWATCH';
      case 'countdown':
        return 'COUNTDOWN';
      case 'leaderboard':
        return 'LEADERBOARD';
      default:
        return 'STOPWATCH';
    }
  }
}
