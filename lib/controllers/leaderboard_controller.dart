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

  /// The signed-in player's username (web reads from the home controller,
  /// native from the reg_page session). Empty when nobody is signed in.
  String get _currentUser => kIsWeb
      ? Get.find<HomeController>().userNameWeb.value
      : (SplashScreen.session.user?.userName ?? '');

  Future<void> getLeaderBoard() async {
    username.value = _currentUser;
    try {
      scoreList([]);
      isLoading(true);
      var value = await getLeaderBoardApiRequest(gameType.value);
      // Rank highest score first. Never trust the backend to pre-sort — the
      // list is rendered by index, so an unsorted response would mis-rank
      // everyone and hand the medals to the wrong players.
      value.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
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
              (p0) => p0.username == _currentUser,
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
    final currentUser = _currentUser;
    // Never post to the global board as an anonymous/placeholder user — that
    // leaks bogus rows (previously submitted as "jamieharrisontest").
    if (currentUser.isEmpty) return null;

    // Only push a genuine new personal best; don't overwrite a higher score.
    if (score <= myCurrentScore) {
      JHGDialogHelper.showInfoDialog(
          context: navKey.currentState!.context,
          buttonLabel: 'OK',
          title: 'Nice try!',
          description:
              'Your best on the leaderboard is still $myCurrentScore. You scored $score this round, so keep at it.');
      return null;
    }

    final data = LeaderboardData(score: score, username: currentUser);
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
