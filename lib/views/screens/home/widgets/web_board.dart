import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:fretboard/controllers/home_controller.dart';
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
      bodyAppBar: JHGAppBar(
        isResponsive: true,
        leadingWidget: JHGIconButton(
            childPadding: EdgeInsets.all(6),
            enabled: true,
            iconData: LucideIcons.trophy300,
            onTap: () {
              Get.to(() => LeadershipScreen(),
                  transition: Transition.leftToRight);
            }),
        trailingWidget: JHGSettingsOptBtn(
          // ** Updated condition **
          btnEnabled: controller.currentGameMode.value != 'leaderboard',
          onTap: () {
            if (controller.currentGameMode.value != 'leaderboard') {
              controller.resetGame(false);
              Get.to(() => SettingScreen(), transition: Transition.rightToLeft);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
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
                                  : StringsNameWidget(
                                      width: width * 0.21,
                                    ),
                              controller.isPortrait == true
                                  ? SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        height: height * 0.50,
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
                CountTimerWidget(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            // ** Updated Bottom AppBar Logic **
            child: Obx(() => JHGAppBar(
                  isResponsive: true,
                  isBottom: true,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  leadingWidget: controller.isStart
                      ? JHGResetBtn(
                          enabled: true,
                          onTap: () {
                            controller.resetGame(false); // Only reset state
                          })
                      : JHGIconButton(
                          // Mode Cycle Button
                          iconData: controller.currentGameMode.value ==
                                  'stopwatch'
                              ? LucideIcons.timer300 // Next is Countdown
                              : controller.currentGameMode.value == 'countdown'
                                  ? LucideIcons.trophy300 // Next is Leaderboard
                                  : LucideIcons.clock300, // Next is Stopwatch
                          enabled: !controller
                              .isStart, // Cannot change mode mid-game
                          tooltipMsg: controller.isStart
                              ? "Cannot change mode during game"
                              : "",
                          onTap: () {
                            if (!controller.isStart) {
                              controller.cycleGameMode();
                            }
                          }),
                  centerWidget: controller.isStart
                      ? Container(
                          height: 40,
                          width: 22.w,
                          alignment: Alignment.topCenter,
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
                      : JHGPrimaryBtn(
                          label: AppStrings.start,
                          width: 20.w,
                          onPressed: () {
                            controller.startTimer();
                            controller.startTheGame();
                          },
                        ),
                  trailingWidget: JHGIconButton(
                      childPadding: EdgeInsets.all(4),
                      enabled: true,
                      iconData: LucideIcons.ratio300,
                      onTap: () {
                        controller.toggleOrientation();
                      }),
                  bottom: controller.isStart == true
                      ? Center(
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
                )),
          ),
        ],
      ),
    );
  }
}
