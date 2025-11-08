// controllers/home_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/services/local_db_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:reg_page/reg_page.dart';
import 'package:universal_html/html.dart' as html;

import 'leaderboard_controller.dart';

class HomeController extends GetxController {
  var userNameWeb = 'DefaultUserName'.obs;

  List<String> defaultTimer = ['Stopwatch', "Countdown"];
  RxString selectedDropDownValue = "".obs;
  RxString defaultTimerSelectedValue = "Stopwatch".obs;

  // Using single mode state as in new code
  RxString currentGameMode = 'stopwatch'.obs;

  void onDefaultTimerInitialized() {
    selectedDropDownValue.value = defaultTimerSelectedValue.value;
    timerIntervalValue.value = 1; // Fixed: Reset to 1 as in old code
    minutesValue.value = 2;
  }

  var isActive = true;
  final player = AudioPlayer();
  int? selectedFret;
  String? selectedNote;
  int? selectedString;
  String? userName;

  RxBool timerIntervalExpanded = false.obs;
  RxInt timerIntervalValue = 1.obs; // Fixed: Changed back to 1 from 120
  RxInt minutesValue = 2.obs;

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
    timer = null;
    secondsRemaining.value = 0;
    
    await initLocalDbData();
    currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' 
        ? 'countdown' 
        : 'stopwatch';
    resetTimer();
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

  // FIXED: Restored the working do-while loop from old code
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
  Rx<int> secondsRemaining = Rx(0);

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
      currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' 
          ? 'countdown' 
          : 'stopwatch';
    }
    
    resetTimer();
    update();
  }

  void resetTimer() {
    if (currentGameMode.value == 'countdown') {
      secondsRemaining.value = 60 * minutesValue.value;
    } else if (currentGameMode.value == 'leaderboard') {
      secondsRemaining.value = 120;
    } else {
      secondsRemaining.value = 0;
    }
    update();
  }

  void startTimer() {
    debugLog('debug timer Started - Mode: ${currentGameMode.value}');
    if (currentGameMode.value == 'countdown') {
      startCountDownTimer();
    } else if (currentGameMode.value == 'leaderboard') {
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

  void cycleGameMode() {
    if (currentGameMode.value == 'stopwatch') {
      currentGameMode.value = 'countdown';
    } else if (currentGameMode.value == 'countdown') {
      currentGameMode.value = 'leaderboard';
    } else {
      currentGameMode.value = 'stopwatch';
    }
    resetTimer();
    update();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // FIXED: Restored the working getStringStatus method from old code
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

  void startLeaderBoardCountDownTimer() {
    if (secondsRemaining.value == 0) {
      secondsRemaining.value = 120;
    }
    update();
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
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
    update();
    if (timer != null) {
      timer!.cancel();
    }
    int elapsed = 0;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      totalSeconds--;

      if (elapsed % interval == 0) {
        secondsRemaining.value -= interval;
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
      SharedPrefHelper.instance.storeDefaultTimerType(defaultTimerSelectedValue.value);
      SharedPrefHelper.instance.storeTimerInterval(seconds);
      SharedPrefHelper.instance.storeDefaultTimerMinutes(minutes);
      popup(context);
    } else {
      SharedPrefHelper.instance.storeDefaultTimerType(defaultTimerSelectedValue.value);
      popup(context);
    }
  }

  Future<void> saveStrings() async {
    await SharedPrefHelper.instance.saveStrings(
        string1, string2, string3, string4, string5, string6);
  }

  void popup(BuildContext context) {
    currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown' 
        ? 'countdown' 
        : 'stopwatch';
    resetTimer();
    Get.back();
  }

  void getUserNameFromRL() async {
    try {
      var uri = Uri.parse(html.window.location.href);
      userNameWeb.value = uri.queryParameters['username'].toString();
      isActive = bool.parse(uri.queryParameters['active'].toString());
      update();
    } on Exception {
      if (userNameWeb.value == "null") {
        userNameWeb.value = "DefaultUserName";
      }
    }
  }

  Future<void> initLocalDbData() async {
    defaultTimerSelectedValue.value = 
        await SharedPrefHelper.instance.getDefaultTimerType() ?? 'Stopwatch';
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