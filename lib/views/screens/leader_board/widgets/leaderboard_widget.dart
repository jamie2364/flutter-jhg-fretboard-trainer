import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
import 'package:fretboard/models/leaderboard.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

final ScrollController _scrollController = ScrollController();

Widget populateScoreList(List<LeaderboardData> leaderboardData) {
  return Column(
    children: [
      ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: leaderboardData.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final data = leaderboardData[index];
          final rank = index + 1;
          final isTop3 = rank <= 3;

          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isTop3
                  ? JHGColors.primary.withValues(alpha: 0.07)
                  : const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(14),
              border: isTop3
                  ? Border.all(
                      color: JHGColors.primary.withValues(alpha: 0.25))
                  : null,
            ),
            child: Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isTop3
                        ? JHGColors.primary.withValues(alpha: 0.2)
                        : const Color(0xFF1E1E1E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: GoogleFonts.poppins(
                        color: isTop3 ? JHGColors.primary : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Username
                Expanded(
                  child: Text(
                    data.username ?? '',
                    style: GoogleFonts.poppins(
                      color: isTop3 ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: isTop3 ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTop3
                        ? JHGColors.primary.withValues(alpha: 0.15)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.score.toString(),
                    style: GoogleFonts.poppins(
                      color: isTop3 ? JHGColors.primary : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      leaderBoardButton(),
    ],
  );
}

Widget leaderBoardTextWidget(String text1, String text2) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: (() {
        try {
          double.parse(text2);
          return CrossAxisAlignment.center;
        } catch (e) {
          return CrossAxisAlignment.start;
        }
      })(),
      children: [
        Text(
          text1,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          text2,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget leaderBoardButton() {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: GestureDetector(
      onTap: () => Get.find<LeaderBoardController>().getLeaderBoard(),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          AppStrings.loadMore,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

Widget leaderBoardTitleWidget() {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      AppStrings.titleLeaderBoardTitle,
      style: GoogleFonts.poppins(
        color: JHGColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
