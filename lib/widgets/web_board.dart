import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/widgets/guitar_board.dart';
import 'package:fretboard/screens/setting_screen/setting_screen.dart';
import 'package:fretboard/utils/images.dart';
import 'package:fretboard/widgets/button_icon.dart';
import 'package:fretboard/widgets/web_guitar_board.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import '../screens/leader_board_screen/leaderboard_screen.dart';
import '../utils/app_ colors.dart';
import '../utils/app_constant.dart';
import 'add_sub_button.dart';

class WebBoard extends StatelessWidget {
  const WebBoard({super.key, required this.controller});

  final HomeController controller;
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final dpr = MediaQuery.of(context).devicePixelRatio;
    // final w = MediaQuery.of(context).size.width;
    return JHGBody(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  //color: Colors.red,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: controller.isPortrait ? height * 0.10:  height * 0.060),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        controller.isPortrait == true
                            ? Container(
                                //color: Colors.blue,
                                height: height * 0.65,
                                width: width * 0.900,
                                child: Center(
                                  child: const WebLandscapeGuitarBoard(),
                                ))
                            : Container(
                                //color: Colors.green,
                                //height: height * 0.64,
                                width: width * 0.16,
                                alignment: Alignment.topCenter,
                                child: Container(
                                  //height: height * 0.60,
                                  width: width * 0.16,
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.zero,
                                    child: const WebPortraitGuitarBoard(),
                                  ),
                                )),

                        //SPACER
                        // SizedBox(
                        //   height: controller.isPortrait ?8.5 :110,
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 14,
              ),
              // TIMER  WITH ADD AND SUBTRACT BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  controller.timerMode == true
                      ? WebAddAndSubtractButton(
                      onTap: () {
                        controller.decreaseTime();
                      },
                      isAdd: false)
                      : const SizedBox(),
                  SizedBox(
                    width: 3.w,
                  ),
                  Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: controller.secondsRemaining,
                      //widget.model.seconds,
                      builder: (context, value, child) {
                        return Text(
                          controller.formatTime(value),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppConstant.sansFont,
                            color: AppColors.whitePrimary,
                            fontSize: 2.5.w,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: 3.w,
                  ),
                  controller.timerMode == true
                      ? WebAddAndSubtractButton(
                      onTap: () {
                        controller.increaseTime();
                      },
                      isAdd: true)
                      : const SizedBox(),
                ],
              ),
              // //TIMER , STOPWATCH , ROTATE ICON
              SizedBox(
                height: 7,
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: width * 0.020,
                    right: width * 0.020,
                    bottom: height * 0.030),
                child: JHGAppBar(
                  // leading
                  leadingWidget: controller.isStart == true
                      ? JHGResetBtn(
                          enabled: true,
                          onTap: () {
                            controller.setTimerMode(false);
                            controller.setLeaderMode(false);
                            controller.resetGame(false);
                          })
                      :

                      // ICON STOP WATCH
                      controller.timerMode == false &&
                              controller.leaderboardMode == false
                          ? JHGIconButton(
                              childPadding: EdgeInsets.all(4),
                              enabled: true,
                              size: 40,
                              svgImg: Images.iconStopwatch,
                              onTap: () {
                                controller.setTimerMode(true);
                                controller.setLeaderMode(false);
                                controller.resetTimer();
                              })
                          :

                          // ICON TIMER
                          controller.timerMode == true
                              ? JHGIconButton(
                                  childPadding: EdgeInsets.all(4),
                                  enabled: true,
                                  size: 40,
                                  svgImg: Images.iconTimer,
                                  onTap: () {
                                    controller.setTimerMode(false);
                                    controller.setLeaderMode(true);
                                    controller.resetTimer();
                                  })
                              :

                              // ICON LEADERBOARD
                              controller.leaderboardMode == true
                                  ? JHGIconButton(
                                      size: 40,
                                      childPadding: EdgeInsets.all(6),
                                      enabled: true,
                                      svgImg: Images.iconTropy,
                                      onTap: () {
                                        controller.setLeaderMode(false);
                                        controller.setTimerMode(false);
                                        controller.resetTimer();
                                      })
                                  : SizedBox(),
                  centerWidget:

                      // HIGILITED NOTE
                      controller.isStart == true
                          ? Container(
                              height: 45,
                              width: 22.w,
                              alignment: Alignment.topCenter,
                              //color: Colors.red,
                              child: Text(
                                "    ${controller.highlightNode ?? ""}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppConstant.sansFont,
                                  color: AppColors.redPrimary,
                                  fontSize: 2.0.w,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          :
                          // START BUTTON
                          JHGPrimaryBtn(
                              label: AppConstant.start,
                              width: 20.w,
                              onPressed: () {
                                controller.startTimer();
                                controller.startTheGame();
                              },
                            ),
                  trailingWidget:
                      // ROTATE ICON
                      JHGIconButton(
                        childPadding: EdgeInsets.all(4),
                        enabled: true,
                          svgImg: Images.iconRotate,
                          size: 40,
                          onTap: () {
                            controller.toggleOrientation();
                          }),
                  bottom: controller.isStart == true
                      ?

                      // SCORE TEXT

                      Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppConstant.scoreText,
                                style: TextStyle(
                                  fontFamily: AppConstant.sansFont,
                                  color: AppColors.whitePrimary,
                                  fontSize: 1.6.w,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                controller.score.toString(),
                                style: TextStyle(
                                  fontFamily: AppConstant.sansFont,
                                  color: AppColors.whitePrimary,
                                  fontSize: 1.6.w,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: width * 0.020, right: width * 0.020, top: height * 0.030),
                child: JHGAppBar(
                  leadingWidget: JHGIconButton(
                      childPadding: EdgeInsets.all(6),
                      enabled: true,
                      svgImg: Images.iconTropy,
                      onTap: () {
                        Get.to(() => LeadershipScreen(),
                            transition: Transition.leftToRight);
                      }),
                  trailingWidget: JHGSettingsButton(
                    enabled: !controller.leaderboardMode,
                    onTap: () {
                      if (controller.leaderboardMode == true) {
                        return;
                      } else {
                        controller.resetGame(false);
                        Get.to(() => SettingScreen(),
                            transition: Transition.rightToLeft);
                      }
                    },
                  ),
                ),
              ),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
