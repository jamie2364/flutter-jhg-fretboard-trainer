import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
// import 'package:fretboard/utils/app_assets.dart'; // No longer needed for icons here
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
    // Define a consistent size for the icon buttons
    const double iconButtonSize = 36.0; // Adjusted size for potentially better fit

    return AnimatedScale(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linearToEaseOut,
      scale: 1, // Using controller scale might cause unwanted effects
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TROPHY AND Timer ICON
          Container(
            height: iconButtonSize + 8, // Adjust container height based on button size + padding
            //color: Colors.amber, // Debug color
            child: Padding(
              padding: EdgeInsets.only(
                left: width * 0.08,
                right: width * 0.1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center, // Center icons vertically
                children: [
                  // Top-left icon area (Reset/Timer/Stopwatch/Trophy)
                   SizedBox(
                     height: iconButtonSize,
                     width: iconButtonSize,
                     child: controller.isStart == true
                         ? JHGResetBtn(
                             onTap: () {
                               controller.setGameMode(
                                   timer: false, leaderboard: false);
                               controller.resetGame(false);
                             },
                             enabled: true, // Assuming enabled when visible
                           )
                         : controller.timerMode == false &&
                                 controller.leaderboardMode == false
                             ? RotatedBox(
                                 quarterTurns: 1, // Rotate Stopwatch icon
                                 child: JHGIconButton(
                                     enabled: true,
                                     iconData: LucideIcons.timer300, // Stopwatch icon
                                     onTap: () {
                                       controller.setGameMode(
                                           timer: true, leaderboard: false);
                                       controller.resetTimer();
                                     }),
                               )
                             : controller.timerMode == true
                                 ? SizedBox( // Wrap in SizedBox for explicit sizing
                                      height: iconButtonSize,
                                      width: iconButtonSize,
                                      child: JHGIconButton(
                                        enabled: true,
                                        iconData: LucideIcons.clock300, // Timer/Clock icon (already rotates by default?)
                                        onTap: () {
                                          controller.setGameMode(
                                              timer: false, leaderboard: true);
                                          controller.resetTimer();
                                        }))
                                 : controller.leaderboardMode == true
                                     ? RotatedBox( // Rotate Trophy icon
                                         quarterTurns: 1,
                                         child: JHGIconButton(
                                             enabled: true,
                                             iconData: LucideIcons.trophy300, // Trophy icon
                                             onTap: () {
                                               controller.setGameMode(
                                                   timer: false,
                                                   leaderboard: false);
                                               controller.resetTimer();
                                             }),
                                       )
                                     : SizedBox(), // Fallback
                   ),
                  // Top-right icon (Leadership Screen)
                  SizedBox( // Wrap in SizedBox for explicit sizing
                    height: iconButtonSize,
                    width: iconButtonSize,
                    child: RotatedBox( // Rotate Trophy icon
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
                  ),
                ],
              ),
            ),
          ),

          //SPACER
          SizedBox(
            height: height * 0.01, // Kept reduced space
          ),

          // BOARD AREA
          Expanded(
              child: Container(
             // Removed fixed height, let Expanded handle it
            child: Row(
             crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically center
              children: [
                // START BUTTON / SCORE & NOTE AREA
                 Container( // Container to hold rotated items
                   width: width * 0.12, // Allocate some width
                   padding: EdgeInsets.only(left: width * 0.01), // Add slight left padding if needed
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       controller.isStart == true
                           ? Expanded( // Allow score/note to take space
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   RotatedBox(
                                     quarterTurns: 1,
                                     child: Row(
                                       mainAxisSize: MainAxisSize.min, // Prevent excessive width
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       children: [
                                         Text(
                                           AppStrings.scoreText,
                                           style: JHGTextStyles.labelStyle.copyWith(
                                             fontSize: 16,
                                           ),
                                         ),
                                         SizedBox(width: 5), // Space between label and score
                                         Text(
                                           controller.score.toString(),
                                           style: JHGTextStyles.labelStyle.copyWith(
                                             fontSize: 16,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                   SizedBox(height: 15), // Space between score and note
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
                               child: Column( // Keep button and text together
                                mainAxisSize: MainAxisSize.min,
                                 children: [
                                   JHGPrimaryBtn(
                                     label: AppStrings.start,
                                     height: 50,
                                     width: width * 0.40, // Adjust width as needed
                                     onPressed: () {
                                       controller.startTimer();
                                       controller.startTheGame();
                                     },
                                   ),
                                    SizedBox(height: controller.leaderboardMode ? 8 : 14),
                                    if(controller.leaderboardMode)
                                        Text(
                                         'You can\'t change settings in leaderboard',
                                         textAlign: TextAlign.center,
                                         style: TextStyle(
                                           color: JHGColors.primary.withOpacity(0.8),
                                           fontSize: 12, // Smaller font size
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
                  flex: 1, // Keep flex 1 for timer
                  child: Center( // Center the timer widget
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: CountTimerWidget()
                    ),
                  ),
                ),


                // GUITAR BOARD AREA
                Expanded(
                  flex: 4, // Increased flex for guitar board (was 3)
                  child: IgnorePointer(
                    ignoring: !controller.isStart,
                    child: Container(
                      alignment: Alignment.center, // Center the board
                       // Add some padding on the right side of the board if needed
                       padding: EdgeInsets.only(right: width * 0.02),
                      child: const GuitarBoard(
                        isPortrait: false,
                      ),
                    ),
                  ),
                ),
                 // Removed SizedBox(width: width * 0.05) which likely caused overflow
                 // SizedBox(width: width * 0.05),
              ],
            ),
          )),

          //SPACER
          SizedBox(
            height: height * 0.01, // Kept reduced space
          ),

          // BOTTOM ICON ROW
          Container(
             height: iconButtonSize + 8, // Match top container height
            child: Padding(
              padding: EdgeInsets.only(
                left: width * 0.1,
                right: width * 0.08,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center, // Center icons vertically
                children: [
                   // Rotate Icon
                  SizedBox( // Wrap in SizedBox for explicit sizing
                    height: iconButtonSize,
                    width: iconButtonSize,
                    child: RotatedBox( // Rotate the icon
                      quarterTurns: 1,
                      child: JHGIconButton(
                          enabled: true,
                          childPadding: EdgeInsets.all(1),
                          iconData: LucideIcons.ratio300, // Rotate icon
                          onTap: () {
                            controller.toggleOrientation();
                          }),
                    ),
                  ),
                  // Settings Icon
                  SizedBox( // Wrap in SizedBox for explicit sizing
                    height: iconButtonSize,
                    width: iconButtonSize,
                    child: RotatedBox( // Rotate the icon
                      quarterTurns: 1,
                      child: JHGIconButton(
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
                          }
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
           SizedBox(height: height * 0.01), // Small bottom padding
        ],
      ),
    );
  }
}