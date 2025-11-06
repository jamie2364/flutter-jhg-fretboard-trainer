import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:get/get.dart';

import '../../../widgets/count_timer_widget.dart';

class PortraitBoard extends StatelessWidget {
  const PortraitBoard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return AnimatedScale(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linearToEaseOut,
      scale: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // TROPHY AND SETTING ICON
          JHGAppBar(
            isResponsive: true,
            leadingWidget: JHGIconButton(
              childPadding: EdgeInsets.all(3),
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
            trailingWidget: JHGSettingsOptBtn(
              // ** Updated condition **
              btnEnabled: controller.currentGameMode.value != 'leaderboard',
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
          SizedBox(
            height: height * 0.01,
          ),

          // BOARD WITH NUMBER
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 45.8),
              child: IgnorePointer(
                ignoring: !controller.isStart,
                child: const GuitarBoard(
                  isPortrait: true,
                ),
              ),
            ),
          ),
          //SPACER
          SizedBox(
            height: height * 0.02,
          ),
          // TIMER
          CountTimerWidget(),
          SizedBox(
            height: height * 0.010,
          ),
          // ** Updated Bottom AppBar Logic **
          Obx(() => JHGAppBar(
                isBottom: true,
                isResponsive: true,
                leadingWidget: controller.isStart
                    ? JHGResetBtn(
                        onTap: () {
                          controller.resetGame(false); // Only reset state
                        },
                        enabled: true,
                      )
                    : JHGIconButton(
                        // Mode Cycle Button
                        iconData: controller.currentGameMode.value ==
                                'stopwatch'
                            ? LucideIcons.timer300 // Next is Countdown
                            : controller.currentGameMode.value == 'countdown'
                                ? LucideIcons.clock300 // Next is Leaderboard
                                : LucideIcons.trophy300, // Next is Stopwatch
                        enabled:
                            !controller.isStart, // Cannot change mode mid-game
                        onTap: () {
                          if (!controller.isStart) {
                            controller.cycleGameMode();
                          }
                        }),
                centerWidget: controller.isStart
                    ? Container(
                        height: height * 0.060,
                        width: width * 0.45,
                        alignment: Alignment.topCenter,
                        child: Text(
                          "    ${controller.highlightNode ?? ""}",
                          textAlign: TextAlign.center,
                          style: JHGTextStyles.mdlabelStyle.copyWith(
                            color: JHGColors.primary,
                          ),
                        ),
                      )
                    : JHGPrimaryBtn(
                        label: AppStrings.start,
                        height: 50,
                        width: width * 0.45,
                        onPressed: () {
                          controller.startTimer();
                          controller.startTheGame();
                        },
                      ),
                trailingWidget: JHGIconButton(
                    iconData: LucideIcons.ratio300,
                    enabled: true,
                    childPadding: EdgeInsets.all(2),
                    onTap: () {
                      controller.toggleOrientation();
                    }),
              )),

          //SCORE
          if (controller.isStart)
            Padding(
              // Add padding to separate from bottom bar
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.scoreText,
                      style: JHGTextStyles.labelStyle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      controller.score.toString(),
                      style: JHGTextStyles.subLabelStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
