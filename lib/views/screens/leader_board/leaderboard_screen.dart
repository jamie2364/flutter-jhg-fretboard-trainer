import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
import 'package:fretboard/utils/app_assets.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/leader_board/widgets/leaderboard_widget.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LeadershipScreen extends StatelessWidget {
  final String? intervalType;
  const LeadershipScreen({this.intervalType, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LeaderBoardController>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: GetBuilder<LeaderBoardController>(builder: (con) {
        if (!kIsWeb) return LeaderPortraitView(controller: controller);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: LeaderPortraitView(controller: controller),
          ),
        );
      }),
    );
  }
}

class LeaderPortraitView extends StatelessWidget {
  const LeaderPortraitView({super.key, required this.controller});
  final LeaderBoardController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ─── TOP NAV ────────────────────────────────────────────────
          // Pushed from the Stats hub tile, so it is a detail screen and gets
          // the canonical back chip.
          JhgScreenHeader.detail(
            title: 'Leaderboard',
            onBack: () => Get.back<void>(),
          ),

          // ─── CONTENT ────────────────────────────────────────────────
          Expanded(
            child: controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(color: JHGColors.primary, strokeWidth: 2))
                : controller.scoreList.isEmpty
                    ? const _EmptyLeaderboard()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: populateScoreList(controller.scoreList),
                      ),
          ),

          // ─── NAV BAR ────────────────────────────────────────────────
          const AppNavBar(activeTab: AppTab.heatmap),
        ],
      ),
    );
  }

}

/// Shown when the board has no scores yet.
class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.trophy,
              color: Colors.white.withValues(alpha: 0.25), size: 40),
          const SizedBox(height: 12),
          Text(
            'No scores yet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Play a round to claim the top spot',
            style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }
}

class LeaderLandscapeView extends StatelessWidget {
  const LeaderLandscapeView({super.key, required this.controller});
  final LeaderBoardController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return JHGBody(
      padding: const EdgeInsets.symmetric(vertical: 24),
      body: RotatedBox(
        quarterTurns: 1,
        child: Column(
          children: [
            JHGAppBar(
              autoImplyLeading: false,
              centerWidget: SvgPicture.asset(
                AppAssets.svg_trophyIcon,
                height: 8.w,
                width: 8.w,
              ),
              trailingWidget: JhgIconChipButton.header(
                icon: LucideIcons.chevronRight,
                onTap: () => Get.back(),
              ),
              bottom: leaderBoardTitleWidget(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    controller.isLoading.value
                        ? SizedBox(
                            height: width,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: JHGColors.primary,
                              ),
                            ))
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 20.dp,
                                    left: 10.0.dp,
                                    right: 10.0.dp),
                                child: Container(
                                  width: 80.w,
                                  height: 10.h,
                                  padding: EdgeInsets.only(
                                      left: 15.dp, right: 15.dp),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    border: Border.all(
                                      color: JHGColors.charcolGray,
                                    ),
                                    color: JHGColors.charcolGray,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 20.dp,
                                    left: 10.0.dp,
                                    right: 10.0.dp),
                                child: SizedBox(
                                  width: 80.w,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 30.dp),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AppStrings.user,
                                              style:
                                                  JHGTextStyles.subLabelStyle,
                                            ),
                                            Text(
                                              AppStrings.scoreTemp,
                                              style:
                                                  JHGTextStyles.subLabelStyle,
                                            )
                                          ],
                                        ),
                                      ),
                                      populateScoreList(controller.scoreList),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderWebView extends StatelessWidget {
  const LeaderWebView({super.key, required this.controller});
  final LeaderBoardController controller;

  @override
  Widget build(BuildContext context) {
    return LeaderPortraitView(controller: controller);
  }
}
