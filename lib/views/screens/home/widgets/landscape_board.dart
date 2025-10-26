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
    // Using default JHGIconButton size implicitly now
    const double placeholderWidth = 44.0; // Placeholder width similar to default button tappable area

    return AnimatedScale(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linearToEaseOut,
      scale: 1, // Keep scale at 1
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ICON ROW
          Container(
            // Use padding to control spacing instead of fixed height
            padding: EdgeInsets.only(
              left: width * 0.08,
              right: width * 0.1,
              top: 8, // Adjust as needed
              bottom: 4 // Adjust as needed
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top-left icon area (Reset Button or Placeholder)
                controller.isStart
                    ? JHGResetBtn(
                        onTap: () {
                          controller.resetGame(false); // Reset state, keep mode
                        },
                        enabled: true,
                      )
                    : SizedBox(width: placeholderWidth), // Use placeholder for alignment

                // Top-right icon (Leadership Screen)
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
                      }),
                ),
              ],
            ),
          ),

          // SPACER
          SizedBox(height: height * 0.01), // Minimal space

          // BOARD AREA
          Expanded(
            child: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items in the row
                children: [
                  // START BUTTON / SCORE & NOTE AREA
                  Container(
                    width: width * 0.12, // Allocate width
                    padding: EdgeInsets.only(left: width * 0.01),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
                      children: [
                        controller.isStart
                            ? Expanded( // Allow score/note content to expand
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
                                            style: JHGTextStyles.labelStyle.copyWith(fontSize: 16),
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            controller.score.toString(),
                                            style: JHGTextStyles.labelStyle.copyWith(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 15),
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
                              )
                            : RotatedBox( // Only rotate button when game not started
                                quarterTurns: 1,
                                child: Column(
                                 mainAxisSize: MainAxisSize.min, // Fit content vertically
                                 children: [
                                   JHGPrimaryBtn(
                                     label: AppStrings.start,
                                     height: 50,
                                     width: width * 0.40, // Adjust as needed
                                     onPressed: () {
                                       controller.startTimer();
                                       controller.startTheGame();
                                     },
                                   ),
                                    // Slightly reduced space below button
                                    SizedBox(height: controller.currentGameMode.value == 'leaderboard' ? 6 : 10),
                                    if(controller.currentGameMode.value == 'leaderboard')
                                      FittedBox( // Allow text to shrink if needed
                                         fit: BoxFit.scaleDown,
                                         child: Text(
                                          'You can\'t change settings in leaderboard',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            // ** Fixed deprecated call **
                                            color: JHGColors.primary.withValues(alpha: 204), // 0.8 alpha
                                            fontSize: 11, // Slightly smaller
                                          ),
                                                                               ),
                                       ),
                                 ],
                                ),
                              ),
                      ],
                    ),
                  ),

                  // TIMER WIDGET AREA
                  Expanded(
                    flex: 1, // Keep flex 1
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: CountTimerWidget(),
                      ),
                    ),
                  ),

                  // GUITAR BOARD AREA
                  Expanded(
                    flex: 4, // Keep larger flex
                    child: IgnorePointer(
                      ignoring: !controller.isStart,
                      child: Container(
                        alignment: Alignment.center,
                         padding: EdgeInsets.only(right: width * 0.02), // Keep padding
                        child: const GuitarBoard(
                          isPortrait: false,
                        ),
                      ),
                    ),
                  ),
                  // Removed SizedBox causing potential horizontal overflow
                ],
              ),
            ),
          ),

          // SPACER
          SizedBox(height: height * 0.01), // Minimal space

          // BOTTOM ICON ROW
          Container(
             padding: EdgeInsets.only(
               left: width * 0.1,
               right: width * 0.08,
               bottom: 8,
               top: 4
             ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 // Mode Cycle Icon
                 Obx(() {
                     IconData icon;
                     // ** Corrected Logic: Show icon for the NEXT mode **
                     if (controller.currentGameMode.value == 'stopwatch') {
                       icon = LucideIcons.timer300; // Next is Countdown
                     } else if (controller.currentGameMode.value == 'countdown') {
                       icon = LucideIcons.trophy300; // Next is Leaderboard
                     } else { // leaderboard
                       icon = LucideIcons.clock300; // Next is Stopwatch
                     }
                     return RotatedBox(
                       quarterTurns: 1,
                       child: JHGIconButton(
                         enabled: !controller.isStart,
                         iconData: icon,
                         tooltipMsg: controller.isStart ? "Cannot change mode during game" : "",
                         onTap: () {
                           if (!controller.isStart) {
                             controller.cycleGameMode();
                           }
                         },
                       ),
                     );
                   }
                 ),
                // Settings Icon
                RotatedBox(
                  quarterTurns: 1,
                  child: JHGIconButton(
                    enabled: controller.currentGameMode.value != 'leaderboard',
                    iconData: LucideIcons.settings300,
                    iconColor: controller.currentGameMode.value == 'leaderboard'
                        ? JHGColors.whiteGrey
                        : JHGColors.white,
                    tooltipMsg: controller.currentGameMode.value == 'leaderboard' ? "Settings disabled in Leaderboard mode" : "",
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
                 // Rotate Icon
                RotatedBox(
                  quarterTurns: 1,
                  child: JHGIconButton(
                      enabled: true,
                      childPadding: EdgeInsets.all(1),
                      iconData: LucideIcons.ratio300,
                      onTap: () {
                        controller.toggleOrientation();
                      }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}