import 'package:flutter/foundation.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/models/leaderboard.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';

import '../repositories/leaderboard_repo.dart';

class LeaderBoardController extends GetxController {
  RxBool isLoading = false.obs;
  RxString gameType = "fretboardtrainer".obs;
  RxString username = "user1".obs;
  int myCurrentScore = 0;
  Rx<LeaderboardData> leader = LeaderboardData().obs;

  RxList<LeaderboardData> scoreList = <LeaderboardData>[].obs;

  Future<void> getLeaderBoard() async {
    username.value = kIsWeb
        ? Get.find<HomeController>().userNameWeb.value
        : SplashScreen.session.user?.userName ?? '';
    try {
      scoreList([]);
      isLoading(true);
      var value = await getLeaderBoardApiRequest(gameType.value);
      scoreList.value = value;
      isLoading(false);
      highestScorer();
      update();
    } catch (e) {
      isLoading(false);
    }
  }

  Future<List<LeaderboardData>> getLeaderBoardApiRequest(gameType) async {
    return await LeaderboardRepo().getLeaderboardData();
  }

  String? highestScorer() {
    String? highestScorer;
    int highestScore = 0;
    myCurrentScore = scoreList
            .firstWhere(
              (p0) =>
                  p0.username ==
                  (kIsWeb
                      ? Get.find<HomeController>().userNameWeb.value
                      : username.value),
              orElse: () => LeaderboardData(),
            )
            .score ??
        0;
    for (var player in scoreList) {
      int score = player.score ?? 0;
      if (score > highestScore) {
        highestScore = score;
        leader(player);
      }
    }
    update();
    return highestScorer;
  }

  Future<dynamic> updateScore(int score) async {
    final data = LeaderboardData(
        score: score,
        username: kIsWeb
            ? Get.find<HomeController>().userNameWeb.value
            : SplashScreen.session.user?.userName ?? 'jamieharrisontest');
    print("object====score--$score  myCurrentScore===$myCurrentScore");
    if (score < myCurrentScore) {
      JHGDialogHelper.showInfoDialog(
          context: navKey.currentState!.context,
          buttonLabel: 'OK',
          title: 'Congratulations',
          description:
              'You achieved a new milestone. Your previous\'s highest score was $myCurrentScore and current score is $score');
      return;
    }
    var response = await updateScoreApiRequest(data);
    JHGDialogHelper.showInfoDialog(
        // ignore: use_build_context_synchronously
        context: navKey.currentState!.context,
        buttonLabel: 'OK',
        title: 'Congratulations',
        description:
            'You achieved a new milestone. Your leaderboard\'s updated score is $score');
    getLeaderBoard();
    return response;
  }

  static Future<dynamic> updateScoreApiRequest(LeaderboardData data) async {
    var response = await LeaderboardRepo().updateLeaderboardData(data);
    return response;
  }
}
