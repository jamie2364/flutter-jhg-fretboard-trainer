import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
import 'package:fretboard/models/leaderboard.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/leader_board/widgets/leaderboard_content.dart';
import 'package:get/get.dart';

Widget populateScoreList(List<LeaderboardData> leaderboardData) {
  final controller = Get.find<LeaderBoardController>();
  final me = controller.username.value;
  final entries = leaderboardData
      .map((d) => LbEntry(
            d.username ?? '',
            (d.score ?? 0).toString(),
            isMe: me.isNotEmpty && d.username == me,
          ))
      .toList();

  return LeaderboardContent(
    entries: entries,
    primary: JhgTokens.dark().accent,
    scoreLabel: AppStrings.scoreTemp.toUpperCase(),
    refreshLabel: AppStrings.loadMore,
    onRefresh: controller.getLeaderBoard,
  );
}

Widget leaderBoardTitleWidget() {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      AppStrings.titleLeaderBoardTitle,
      style: JhgFonts.poppins(
        color: JhgTokens.dark().accent,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
