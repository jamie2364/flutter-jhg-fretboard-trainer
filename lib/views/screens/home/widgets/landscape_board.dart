import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_assets.dart';
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
    return AnimatedScale(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linearToEaseOut,
      scale: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TROPHY AND Timer ICON
          Container(
            height: 30,
            //color: Colors.amber,
            child: Padding(
              padding: EdgeInsets.only(
                left: width * 0.08,
                right: width * 0.1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  controller.isStart == true
                      ? JHGResetBtn(onTap: () {
                          controller.setGameMode(
                              timer: false, leaderboard: false);
                          controller.resetGame(false);
                        })
                      : controller.timerMode == false &&
                              controller.leaderboardMode == false
                          ? RotatedBox(
                              quarterTurns:
                                  controller.isPortrait == true ? 0 : 1,
                              child: JHGIconButton(
                                  enabled: true,
                                  iconData: LucideIcons.timer300,
                                  onTap: () {
                                    controller.setGameMode(
                                        timer: true, leaderboard: false);
                                    controller.resetTimer();
                                  }),
                            )
                          : controller.timerMode == true
                              ? JHGIconButton(
                                  enabled: true,
                                  iconData: LucideIcons.clock300,
                                  onTap: () {
                                    controller.setGameMode(
                                        timer: false, leaderboard: true);
                                    controller.resetTimer();
                                  })
                              : controller.leaderboardMode == true
                                  ? JHGIconButton(
                                      enabled: true,
                                      iconData: LucideIcons.trophy300,
                                      onTap: () {
                                        controller.setGameMode(
                                            timer: false, leaderboard: false);
                                        controller.resetTimer();
                                      })
                                  : SizedBox(),
                  JHGIconButton(
                      enabled: true,
                      iconData: LucideIcons.trophy300,
                      onTap: () {
                        Get.to(() => LeadershipScreen(),
                            transition: Transition.leftToRight);
                        if (isFreePlan) {
                          controller.interstitialAds?.showInterstitial();
                        }
                        // Get.to(() => LeadershipScreen(),
                        //     transition: Transition.leftToRight);
                      }),
                ],
              ),
            ),
          ),

          //SPACER
          SizedBox(
            height: height * 0.025,
          ),

          // BOARD
          Expanded(
              child: Container(
            height: height * 0.75,
            child: Row(
              children: [
                // Spacer(),

                // START BUTTON
                controller.isStart == true
                    ? const SizedBox()
                    : RotatedBox(
                        quarterTurns: 1,
                        child: Column(
                          children: [
                            JHGPrimaryBtn(
                              label: AppStrings.start,
                              height: 50,
                              width: width * 0.45,
                              onPressed: () {
                                controller.startTimer();
                                controller.startTheGame();
                              },
                            ),
                            !controller.leaderboardMode
                                ? SizedBox(height: 14)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'You can\'t change settings in leaderboard',
                                      style: TextStyle(
                                        color: JHGColors.primary,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                controller.isStart == false
                    ? SizedBox(
                        width: width * 0.01,
                      )
                    : const SizedBox(),
                // SCORE AND NOTE
                controller.isStart == false
                    ? const SizedBox()
                    : Row(
                        children: [
                          RotatedBox(
                            quarterTurns: 1,
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
                                  style: JHGTextStyles.labelStyle.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                controller.highlightNode ?? "",
                                style: JHGTextStyles.smlabelStyle.copyWith(
                                  color: JHGColors.primary,
                                  fontSize: 28,
                                ),
                              )),
                        ],
                      ),
                Spacer(),
                // TIMER WITH INCREASE AND DECREASE BUTTON
                RotatedBox(quarterTurns: 1, child: CountTimerWidget()),

                Spacer(),
                // controller.isStart ?
                //  SizedBox(width: width*0.04,)
                //   :
                //  SizedBox(width: width*0.06,),

                // BOARD
                IgnorePointer(
                  ignoring: !controller.isStart,
                  child: Container(
                      //color: Colors.blue,
                      height: height * 0.74,
                      child: const GuitarBoard(
                        isPortrait: false,
                      ),

                  ),
                ),
                Spacer(),
              ],
            ),
          )),

          //SPACER
          SizedBox(
            height: height * 0.025,
          ),

          Container(

            height: 30,
            child: Padding(
              padding: EdgeInsets.only(
                left: width * 0.1,
                right: width * 0.08,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  JHGIconButton(
                      size: 36,
                      enabled: true,
                      childPadding: EdgeInsets.all(1),
                      iconData: LucideIcons.rotateCcw300,
                      onTap: () {
                        controller.toggleOrientation();
                      }),
                  JHGIconButton(
                    enabled: true,
                    iconData: LucideIcons.settings300,
                    iconColor: controller.leaderboardMode == true
                        ? JHGColors.whiteGrey
                        : JHGColors.white,
                    onTap: () {
                      if (controller.leaderboardMode == true) {
                        return;
                      } else {
                        controller.resetGame(false);
                        Get.to(() => SettingScreen(),
                            transition: Transition.rightToLeft);
                        if (isFreePlan) {
                          controller.interstitialAds?.showInterstitial();
                        }
                        // Get.to(() => SettingScreen(),
                        //     transition: Transition.rightToLeft);
                      }
                    },
                  )
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}
