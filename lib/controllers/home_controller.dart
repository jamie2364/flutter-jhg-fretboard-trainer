import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/services/local_db_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
// import 'package:universal_html/html.dart'; // Keep commented if not needed elsewhere

import 'leaderboard_controller.dart';

class HomeController extends GetxController {
  var userNameWeb = 'DefaultUserName'.obs;

  List<String> defaultTimer = ['Stopwatch', "Countdown"]; // Index 0: Stopwatch, Index 1: Countdown
  RxString selectedDropDownValue = "".obs; // For dropdown UI
  RxString defaultTimerSelectedValue = "Stopwatch".obs; // For saving preference

  // ** Replaced booleans with a single mode state **
  RxString currentGameMode = 'stopwatch'.obs; // 'stopwatch', 'countdown', 'leaderboard'

  void onDefaultTimerInitialized() {
    initLocalDbData().then((_) {
      selectedDropDownValue.value = defaultTimerSelectedValue.value;
      // Set initial currentGameMode based on saved default
      currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' ? 'countdown' : 'stopwatch';
      resetTimer(); // Apply initial time
    });
  }

  var isActive = true;
  final player = AudioPlayer();
  int? selectedFret;
  String? selectedNote;
  int? selectedString;
  String? userName;

  RxInt timerIntervalValue = 120.obs; // Default to 120 seconds (2:00) for Countdown

  JHGInterstitialAd? interstitialAds;
  RxBool isExpanded = RxBool(false);

  getUserName() async {
    userName = await LocalDB.getUserName;
  }

  void updateIsExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  Future<void> initializeData() async {
    selectedColor = Colors.transparent;
    isStart = false;
    selectedFret = null;
    selectedString = null;
    selectedNote = null;
    highlightFret = null;
    highlightString = null;
    highlightNode = null;
    previousHighlightFret = null;
    previousHighlightNode = null;
    score = 0;
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    secondsRemaining.value = 0;
    // Load saved settings first
    await initLocalDbData();
    // Set current game mode based on loaded default preference
    currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' ? 'countdown' : 'stopwatch';
    resetTimer(); // Apply the time for the initial mode
    await getUserName();
    update();
  }

  bool isPlayed = false;

  Future<void> playSound(int index, String note, int str, String tune) async {
    isPlayed = false;
    player.stop();
    final boardModel = fretList.firstWhereOrNull(
        (element) => element.note == note && element.string == str);
    if (boardModel != null) {
      if (!isPlayed) {
        final stringStatus = getStringStatus(boardModel.string!);
        if (stringStatus == true && isStart == true) {
          selectedFret = index;
          selectedString = str;
          selectedNote = note;
          boardModel.playSound();
          if (highlightNode == selectedNote &&
              selectedString == highlightString) {
            previousHighlightFret = highlightFret;
            previousHighlightNode = highlightNode;
            incrementScore();
            highLightTheGame();
            Future.delayed(Duration(milliseconds: 300), () {
              selectedFret = null;
              selectedColor = Colors.transparent;
              update();
            });
          } else {
            decrementScore();
          }
          update();
        } else {
          boardModel.playSound();
        }
      }
    }
  }

  double scale = 1;
  bool isPortrait = true;

  void toggleOrientation() {
    scale = 0.5;
    Future.delayed(const Duration(milliseconds: 100), () {
      isPortrait = !isPortrait;
      update();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      scale = 1;
      update();
    });
  }

  int score = 0;

  void incrementScore() {
    score = score + 1;
    isPlayed = true;
    selectedColor = JHGColors.green;
    update();
  }

  void decrementScore() {
    score = score - 1;
    isPlayed = true;
    selectedColor = JHGColors.primary;
    update();
  }

  // ** Removed setGameMode **

  bool isStart = false;
  int? highlightFret;
  int? highlightString;
  String? highlightNode;
  String? previousHighlightNode;
  int? previousHighlightFret;
  Color? selectedColor;

  void highLightTheGame() {
    int randomIndex = getRandomIndex();
    highlightFret = randomIndex;
    highlightNode = fretList[randomIndex].note;
    highlightString = fretList[randomIndex].string;
    update();
  }

  int getRandomIndex() {
    Random random = Random();
    int randomIndex;
    do {
      randomIndex = random.nextInt(fretList.length);
    } while (getStringStatus(fretList[randomIndex].string!) == false);
    return randomIndex;
  }

  void startTheGame() {
    isStart = true;
    int randomIndex = getRandomIndex();
    highlightFret = randomIndex;
    previousHighlightFret = highlightFret;
    previousHighlightNode = highlightNode;
    highlightNode = fretList[randomIndex].note;
    highlightString = fretList[randomIndex].string;
    update();
  }

