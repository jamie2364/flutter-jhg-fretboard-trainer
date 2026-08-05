// controllers/home_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/services/heatmap_service.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/services/chord_service.dart';
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
  // True once the user has explicitly picked Find/Identify (startup screen or
  // the top-bar switcher). Stops initializeData() from overwriting their choice.
  bool modeChosen = false;
  // Timer sub-mode tracked independently so identify mode keeps timer working
  // ('stopwatch' | 'countdown') — leaderboard excluded from identify mode
  RxString timerMode = 'stopwatch'.obs;

  // Reverse mode state
  List<String> reverseChoices = [];
  String? reverseSelectedNote;   // which button the user just tapped
  bool reverseWasCorrect = false; // was their tap correct

  // ── Interval mode state ("Name the Interval") ────────────────────────────
  // A two-note prompt is shown on the neck (root + target) and the user picks
  // the interval name. Difficulty widens how far apart the notes may sit.
  IntervalDifficulty intervalDifficulty = IntervalDifficulty.easy;
  IntervalGameType intervalGameType = IntervalGameType.name;
  IntervalPrompt? intervalPrompt;
  int? intervalRootIndex;        // fretList index of the root note
  int? intervalTargetIndex;      // fretList index of the target note (name mode)
  List<MusicInterval> intervalChoicesList = [];
  MusicInterval? intervalSelected;    // which choice the user tapped (name mode)
  bool intervalWasCorrect = false;
  bool intervalBuildDone = false;     // build mode: locks after a tap for feedback
  int? intervalBuildRevealIndex;      // build mode: correct target shown after a wrong tap

  // ── Chord mode state ("Name / Build the Chord") ──────────────────────────
  // A chord shape lights up on the neck (Name) — the user picks the symbol; or
  // a chord symbol is shown (Build) — the user taps the frets to place it.
  // Difficulty widens the chord vocabulary and how far up the neck shapes sit.
  ChordDifficulty chordDifficulty = ChordDifficulty.easy;
  ChordGameType chordGameType = ChordGameType.name;

  final ChordService _chordService = ChordService();
  ChordCatalog? _chordCatalog;
  bool chordCatalogLoading = false;

  ChordShape? chordPrompt;
  List<String> chordChoicesList = [];   // name mode: symbols to choose from
  String? chordSelected;                // name mode: which symbol was tapped
  bool chordWasCorrect = false;
  Set<int> chordTapped = {};             // build mode: fretted indices placed
  bool chordBuildDone = false;           // build mode: locked during feedback
  Set<int>? chordBuildReveal;            // build mode: correct set after Reveal

  // Choice-mode = the timer behaves like identify (follows [timerMode], no
  // leaderboard). Interval and chord game types share this timing treatment.
  bool get isChoiceMode =>
      currentGameMode.value == 'reverse' ||
      currentGameMode.value == 'interval' ||
      currentGameMode.value == 'chord';

  bool get isIntervalMode => currentGameMode.value == 'interval';
  bool get isIntervalName =>
      isIntervalMode && intervalGameType == IntervalGameType.name;
  bool get isIntervalBuild =>
      isIntervalMode && intervalGameType == IntervalGameType.build;

  bool get isChordMode => currentGameMode.value == 'chord';
  bool get isChordName =>
      isChordMode && chordGameType == ChordGameType.name;
  bool get isChordBuild =>
      isChordMode && chordGameType == ChordGameType.build;

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
    _clearIntervalState();
    _clearChordState();

    await initLocalDbData();
    // Don't override a mode the user explicitly picked (startup screen / switcher).
    if (!modeChosen) {
      currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown'
          ? 'countdown'
          : 'stopwatch';
    }
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

  // A session is "in progress" once the user has started (and not yet reset)
  // the game — running OR paused. While active, navigation away from the game
  // screen is blocked so the timer/score can't be abandoned mid-session.
  bool get sessionActive => isStart || isPaused;

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
    if (isIntervalMode) {
      if (isIntervalBuild) {
        newBuildIntervalPrompt();
      } else {
        newIntervalPrompt();
      }
      update();
      return;
    }
    if (isChordMode) {
      // The catalog can still be loading on the first play — start the round
      // as soon as it's ready.
      if (_chordCatalog == null) {
        ensureChordCatalog().then((_) {
          if (isStart) {
            isChordBuild ? newBuildChordPrompt() : newChordNamePrompt();
          }
        });
      } else {
        isChordBuild ? newBuildChordPrompt() : newChordNamePrompt();
      }
      update();
      return;
    }
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
    _clearIntervalState();
    _clearChordState();

    // Keep the chosen trainer mode on reset — only the plain find-note timer
    // modes fall back to the saved default. Identify / interval stay put so the
    // reset button clears the round rather than kicking back to Find Note.
    if (resetAll && !isChoiceMode) {
      currentGameMode.value = defaultTimerSelectedValue.value == 'Countdown'
          ? 'countdown'
          : 'stopwatch';
    }

    resetTimer();
    update();
  }

  void _clearIntervalState() {
    intervalPrompt = null;
    intervalRootIndex = null;
    intervalTargetIndex = null;
    intervalChoicesList = [];
    intervalSelected = null;
    intervalWasCorrect = false;
    intervalBuildDone = false;
    intervalBuildRevealIndex = null;
  }

  void _clearChordState() {
    chordPrompt = null;
    chordChoicesList = [];
    chordSelected = null;
    chordWasCorrect = false;
    chordTapped = {};
    chordBuildDone = false;
    chordBuildReveal = null;
  }

  void resetTimer() {
    // In choice modes (identify / interval) use timerMode; otherwise currentGameMode
    final effective = isChoiceMode ? timerMode.value : currentGameMode.value;
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
    final effective = isChoiceMode ? timerMode.value : currentGameMode.value;
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
    if (isChoiceMode) {
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
    modeChosen = true;
    currentGameMode.value = 'reverse';
    reverseChoices = [];
    resetGame(false);
    update();
  }

  void switchToFindMode() {
    modeChosen = true;
    currentGameMode.value = timerMode.value;
    reverseChoices = [];
    resetGame(false);
    update();
  }

  // ── Interval mode ("Name the Interval") ──────────────────────────────────

  void switchToIntervalMode({
    IntervalGameType? type,
    IntervalDifficulty? difficulty,
  }) {
    modeChosen = true;
    currentGameMode.value = 'interval';
    if (type != null) intervalGameType = type;
    if (difficulty != null) intervalDifficulty = difficulty;
    _clearIntervalState();
    resetGame(false);
    update();
  }

  void setIntervalDifficulty(IntervalDifficulty difficulty) {
    intervalDifficulty = difficulty;
    // If a round is idle, regenerate nothing; the next Play uses the new level.
    update();
  }

  void setIntervalGameType(IntervalGameType type) {
    intervalGameType = type;
    update();
  }

  // ── Build the Interval: show a root + interval name, user taps the fret ──

  /// Prepares the next build question: a root note and a target interval that
  /// is reachable at the current difficulty (the actual target fret stays
  /// hidden — the user has to find it).
  void newBuildIntervalPrompt() {
    final prompt = pickIntervalPrompt(
      fretList,
      difficulty: intervalDifficulty,
      isStringActive: getStringStatus,
    );
    if (prompt == null) return;

    intervalPrompt = prompt;
    intervalRootIndex = fretList.indexOf(prompt.root);
    intervalTargetIndex = null; // hidden — the user taps to find it
    intervalSelected = null;
    intervalWasCorrect = false;
    intervalBuildDone = false;
    intervalBuildRevealIndex = null;
    selectedFret = null;
    selectedColor = Colors.transparent;

    if (identifyPlaySound) unawaited(prompt.root.playSound());
    update();
  }

  /// Handles a fret tap in build mode. Any position exactly the target interval
  /// away from the root counts (ascending for easy/medium, either way on hard).
  void selectBuildIntervalFret(int index) {
    if (!isStart) return;
    if (intervalBuildDone) return; // locked while showing feedback
    final root = intervalPrompt?.root;
    final want = intervalPrompt?.interval;
    if (root == null || want == null) return;
    if (index < 0 || index >= fretList.length) return;

    final tapped = fretList[index];
    // Only count taps on active strings, mirroring find mode.
    if (!getStringStatus(tapped.string ?? 0)) {
      unawaited(tapped.playSound());
      return;
    }

    final gap = semitoneGap(root, tapped);
    final isCorrect = intervalDifficulty == IntervalDifficulty.hard
        ? gap.abs() == want.semitones
        : gap == want.semitones;

    intervalBuildDone = true;
    selectedFret = index;
    unawaited(tapped.playSound());
    unawaited(HeatmapService.recordAttempt(index, isCorrect));

    if (isCorrect) {
      selectedColor = JHGColors.green;
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 350)
          : const Duration(milliseconds: 700);
      Future.delayed(delay, () {
        if (isStart) newBuildIntervalPrompt();
      });
    } else {
      selectedColor = JHGColors.primary;
      // Reveal where a correct answer was so the user learns from the miss.
      intervalBuildRevealIndex = intervalRootIndex == null
          ? null
          : fretList.indexOf(intervalPrompt!.target);
      decrementScore();
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (isStart) newBuildIntervalPrompt();
      });
    }
    update();
    onFretTappedDuringTour?.call();
  }

  /// Generates the next interval question, honouring difficulty and muted
  /// strings. No-op (keeps the previous prompt) if no valid pair exists.
  void newIntervalPrompt() {
    final prompt = pickIntervalPrompt(
      fretList,
      difficulty: intervalDifficulty,
      isStringActive: getStringStatus,
    );
    if (prompt == null) return;

    intervalPrompt = prompt;
    intervalRootIndex = fretList.indexOf(prompt.root);
    intervalTargetIndex = fretList.indexOf(prompt.target);
    intervalChoicesList = intervalChoices(prompt.interval);
    intervalSelected = null;
    intervalWasCorrect = false;

    if (identifyPlaySound) unawaited(_playIntervalNotes());
    update();
  }

  Future<void> _playIntervalNotes() async {
    final p = intervalPrompt;
    if (p == null) return;
    await p.root.playSound();
    await Future.delayed(const Duration(milliseconds: 480));
    // Guard against the round having moved on while we waited.
    if (intervalPrompt == p) await p.target.playSound();
  }

  void selectIntervalAnswer(MusicInterval choice) {
    if (!isStart) return;
    if (intervalSelected != null) return; // block double-tap during feedback
    final correct = intervalPrompt?.interval;
    if (correct == null) return;

    if (identifyPlaySound) unawaited(_playIntervalNotes());

    final isCorrect = choice.semitones == correct.semitones;
    intervalSelected = choice;
    intervalWasCorrect = isCorrect;

    // Record against the target fret so the heatmap still reflects trouble spots.
    if (intervalTargetIndex != null) {
      unawaited(HeatmapService.recordAttempt(intervalTargetIndex!, isCorrect));
    }

    if (isCorrect) {
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 650);
      Future.delayed(delay, () {
        if (isStart) newIntervalPrompt();
      });
    } else {
      decrementScore();
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (isStart) newIntervalPrompt();
      });
    }
    update();
    onAnswerSelectedDuringTour?.call();
  }

  // ── Chord mode ("Name / Build the Chord") ────────────────────────────────

  void switchToChordMode({
    ChordGameType? type,
    ChordDifficulty? difficulty,
  }) {
    modeChosen = true;
    currentGameMode.value = 'chord';
    if (type != null) chordGameType = type;
    if (difficulty != null) chordDifficulty = difficulty;
    _clearChordState();
    ensureChordCatalog();
    resetGame(false);
    update();
  }

  void setChordDifficulty(ChordDifficulty difficulty) {
    chordDifficulty = difficulty;
    update();
  }

  void setChordGameType(ChordGameType type) {
    chordGameType = type;
    update();
  }

  /// Loads + builds the chord catalog once (parsed off the UI thread). Safe to
  /// call repeatedly — it no-ops after the first successful build.
  Future<void> ensureChordCatalog() async {
    if (_chordCatalog != null || chordCatalogLoading) return;
    chordCatalogLoading = true;
    update();
    try {
      final data = await _chordService.getData();
      _chordCatalog = ChordCatalog(data);
    } finally {
      chordCatalogLoading = false;
      update();
    }
  }

  /// Strums a chord shape: each sounding note in turn, low string → high, so it
  /// reads as a downstroke rather than a block.
  Future<void> _playChord(ChordShape shape) async {
    for (final i in shape.boardIndices) {
      if (i < 0 || i >= fretList.length) continue;
      unawaited(fretList[i].playSound());
      await Future.delayed(const Duration(milliseconds: 70));
    }
  }

  /// Prepares the next Name question: a shape to light up plus its answer set.
  void newChordNamePrompt() {
    final cat = _chordCatalog;
    if (cat == null) return;
    final shape = cat.pick(chordDifficulty);
    if (shape == null) return;

    chordPrompt = shape;
    chordChoicesList = cat.choices(shape, chordDifficulty);
    chordSelected = null;
    chordWasCorrect = false;
    chordTapped = {};
    chordBuildDone = false;
    chordBuildReveal = null;
    selectedFret = null;
    selectedColor = Colors.transparent;

    if (identifyPlaySound) unawaited(_playChord(shape));
    update();
  }

  /// Prepares the next Build question: a chord symbol is shown; the actual
  /// shape stays hidden until the user places it (or reveals it).
  void newBuildChordPrompt() {
    final cat = _chordCatalog;
    if (cat == null) return;
    final shape = cat.pick(chordDifficulty);
    if (shape == null) return;

    chordPrompt = shape;
    chordChoicesList = [];
    chordSelected = null;
    chordWasCorrect = false;
    chordTapped = {};
    chordBuildDone = false;
    chordBuildReveal = null;
    selectedFret = null;
    selectedColor = Colors.transparent;

    // Play it once as an audio reference for the shape to build.
    if (identifyPlaySound) unawaited(_playChord(shape));
    update();
  }

  void selectChordAnswer(String symbol) {
    if (!isStart) return;
    if (chordSelected != null) return; // block double-tap during feedback
    final correct = chordPrompt?.symbol;
    if (correct == null) return;

    if (identifyPlaySound) unawaited(_playChord(chordPrompt!));

    final isCorrect = symbol == correct;
    chordSelected = symbol;
    chordWasCorrect = isCorrect;

    if (isCorrect) {
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 350)
          : const Duration(milliseconds: 750);
      Future.delayed(delay, () {
        if (isStart) newChordNamePrompt();
      });
    } else {
      decrementScore();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (isStart) newChordNamePrompt();
      });
    }
    update();
    onAnswerSelectedDuringTour?.call();
  }

  /// Build mode: toggle a fretted position. Open strings (fret 0) aren't part
  /// of the placed shape — tapping one just sounds the note. The round is won
  /// when the placed set matches any accepted voicing of the target chord.
  void tapChordFret(int index) {
    if (!isStart) return;
    if (chordBuildDone) return; // locked while showing feedback
    if (index < 0 || index >= fretList.length) return;

    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    unawaited(model.playSound());
    if (fret <= 0) return; // open string — not a placed note

    if (chordTapped.contains(index)) {
      chordTapped.remove(index);
    } else {
      chordTapped.add(index);
    }

    final matched = chordPrompt?.acceptableFrettedSets.any((s) =>
            s.length == chordTapped.length && s.containsAll(chordTapped)) ??
        false;
    if (matched) {
      chordBuildDone = true;
      selectedColor = JHGColors.green;
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 450)
          : const Duration(milliseconds: 850);
      Future.delayed(delay, () {
        if (isStart) newBuildChordPrompt();
      });
    }
    update();
    onFretTappedDuringTour?.call();
  }

  void clearChordBuild() {
    if (chordBuildDone) return;
    chordTapped = {};
    update();
  }

  /// Build mode: give up on the current chord — reveal a correct shape (green)
  /// and move on. Counts as a miss.
  void revealChordBuild() {
    if (!isStart || chordBuildDone) return;
    final sets = chordPrompt?.acceptableFrettedSets;
    if (sets == null || sets.isEmpty) return;
    chordBuildReveal = sets.first;
    chordBuildDone = true;
    decrementScore();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isStart) newBuildChordPrompt();
    });
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
        update();
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
        update();
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
