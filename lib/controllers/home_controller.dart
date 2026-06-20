// controllers/home_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/services/heatmap_service.dart';
import 'package:fretboard/services/local_db_service.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';
import 'package:universal_html/html.dart' as html;

import 'leaderboard_controller.dart';

class HomeController extends GetxController {
  var userNameWeb = 'DefaultUserName'.obs;

  List<String> defaultTimer = ['Stopwatch', "Countdown"];
  RxString selectedDropDownValue = "".obs;
  RxString defaultTimerSelectedValue = "Stopwatch".obs;

  // Game type ('stopwatch' | 'countdown' | 'leaderboard' | 'reverse')
  RxString currentGameMode = 'stopwatch'.obs;
  // Timer sub-mode tracked independently so identify mode keeps timer working
  // ('stopwatch' | 'countdown') — leaderboard excluded from identify mode
  RxString timerMode = 'stopwatch'.obs;

  // Reverse mode state
  List<String> reverseChoices = [];
  String? reverseSelectedNote;   // which button the user just tapped
  bool reverseWasCorrect = false; // was their tap correct

  // "STRING G · FRET 5" hint displayed in the choice panel
  String get reversePositionHint {
    if (highlightFret == null) return '';
    final bm = fretList[highlightFret!];
    const stringNames = {1: 'e', 2: 'B', 3: 'G', 4: 'D', 5: 'A', 6: 'E'};
    return 'STRING ${stringNames[bm.string] ?? bm.string}  ·  FRET ${bm.fret}';
  }

  static const List<String> _allNotes = [
    'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'
  ];

  void onDefaultTimerInitialized() {
    selectedDropDownValue.value = defaultTimerSelectedValue.value;
    if (timerIntervalValue.value <= 0) {
      timerIntervalValue.value = 1;
    }
  }

  var isActive = true;

  // Tour hooks — set by TourController, cleared on tour end.
  VoidCallback? onFretTappedDuringTour;
  VoidCallback? onAnswerSelectedDuringTour;

  int? selectedFret;
  String? selectedNote;
  int? selectedString;
  String? userName;

  RxBool timerIntervalExpanded = false.obs;
  RxInt timerIntervalValue = 1.obs; // Fixed: Changed back to 1 from 120
  RxInt minutesValue = 2.obs;

  JHGInterstitialAd? interstitialAds;
  RxBool isExpanded = RxBool(false);

  /// Controls the collapsible bottom panel on the portrait home screen.
  /// Tour steps and game-state changes drive this; the panel widget observes it.
  final isBottomPanelExpanded = true.obs;

