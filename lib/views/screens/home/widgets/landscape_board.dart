import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/setting_screen.dart';
import 'package:fretboard/views/widgets/count_timer_widget.dart';
import 'package:get/get.dart';

class LandscapeBoard extends StatelessWidget {
  const LandscapeBoard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    const double placeholderWidth = 44.0; // button spacing placeholder

    return AnimatedScale(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linearToEaseOut,
      scale: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 TOP ICON ROW
          Container(
            padding: EdgeInsets.only(
              left: width * 0.08,
              right: width * 0.1,
              top: 8,
              bottom: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mode Cycle Icon
                Obx(() {
                  IconData icon;
                  if (controller.currentGameMode.value == 'stopwatch') {
                    icon = LucideIcons.timer300; // Next is Countdown
                  } else if (controller.currentGameMode.value == 'countdown') {
                    icon = LucideIcons.trophy300; // Next is Leaderboard
                  } else {
                    icon = LucideIcons.clock300; // Next is Stopwatch
                  }
                  return RotatedBox(
                    quarterTurns: 1,
                    child: JHGIconButton(
                      enabled: !controller.isStart,
                      iconData: icon,
                      tooltipMsg: controller.isStart
                          ? "Cannot change mode during game"
                          : "",
                      onTap: () {
                        if (!controller.isStart) {
                          controller.cycleGameMode();
                        }
                      },
                    ),
                  );
                }),

                // Reset button or placeholder
                controller.isStart
                    ? JHGResetBtn(
                        onTap: () {
                          controller.resetGame(false);
                        },
                        enabled: true,
                      )
                    : const SizedBox(width: placeholderWidth),

                // Leaderboard icon
                RotatedBox(
                  quarterTurns: 1,
                  child: JHGIconButton(
                    enabled: true,
                    iconData: LucideIcons.trophy300,
                    onTap: () {
                      Get.to(() => LeadershipScreen(),
                          transition: Transition.leftToRight);
                      if (isFreePlan) {
                        controller.interstitialAds?.showInterstitial();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.01),

          // 🔹 MAIN BOARD AREA
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // START BUTTON / SCORE AREA
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  width: width * 0.12,
                  padding: EdgeInsets.only(left: width * 0.01),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isStart)
                        Flexible(
                          fit: FlexFit.loose,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppStrings.scoreText,
                                        style: JHGTextStyles.labelStyle
                                            .copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        controller.score.toString(),
                                        style: JHGTextStyles.labelStyle
                                            .copyWith(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    controller.highlightNode ?? "",
                                    style: JHGTextStyles.smlabelStyle.copyWith(
                                      color: JHGColors.primary,
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        RotatedBox(
                          quarterTurns: 1,
                          child: JHGPrimaryBtn(
                            label: AppStrings.start,
                            height: 50,
                            width: width * 0.40,
                            onPressed: () {
                              controller.startTimer();
                              controller.startTheGame();
                            },
                          ),
                        ),

                      RotatedBox(
                        quarterTurns: 1,
                        child: SizedBox(
                          height:
                              controller.currentGameMode.value == 'leaderboard'
                                  ? 6
                                  : 10,
                        ),
                      ),
                      if (controller.currentGameMode.value == 'leaderboard')
                        RotatedBox(
                          quarterTurns: 1,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'You can\'t change settings in leaderboard',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: JHGColors.primary.withValues(alpha: 204),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),

                // TIMER AREA
                Expanded(
                  flex: 1,
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: CountTimerWidget(),
                    ),
                  ),
                ),

                // GUITAR BOARD AREA
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

          // 🔹 BOTTOM ICON ROW
          Container(
            padding: EdgeInsets.only(
              left: width * 0.1,
              right: width * 0.08,
              bottom: 8,
              top: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Settings Icon
                RotatedBox(
                  quarterTurns: 1,
                  child: JHGIconButton(
                    enabled: controller.currentGameMode.value != 'leaderboard',
                    iconData: LucideIcons.settings300,
                    iconColor: controller.currentGameMode.value == 'leaderboard'
                        ? JHGColors.whiteGrey
                        : JHGColors.white,
                    tooltipMsg:
                        controller.currentGameMode.value == 'leaderboard'
                            ? "Settings disabled in Leaderboard mode"
                            : "",
                    onTap: () {
                      if (controller.currentGameMode.value != 'leaderboard') {
                        controller.resetGame(false);
                        Get.to(() => SettingScreen(),
                            transition: Transition.rightToLeft);
                        if (isFreePlan) {
                          controller.interstitialAds?.showInterstitial();
                        }
                      }
                    },
                  ),
                ),

                // Rotate Orientation Icon
                RotatedBox(
                  quarterTurns: 1,
                  child: JHGIconButton(
                    enabled: true,
                    childPadding: const EdgeInsets.all(1),
                    iconData: LucideIcons.ratio300,
                    onTap: () {
                      controller.toggleOrientation();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
