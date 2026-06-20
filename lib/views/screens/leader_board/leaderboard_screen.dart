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
  LeadershipScreen({this.intervalType, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LeaderBoardController>();
    return Scaffold(
      backgroundColor: JHGColors.secondryBlack,
      body: GetBuilder<LeaderBoardController>(builder: (con) {
        if (!kIsWeb) return LeaderPortraitView(controller: controller);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 568),
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
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ─── TOP NAV ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 44, width: 44,
                  decoration: BoxDecoration(
                    color: JHGColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: JHGColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(LucideIcons.trophy300, color: JHGColors.primary, size: 20),
                ),
                Text('Leaderboard',
                    style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 44),
              ],
            ),
          ),

          // ─── CONTENT ────────────────────────────────────────────────
          Expanded(
            child: controller.isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(color: JHGColors.primary, strokeWidth: 2))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeaderCard(),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('RANKINGS',
                                  style: GoogleFonts.inter(
                                    color: Colors.white38, fontSize: 11,
                                    fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              Text(AppStrings.scoreTemp.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white38, fontSize: 11,
                                    fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        populateScoreList(controller.scoreList),
                      ],
                    ),
                  ),
          ),

          // ─── NAV BAR ────────────────────────────────────────────────
          AppNavBar(activeTab: AppTab.leaderboard, safeBottom: safeBottom),
        ],
      ),
    );
  }

  Widget _buildLeaderCard() {
    final username = controller.leader.value.username ?? '—';
    final score = controller.leader.value.score?.toString() ?? '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: JHGColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: JHGColors.primary.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: JHGColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.trophy300,
                color: JHGColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT LEADER',
                  style: GoogleFonts.inter(
                    color: JHGColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  username,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: JHGColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score,
              style: GoogleFonts.poppins(
                color: JHGColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      padding: EdgeInsets.symmetric(vertical: 24),
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
              trailingWidget: JHGIconButton(
                size: 24,
                onTap: () => Get.back(),
                iconData: LucideIcons.chevronRight300,
              ),
              bottom: leaderBoardTitleWidget(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    controller.isLoading.value
                        ? Container(
                            height: width,
                            child: Center(
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
                                  child: Row(
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
                                child: Container(
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
