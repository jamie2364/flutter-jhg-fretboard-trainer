import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/services/local_db_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
import 'package:universal_html/html.dart';

import 'leaderboard_controller.dart';

class HomeController extends GetxController {
  // disable the web active status is true
  var userNameWeb = 'DefaultUserName';

  List<String> defaultTimer = ['Stopwatch', "Countdown"];
  RxString selectedDropDownValue = "".obs;

  void onDefaultTimerInitialized() {
    selectedDropDownValue.value = "Stopwatch";
    timerIntervalValue.value = 10;
    minutesValue.value = 2;
  }

  var isActive = true;

  // Instance of the Player
  final player = AudioPlayer();
  int? selectedFret;
  String? selectedNote;
  int? selectedString;
  String? userName;

  RxBool timerIntervalExpanded = false.obs;
  RxInt timerIntervalValue = 10.obs;
  RxInt minutesValue = 2.obs;

  RxString defaultTimerSelectedValue = "Stopwatch".obs;

  // JHGInterstitialAd? interstitialAd;
  JHGInterstitialAd? interstitialAds;
  RxBool isExpanded = RxBool(false);

  getUserName() async {
    userName = await LocalDB.getUserName;
  }

  void updateIsExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  // Initialize  animation controller
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
    timer = null;
    //isTimerSet = false;
    secondsRemaining.value = 0;
    timerMode = false;
    leaderboardMode = false;
    initLocalDbData();
    await getUserName();
    update();
  }

  // PLAY SOUND ACCORDING TO SELECTED NOTES , STRING AND FRET

  bool isPlayed = false;

  Future<void> playSound(int index, String note, int str, String tune) async {
    isPlayed = false;
    player.stop();
    // EXECUTE LOOP
    fretList.forEach((element) async {
      // if(element.id == index){
      if (element.note == note && element.string == str && isPlayed == false) {
        // GET ALLOW STRING STATUS
        final stringStatus = getStringStatus(element.string!);

        // CHECK IF THE STATUS IS TRUE AND GAME IS START
        // THEN WE WILL HIGHLIGHT THINGS
        if (stringStatus == true && isStart == true) {
          selectedFret = index;
          selectedString = str;
          selectedNote = note;
          element.playSound();
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
          element.playSound();
        }
        return;
      }
    });
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

  // SCORE
  // Correct  and Incorrect
  // Correct increment , incorrect decrement
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

  //Modes

  bool timerMode = false;
  bool leaderboardMode = false;

  void setGameMode({required bool timer, required bool leaderboard}) {
    timerMode = timer;
    leaderboardMode = leaderboard;
    update();
  }

  // START THE GAME
  // SELECT AND HIGHLIGHT STRING, FRET AND NOTE

  bool isStart = false;
  int? highlightFret;
  int? highlightString;
  String? highlightNode;
  String? previousHighlightNode;
  int? previousHighlightFret;
  Color? selectedColor;

  // WHEN PRESS CORRECT NOTE THEN HIGHLIGHT ANOTHER ONE TO SELECT
  void highLightTheGame() {
    // Get randomly highlight node
    int randomIndex = getRandomIndex();
    highlightFret = randomIndex;
    highlightNode = fretList[randomIndex].note;
    highlightString = fretList[randomIndex].string;

    // print("===================================");
    // print("Highlight Freth ===>  : $randomIndex");
    // print("highlightNode====>  : $highlightNode");
    // print("highlightString=====>  : $highlightString");

    update();
  }

// GET RANDOM INDEX ACCORDING TO  ALLOW STRING
  int getRandomIndex() {
    Random random = Random();
    int randomIndex;
    do {
      randomIndex = random.nextInt(fretList.length);
    } while (getStringStatus(fretList[randomIndex].string!) == false);
    return randomIndex;
  }

  // START THE GAME ON START BUTTON
  void startTheGame() {
    isStart = true;
    int randomIndex = getRandomIndex();
    highlightFret = randomIndex;
    previousHighlightFret = highlightFret;
    previousHighlightNode = highlightNode;
    highlightNode = fretList[randomIndex].note;
    highlightString = fretList[randomIndex].string;

    // print("===================================");
    // print("Highlight Freth : $randomIndex");
    // print("PreviousHighlightFret Freth : $previousHighlightFret");
    // print("previousHighlightNode  : $previousHighlightNode");
    // print("highlightNode  : $highlightNode");
    // print("highlightString  : $highlightString");

    update();
  }

// TIMER

  // int secondsRemaining = 0; // Initial countdown time in seconds
  Timer? timer;

  // bool isTimerSet = false;

  void increaseTime() {
    if (isStart != true) {
      secondsRemaining.value =
          secondsRemaining.value + timerIntervalValue.value;
      update();
    }
  }

  void decreaseTime() {
    if (secondsRemaining.value > 10 && isStart != true) {
      secondsRemaining.value =
          secondsRemaining.value - timerIntervalValue.value;
      update();
    }
  }

  void resetGame(bool resetAll) {
    if (timer != null) {
      timer!.cancel();
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
    secondsRemaining.value = 0;
    // isTimerSet = false;
    timer = null;

    if (resetAll == true) {
      if (timerMode == true) {
        timerMode = false;
      } else if (leaderboardMode == true) {
        leaderboardMode = false;
      }
    }
    update();

    resetTimer();
  }

  void resetTimer() {
    //isTimerSet = true;
    if (timerMode == true) {
      secondsRemaining.value = 60 * minutesValue.value;
    } else if (leaderboardMode == true) {
      secondsRemaining.value = 120;
    } else {
      secondsRemaining.value = 0;
    }
    update();
  }

  void startTimer() {
    debugLog('debug timer Started');
    if (timerMode == true) {
      startCountDownTimer();
    } else if (leaderboardMode == true) {
      offString = [true, true, true, true, true, true];
      string1 = true;
      string2 = true;
      string3 = true;
      string4 = true;
      string5 = true;
      string6 = true;
      notifyChildrens();
      startLeaderBoardCountDownTimer();
    } else {
      startCountUpTimer();
    }
  }

  String formatTime(int seconds) {
    // Format the remaining time as mm:ss
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  //GET STRING STATUS WHICH STRING IS ALLOW
  bool getStringStatus(int id) {
    if (string1 == true && id == 1) {
      return true;
    } else if (string2 == true && id == 2) {
      return true;
    } else if (string3 == true && id == 3) {
      return true;
    } else if (string4 == true && id == 4) {
      return true;
    } else if (string5 == true && id == 5) {
      return true;
    } else if (string6 == true && id == 6) {
      return true;
    } else {
      return false;
    }
  }

  List offString = [true, true, true, true, true, true];

  //STRING TOGGLES
  // STRING 1
  bool string1 = true;

  void setString1(int index) {
    string1 = !string1;
    offString[index] = string1;
    if (!offString.contains(true)) {
      offString[index] = true;
      string1 = true;
    }
    update();
  }

  // STRING 2
  bool string2 = true;

  void setString2(int index) {
    string2 = !string2;
    offString[index] = string2;
    if (!offString.contains(true)) {
      offString[index] = true;
      string2 = true;
    }
    update();
  }

  // STRING 3
  bool string3 = true;

  void setString3(int index) {
    string3 = !string3;
    offString[index] = string3;
    if (!offString.contains(true)) {
      offString[index] = true;
      string3 = true;
    }
    update();
  }

  // STRING 4
  bool string4 = true;

  void setString4(int index) {
    string4 = !string4;
    offString[index] = string4;
    if (!offString.contains(true)) {
      offString[index] = true;
      string4 = true;
    }
    update();
  }

  // STRING 5
  bool string5 = true;

  void setString5(int index) {
    string5 = !string5;
    offString[index] = string5;
    if (!offString.contains(true)) {
      offString[index] = true;
      string5 = true;
    }
    update();
  }

  // STRING 6
  bool string6 = true;

  void setString6(int index) {
    string6 = !string6;
    offString[index] = string6;
    if (!offString.contains(true)) {
      offString[index] = true;
      string6 = true;
    }
    update();
  }

  // Value Notifier listener

  Rx<int> secondsRemaining = Rx(0);

  void startLeaderBoardCountDownTimer() {
    if (secondsRemaining.value == 0) {
      secondsRemaining.value = 10;
    }
    update();
    if (timer != null) {
      timer!.cancel();
    }
    // Create a timer that runs every second
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // Update the UI and decrement the remaining seconds
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
        LeaderBoardController lc = Get.find<LeaderBoardController>();
        lc.updateScore(score);
        resetGame(false);
        update();
      }
    });
  }

  void startCountDownTimer() {
    if (secondsRemaining.value == 0) {
      secondsRemaining.value = 60 * minutesValue.value;
    }
    update();
    if (timer != null) {
      timer!.cancel();
    }
    // Create a timer that runs every second
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update the UI and decrement the remaining seconds
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        // Timer expired, you can handle this case here
        timer.cancel();
        // Cancel the timer when the countdown reaches 0
        update();
        resetGame(false);
      }
    });
  }

  void startCountUpTimer() async {
    final minutes = await SharedPrefHelper.instance.getDefaultTimerMinutes();
    final interval = await SharedPrefHelper.instance.getTimerInterval();
    secondsRemaining.value = minutes * 60;
    int totalSeconds = minutes * 60;
    ;
    update();
    if (timer != null) {
      timer!.cancel();
    }
    int elapsed = 0;
    // Create a timer that runs every second
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      totalSeconds--;

      if (elapsed % interval == 0) {
        secondsRemaining.value -= interval;

        // Clamp to zero
        if (secondsRemaining.value <= 0) {
          secondsRemaining.value = 0;
          update();
          timer.cancel();
          resetGame(false);
          return;
        }

        update();
      } else if (totalSeconds <= 0) {
        timer.cancel();
        resetGame(false);
        update();
      }
    });
  }

  void onClickSave(BuildContext context) async {
    int seconds = timerIntervalValue.value;
    int minutes = minutesValue.value;
    saveStrings();
    if (defaultTimerSelectedValue.value == "Countdown") {
      SharedPrefHelper.instance
          .storeDefaultTimerType(defaultTimerSelectedValue.value);
      SharedPrefHelper.instance.storeTimerInterval(seconds);
      SharedPrefHelper.instance.storeDefaultTimerMinutes(minutes);
      popup(context);
    } else {
      SharedPrefHelper.instance
          .storeDefaultTimerType(defaultTimerSelectedValue.value);
      popup(context);
    }
  }

  Future<void> saveStrings() async {
    await SharedPrefHelper.instance
        .saveStrings(string1, string2, string3, string4, string5, string6);
  }

  void popup(BuildContext context) {
    resetTimer();
    Get.back();
  }

  void getUserNameFromRL() async {
    try {
      var uri = Uri.parse(window.location.href);
      userNameWeb = uri.queryParameters['username'].toString();
      isActive = bool.parse(uri.queryParameters['active'].toString());
      update();
    } on Exception {
      if (userNameWeb == null || userNameWeb == "null") {
        userNameWeb = "DefaultUserName";
      }
    }
  }

  Future<void> initLocalDbData() async {
    defaultTimerSelectedValue(
        await SharedPrefHelper.instance.getDefaultTimerType());
    minutesValue.value =
        await SharedPrefHelper.instance.getDefaultTimerMinutes();
    timerIntervalValue.value =
        await SharedPrefHelper.instance.getTimerInterval();
    string1 = await SharedPrefHelper.instance.getString1();
    string2 = await SharedPrefHelper.instance.getString2();
    string3 = await SharedPrefHelper.instance.getString3();
    string4 = await SharedPrefHelper.instance.getString4();
    string5 = await SharedPrefHelper.instance.getString5();
    string6 = await SharedPrefHelper.instance.getString6();
  }
}
