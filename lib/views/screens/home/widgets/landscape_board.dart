import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:fretboard/views/widgets/count_timer_widget.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LandscapeBoard extends StatelessWidget {
  const LandscapeBoard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── TOP ICON ROW ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            left: width * 0.08,
            right: width * 0.1,
            top: 8,
            bottom: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mode-cycle (idle) or Reset (playing)
              // Always read currentGameMode.value first so Obx has a valid Rx subscription
              Obx(() {
                final mode = controller.currentGameMode.value;
                if (controller.isStart) {
                  return GestureDetector(
                    onTap: () => controller.resetGame(false),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: _iconBtn(Icons.refresh_rounded),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => controller.cycleGameMode(),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: _iconBtn(_modeIcon(mode), active: true),
                  ),
                );
              }),

              // Leaderboard
              GestureDetector(
                onTap: () {
                  Get.to(() => const LeadershipScreen(),
                      transition: Transition.leftToRight);
                  if (isFreePlan) {
                    controller.interstitialAds?.showInterstitial();
                  }
                },
                child: RotatedBox(
                  quarterTurns: 1,
                  child: _iconBtn(LucideIcons.trophy300),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: height * 0.01),

        // ─── MAIN BOARD AREA ──────────────────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left panel — fixed 72 px so 48 px buttons fit with padding
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (controller.isStart) ...[
                      // Score badge (rotated so text reads bottom-to-top)
                      RotatedBox(
                        quarterTurns: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SCORE',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                controller.score.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Note to find
                      RotatedBox(
                        quarterTurns: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: JHGColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: JHGColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            controller.highlightNode ?? '',
                            style: GoogleFonts.poppins(
                              color: JHGColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Play button — 48×48 fits inside 72 px panel
                      GestureDetector(
                        onTap: () {
                          controller.startTimer();
                          controller.startTheGame();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: JHGColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: JHGColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Timer area
              const Expanded(
                flex: 1,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: CountTimerWidget(),
                  ),
                ),
              ),

              // Guitar board
              Expanded(
                flex: 4,
                child: IgnorePointer(
                  ignoring: !controller.isStart,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(right: width * 0.02),
                    child: const GuitarBoard(isPortrait: false),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: height * 0.01),

        // ─── BOTTOM ICON ROW ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(
            left: width * 0.1,
            right: width * 0.08,
            bottom: 8,
            top: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Settings — locked in leaderboard mode and mid-session.
              Obx(() {
                final settingsLocked =
                    controller.currentGameMode.value == 'leaderboard' ||
                        controller.sessionActive;
                return GestureDetector(
                  onTap: settingsLocked
                      ? null
                      : () {
                          controller.resetGame(false);
                          Get.to(() => const SettingScreen(),
                              transition: Transition.rightToLeft);
                          if (isFreePlan) {
                            controller.interstitialAds?.showInterstitial();
                          }
                        },
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: _iconBtn(
                      LucideIcons.settings300,
                      disabled: settingsLocked,
                    ),
                  ),
                );
              }),

              // Heatmap — locked mid-session. (Parent GetBuilder rebuilds this
              // on start/pause/reset, so no Obx is needed for sessionActive.)
              Builder(builder: (_) {
                final locked = controller.sessionActive;
                return GestureDetector(
                  onTap: locked
                      ? null
                      : () => Get.to(
                            () => const HeatmapScreen(),
                            transition: Transition.downToUp,
                          ),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: _iconBtn(Icons.insights_rounded, disabled: locked),
                  ),
                );
              }),

              // Full reset
              GestureDetector(
                onTap: () => controller.resetGame(true),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: _iconBtn(Icons.refresh_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, {bool active = false, bool disabled = false}) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: active
            ? Border.all(color: JHGColors.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Icon(
        icon,
        color: disabled
            ? Colors.white24
            : active
                ? JHGColors.primary
                : Colors.white70,
        size: 20,
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
      case 'reverse':
        return Icons.quiz_rounded;
      default:
        return LucideIcons.timer300;
    }
  }
}
