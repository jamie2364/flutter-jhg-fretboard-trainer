import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/utils/app_assets.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/home/widgets/board_widgets.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart'
    show StringsNameWidget;
import 'package:fretboard/views/screens/home/widgets/web_guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/setting_screen.dart';
import 'package:get/get.dart';

import '../../../widgets/count_timer_widget.dart';
import '../../../widgets/scroll_bar_behavior.dart';

class WebBoard extends StatelessWidget {
  const WebBoard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final List<Widget> alphabetsWidget = [
      buildStringCharWeb('E', 1, controller),
      buildStringCharWeb('A', 2, controller),
      buildStringCharWeb('D', 3, controller),
      buildStringCharWeb('G', 4, controller),
      buildStringCharWeb('B', 5, controller),
      buildStringCharWeb('E', 6, controller),
    ];
    return JHGBody(
      body: Column(
        children: [
          JHGAppBar(
            isResponsive: true,
            leadingWidget: JHGIconButton(
                childPadding: EdgeInsets.all(6),
                enabled: true,
                svgImg: AppAssets.iconTropy,
                onTap: () {
                  Get.to(() => LeadershipScreen(),
                      transition: Transition.leftToRight);
                }),
            trailingWidget: JHGSettingsOptBtn(
              btnEnabled: !controller.leaderboardMode,
              onTap: () {
                controller.resetGame(false);
                Get.to(() => SettingScreen(),
                    transition: Transition.rightToLeft);
              },
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    //color: Colors.red,
                    child: ScrollConfiguration(
                      behavior: NoScrollbarBehavior(),
                      child: SingleChildScrollView(
                        scrollDirection: controller.isPortrait == true
                            ? Axis.horizontal
                            : Axis.vertical,
                        padding: EdgeInsets.only(
                            top: controller.isPortrait
                                ? height * 0.10
                                : height * 0.060),
                        child: IgnorePointer(
                          ignoring: !controller.isStart,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              controller.isPortrait == true
                                  ? SizedBox.shrink()
                                  : StringsNameWidget(width: width * 0.21),
                              controller.isPortrait == true
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        //color: Colors.blue,
                                        height: height * 0.50,
                                        // width: width * 0.930,
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding:
                                                    EdgeInsets.only(top: 16.dp),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: alphabetsWidget
                                                      .reversed
                                                      .toList(),
                                                ),
                                              ),
                                              const WebLandscapeGuitarBoard()
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : ScrollConfiguration(
                                      behavior: NoScrollbarBehavior(),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Container(
                                            // color: Colors.blue,
                                            //width: width * 0.29,
                                            alignment: Alignment.topCenter,
                                            child:
                                                const WebPortraitGuitarBoard()),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14),
                // TIMER  WITH ADD AND SUBTRACT BUTTONS
                CountTimerWidget(),
                SizedBox(height: 7),
                JHGAppBar(
                  isResponsive: true,
                  isBottom: false,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  leadingWidget: controller.isStart == true
                      ? JHGResetBtn(
                          enabled: true,
                          onTap: () {
                            controller.setGameMode(
                                timer: false, leaderboard: false);
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
                              svgImg: AppAssets.iconStopwatch,
                              onTap: () {
                                controller.setGameMode(
                                    timer: true, leaderboard: false);
                                controller.resetTimer();
                              })
                          :

                          // ICON TIMER
                          controller.timerMode == true
                              ? JHGIconButton(
                                  childPadding: EdgeInsets.all(4),
                                  enabled: true,
                                  size: 40,
                                  svgImg: AppAssets.iconTimer,
                                  onTap: () {
                                    controller.setGameMode(
                                        timer: false, leaderboard: true);
                                    controller.resetTimer();
                                  })
                              :

                              // ICON LEADERBOARD
                              controller.leaderboardMode == true
                                  ? JHGIconButton(
                                      size: 40,
                                      childPadding: EdgeInsets.all(6),
                                      enabled: true,
                                      svgImg: AppAssets.iconTropy,
                                      onTap: () {
                                        controller.setGameMode(
                                            timer: false, leaderboard: false);
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
                                style: JHGTextStyles.subLabelStyle.copyWith(
                                  color: JHGColors.primary,
                                  fontSize: 2.0.w,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          :
                          // START BUTTON
                          JHGPrimaryBtn(
                              label: AppStrings.start,
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
                          svgImg: AppAssets.iconRotate,
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
                                AppStrings.scoreText,
                                style: JHGTextStyles.labelStyle.copyWith(
                                  fontSize: 1.6.w,
                                ),
                              ),
                              Text(
                                controller.score.toString(),
                                style: JHGTextStyles.labelStyle.copyWith(
                                  fontSize: 1.6.w,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
          !controller.leaderboardMode
              ? SizedBox(height: 14)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'You can\'t change settings in leaderboard',
                    style: TextStyle(
                      color: JHGColors.primary,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