  // ── Identify mode settings ───────────────────────────────────────────────
  bool identifyShowPositionHint = true;
  bool identifyAutoAdvance = false;
  bool identifyPlaySound = true;

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
    if (kIsWeb) {
      preloadFretSounds();
    }
    resetTimer();
    await getUserName();
    update();
  }

  bool isPlayed = false;

  Future<void> playSound(int index, String note, int str, String tune) async {
    isPlayed = false;
    final boardModel = index >= 0 && index < fretList.length
        ? fretList[index]
        : fretList.firstWhereOrNull((element) => element.fretSound == tune);
    if (boardModel != null) {
      if (!isPlayed) {
        final stringStatus = getStringStatus(boardModel.string!);
        if (stringStatus == true && isStart == true) {
          selectedFret = index;
          selectedString = str;
          selectedNote = note;
          unawaited(boardModel.playSound());
          if (highlightNode == selectedNote &&
              selectedString == highlightString) {
            if (highlightFret != null) {
              unawaited(HeatmapService.recordAttempt(highlightFret!, true));
            }
            previousHighlightFret = highlightFret;
            previousHighlightNode = highlightNode;
            incrementScore();
            highLightTheGame();
            Future.delayed(const Duration(milliseconds: 300), () {
              selectedFret = null;
              selectedColor = Colors.transparent;
              update();
            });
          } else {
            if (highlightFret != null) {
              unawaited(HeatmapService.recordAttempt(highlightFret!, false));
            }
            decrementScore();
          }
          update();
          // Notify the interactive tour that the user tapped a fret.
          onFretTappedDuringTour?.call();
        } else {
          unawaited(boardModel.playSound());
        }
      }
    }
  }

  void preloadFretSounds() {
    for (final boardModel in fretList) {
      unawaited(boardModel.preloadSound());
    }
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
  bool isPaused = false;
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
    if (currentGameMode.value == 'reverse') {
      generateReverseChoices(highlightNode!);
    }
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
    isPaused = false;
    int randomIndex = getRandomIndex();
    highlightFret = randomIndex;
    previousHighlightFret = highlightFret;
    previousHighlightNode = highlightNode;
    highlightNode = fretList[randomIndex].note;
    highlightString = fretList[randomIndex].string;
    if (currentGameMode.value == 'reverse') {
      generateReverseChoices(highlightNode!);
    }
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
    isPaused = false;
    selectedFret = null;
    selectedString = null;
    selectedNote = null;
    highlightFret = null;
    highlightString = null;
    highlightNode = null;
    previousHighlightFret = null;
    previousHighlightNode = null;
    score = 0;
    reverseChoices = [];
    reverseSelectedNote = null;
    reverseWasCorrect = false;

    if (resetAll) {
      currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown'
          ? 'countdown'
          : 'stopwatch';
    }

    resetTimer();
    update();
  }

  void resetTimer() {
    // In identify mode use timerMode; otherwise use currentGameMode
    final effective = currentGameMode.value == 'reverse'
        ? timerMode.value
        : currentGameMode.value;
    if (effective == 'countdown') {
      secondsRemaining.value =
          timerIntervalValue.value <= 0 ? 1 : timerIntervalValue.value;
    } else if (effective == 'leaderboard') {
      secondsRemaining.value = 120;
    } else {
      secondsRemaining.value = 0;
    }
    update();
  }

  void startTimer({bool resume = false}) {
    debugLog('debug timer Started - Mode: ${currentGameMode.value}');
    final effective = currentGameMode.value == 'reverse'
        ? timerMode.value
        : currentGameMode.value;
    if (effective == 'countdown') {
      startCountDownTimer();
    } else if (effective == 'leaderboard') {
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
      startCountUpTimer(resume: resume);
    }
  }

  void pauseGame() {
    timer?.cancel();
    timer = null;
    isStart = false;
    isPaused = true;
    update();
  }

  void resumeGame() {
    isStart = true;
    isPaused = false;
    if (highlightFret == null || highlightNode == null) {
      highLightTheGame();
    }
    startTimer(resume: true);
    update();
  }

  // Cycles timer modes. In identify mode only stopwatch↔countdown (no leaderboard).
  void cycleGameMode() {
    if (currentGameMode.value == 'reverse') {
      timerMode.value = timerMode.value == 'stopwatch' ? 'countdown' : 'stopwatch';
    } else {
      if (currentGameMode.value == 'stopwatch') {
        currentGameMode.value = 'countdown';
        timerMode.value = 'countdown';
      } else if (currentGameMode.value == 'countdown') {
        currentGameMode.value = 'leaderboard';
        timerMode.value = 'stopwatch'; // leaderboard excluded from identify
      } else {
        currentGameMode.value = 'stopwatch';
        timerMode.value = 'stopwatch';
      }
    }
    resetTimer();
    update();
  }

  void switchToIdentifyMode() {
    currentGameMode.value = 'reverse';
    reverseChoices = [];
    resetTimer();
    update();
  }

  void switchToFindMode() {
    currentGameMode.value = timerMode.value;
    reverseChoices = [];
    resetTimer();
    update();
  }

  void generateReverseChoices(String correctNote) {
    final others = List<String>.from(_allNotes)
      ..remove(correctNote)
      ..shuffle();
    reverseChoices = [correctNote, others[0], others[1], others[2]]..shuffle();
  }

  void selectReverseAnswer(String note) {
    if (!isStart) return;
    if (reverseSelectedNote != null) return; // block double-tap during feedback

    // Play the note so the user hears what it is (respects identifyPlaySound setting)
    if (highlightFret != null && identifyPlaySound) {
      unawaited(fretList[highlightFret!].playSound());
    }

    final isCorrect = note == highlightNode;
    reverseSelectedNote = note;
    reverseWasCorrect = isCorrect;

    if (highlightFret != null) {
      unawaited(HeatmapService.recordAttempt(highlightFret!, isCorrect));
    }

    if (isCorrect) {
      previousHighlightFret = highlightFret;
      previousHighlightNode = highlightNode;
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 600);
      Future.delayed(delay, () {
        reverseSelectedNote = null;
        reverseWasCorrect = false;
        highLightTheGame();
      });
    } else {
      decrementScore();
      // Show correct answer for longer so user can learn, then advance
      Future.delayed(const Duration(milliseconds: 1000), () {
        reverseSelectedNote = null;
        reverseWasCorrect = false;
        highLightTheGame();
      });
    }
    update();
    // Notify the interactive tour that the user selected an identify answer.
    onAnswerSelectedDuringTour?.call();
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
      secondsRemaining.value =
          timerIntervalValue.value <= 0 ? 1 : timerIntervalValue.value;
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

  void startCountUpTimer({bool resume = false}) async {
    if (!resume) {
      secondsRemaining.value = 0;
    }
    update();
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining.value++;
      update();
    });
  }

  void onClickSave(BuildContext context) async {
    await saveTimerSettings();
    Get.back();
  }

  Future<void> saveTimerSettings() async {
    int seconds = timerIntervalValue.value;
    int minutes = seconds ~/ 60;
    minutesValue.value = minutes;
    await saveStrings();
    await SharedPrefHelper.instance
        .storeDefaultTimerType(defaultTimerSelectedValue.value);
    if (defaultTimerSelectedValue.value == "Countdown") {
      await SharedPrefHelper.instance.storeTimerInterval(seconds);
      await SharedPrefHelper.instance.storeDefaultTimerMinutes(minutes);
    }
    currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown'
        ? 'countdown'
        : 'stopwatch';
    resetTimer();
  }

  Future<void> saveStrings() async {
    await SharedPrefHelper.instance
        .saveStrings(string1, string2, string3, string4, string5, string6);
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
