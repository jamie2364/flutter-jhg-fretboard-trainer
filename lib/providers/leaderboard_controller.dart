import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
// import 'package:musicgame/api/api_triggers.dart';
import 'package:reg_page/reg_page.dart';

class LeaderBoardProvider extends ChangeNotifier{
  // RxBool isLoading = false.obs;
  // RxString gameType = "Namethechord".obs;
  // RxString username = "user1".obs;
  // RxString highestUserScore = "".obs;
  // RxString highScore = "0".obs;
  //
  // RxList scoreList = [].obs;
  // ApiTriggers api = ApiTriggers();
  //
  // @override
  // void onInit() {
  //   super.onInit();
  //   getUserName();
  //   getLearderBoard();
  // }
  //
  //  getUserName()async {
  //  var usernames  =  await LocalDB.getUserName;
  //  username.value = usernames!;
  //   print("THE USER NAME IS $usernames");
  // }
  //
  // void setSelectedGame(String? selectedgameType) {
  //   if (selectedgameType == "Chords") {
  //     gameType.value = "Namethechord";
  //   } else if (selectedgameType == "Scales") {
  //     gameType.value = "Namethescale";
  //   } else if (selectedgameType == "Intervals") {
  //     gameType.value = "Nametheinterval";
  //   } else if (selectedgameType == "Chord Tones") {
  //     gameType.value = "Namethechordtone";
  //   } else if (selectedgameType == "Arpeggios") {
  //     gameType.value = "Namethearpeggio";
  //   } else if (selectedgameType == "Modes") {
  //     gameType.value = "Namethemode";
  //   }
  //   update();
  // }
  //
  // Future<dynamic> getLearderBoard() async {
  //   scoreList([]);
  //   isLoading(true);
  //   scoreList.value = await api.getLearderBoard(gameType);
  //   isLoading(false);
  //   await highestScorer(scoreList);
  //   update();
  //   return scoreList;
  // }
  //
  // Future<dynamic> highestScorer(leaderboard) async {
  //   String? highestScorer;
  //   int highestScore = 0; // Initialize to the lowest possible value
  //
  //   for (var player in leaderboard) {
  //     String username = player['username'];
  //     int score = player['score'];
  //
  //     if (score > highestScore) {
  //       highestScore = score;
  //       highestScorer = username;
  //     }
  //   }
  //
  //   if (highestScorer != null) {
  //     highestUserScore.value = highestScorer.toString();
  //     highScore.value = highestScore.toString();
  //     print(
  //         "The user with the highest score is $highestScorer with a score of $highestScore");
  //   } else {
  //     print("No user with a positive score found in the leaderboard.");
  //   }
  //   update();
  //   return highestScorer;
  // }
  //
  // Future<dynamic> updateScore(score) async {
  //   var response = await api.updateScore(gameType.value, username.value, score);
  //   return response;
  // }
}