  Timer? timer;

  void resetGame(bool resetAll) {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    isStart = false;
    selectedFret = null;
    selectedString = null;
    selectedNote = null;
    highlightFret = null;
    highlightString = null;
    highlightNode = null;
    previousHighlightFret = null;
    previousHighlightNode = null;
    score = 0;

    if (resetAll) {
      // If resetting everything, revert to the saved default mode
      currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' ? 'countdown' : 'stopwatch';
    }
    // Keep the current mode if resetAll is false

    resetTimer(); // Apply correct time based on current mode
    update();
  }

  // ** Updated resetTimer **
  void resetTimer() {
    if (currentGameMode.value == 'leaderboard') {
      secondsRemaining.value = 120;
    } else if (currentGameMode.value == 'countdown') {
      secondsRemaining.value = timerIntervalValue.value;
    } else { // stopwatch
      secondsRemaining.value = 0;
    }
    update();
  }

  // ** Updated startTimer **
  void startTimer() {
    debugLog('debug timer Started - Mode: ${currentGameMode.value}');
    if (currentGameMode.value == 'leaderboard') {
      offString = [true, true, true, true, true, true];
      string1 = true;
      string2 = true;
      string3 = true;
      string4 = true;
      string5 = true;
      string6 = true;
      notifyChildrens(); // Assuming this updates UI related to strings
      startLeaderBoardCountDownTimer();
    } else if (currentGameMode.value == 'countdown') {
      startCountDownTimer();
    } else { // stopwatch
      startCountUpTimer();
    }
  }

  // ** New function to cycle modes **
  void cycleGameMode() {
    if (currentGameMode.value == 'stopwatch') {
      currentGameMode.value = 'countdown';
    } else if (currentGameMode.value == 'countdown') {
      currentGameMode.value = 'leaderboard';
    } else { // leaderboard
      currentGameMode.value = 'stopwatch';
    }
    resetTimer(); // Set the correct time for the new mode
    update(); // Update UI to reflect new mode icon etc.
  }


  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool getStringStatus(int id) { /* ... unchanged ... */ return false; }
  List offString = [true, true, true, true, true, true];
  bool string1 = true;
  void setString1(int index) { /* ... */ }
  bool string2 = true;
  void setString2(int index) { /* ... */ }
  bool string3 = true;
  void setString3(int index) { /* ... */ }
  bool string4 = true;
  void setString4(int index) { /* ... */ }
  bool string5 = true;
  void setString5(int index) { /* ... */ }
  bool string6 = true;
  void setString6(int index) { /* ... */ }

  Rx<int> secondsRemaining = Rx(0); // This is the RUNTIME timer value

  void startLeaderBoardCountDownTimer() { /* ... unchanged ... */ }
  void startCountDownTimer() { /* ... unchanged ... */ }
  void startCountUpTimer() { /* ... unchanged ... */ }

  void onClickSave(BuildContext context) async {
    int seconds = timerIntervalValue.value;
    saveStrings();

    await SharedPrefHelper.instance
        .storeDefaultTimerType(defaultTimerSelectedValue.value);
    // Only save interval time if Countdown was the selected *default*
    // Or save it always, so it remembers the last setting for countdown? Let's save always.
    await SharedPrefHelper.instance.storeTimerInterval(seconds);

    popup(context);
  }

  Future<void> saveStrings() async { /* ... unchanged ... */ }

  void popup(BuildContext context) {
     // Apply potentially newly saved settings to the current state
    currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' ? 'countdown' : 'stopwatch';
    resetTimer();
    Get.back();
  }

  void getUserNameFromRL() async { /* ... unchanged ... */ }

  Future<void> initLocalDbData() async {
    defaultTimerSelectedValue.value = await SharedPrefHelper.instance.getDefaultTimerType() ?? 'Stopwatch';
    timerIntervalValue.value = await SharedPrefHelper.instance.getTimerInterval();
    string1 = await SharedPrefHelper.instance.getString1();
    string2 = await SharedPrefHelper.instance.getString2();
    string3 = await SharedPrefHelper.instance.getString3();
    string4 = await SharedPrefHelper.instance.getString4();
    string5 = await SharedPrefHelper.instance.getString5();
    string6 = await SharedPrefHelper.instance.getString6();
    selectedDropDownValue.value = defaultTimerSelectedValue.value;
    // Don't call resetTimer here anymore, it's called after initLocalDbData in initializeData and onDefaultTimerInitialized
  }
}