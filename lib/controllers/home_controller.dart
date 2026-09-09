// controllers/home_controller.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:fretboard/services/feedback_sounds.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/models/saved_session.dart';
import 'package:fretboard/services/heatmap_service.dart';
import 'package:fretboard/services/practice_stats_service.dart';
import 'package:fretboard/services/saved_sessions_service.dart';
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
  // True once the user has explicitly chosen which strings to practise (the
  // customize-session Strings step, or the Settings per-string toggles). The
  // string prefs have no setter, so getString1..6() always return `true` — this
  // flag stops initLocalDbData() from resetting a live selection back to all-on
  // every time the training board opens.
  bool stringsChosen = false;
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

  // ── Chord Lab ──────────────────────────────────────────────────────────────
  // The customize-session chord game type: one session rotates through the four
  // ChordLabRound variations.
  Set<String> chordLabKeys = {...kChromaticRoots};
  Set<String> chordLabTonalities = {...kChordLabTonalities};
  Set<ChordLabRound> chordLabRounds = {...ChordLabRound.values};
  ChordLabPrompt? chordLabPrompt;
  Set<int> chordLabActive = {};   // currently lit fretted notes
  int? chordLabFlashIndex;        // fret briefly flashed red after a wrong tap
  bool chordLabDone = false;      // locked while the win feedback shows
  ChordLabRound? _lastLabRound;

  // ── Practice-stats guards ────────────────────────────────────────────────
  // Accuracy is recorded once per prompt (the first graded outcome), so the
  // Stats screen reflects genuine first-try knowledge rather than every retry.
  bool _intervalStatDone = false;
  bool _chordStatDone = false;
  bool _labStatDone = false;
  bool _labHadWrong = false; // a board-round tap went wrong before the win

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
  bool get isChordLab =>
      isChordMode && chordGameType == ChordGameType.lab;
  bool get isChordLabName =>
      isChordLab && chordLabPrompt?.round == ChordLabRound.name;

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
    if (timerIntervalValue.value < kMinTimerIntervalSeconds) {
      timerIntervalValue.value = kMinTimerIntervalSeconds;
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
  /// Countdown length in seconds. Defaults to 2 minutes — a 1-second default
  /// made every unconfigured countdown end the moment it started.
  RxInt timerIntervalValue = 120.obs;
  RxInt minutesValue = 2.obs;

  JHGInterstitialAd? interstitialAds;
  RxBool isExpanded = RxBool(false);

  /// Controls the collapsible bottom panel on the portrait home screen.
  /// Tour steps and game-state changes drive this; the panel widget observes it.
  final isBottomPanelExpanded = true.obs;

  // ── Identify mode settings ───────────────────────────────────────────────
  bool identifyShowPositionHint = true;
  bool identifyAutoAdvance = false;
  // Off by default: the trainer no longer auto-plays notes/chords during a
  // round. Users can still hear the current prompt on demand via the Listen
  // button (playCurrentPrompt), or re-enable auto-play from Settings.
  bool identifyPlaySound = false;

  @override
  void onInit() {
    super.onInit();
    // Warm the chord library in the background isolate the moment the app
    // boots, so it's already parsed by the time the user reaches Chord mode —
    // no "Loading chords…"/"Getting the next chord…" stall on first play.
    unawaited(ensureChordCatalog());
    // Preload the answer-feedback cues so the first correct/wrong is instant.
    unawaited(FeedbackSounds.instance.init());
  }

  /// Plays the current prompt on demand (the Listen button). Respects nothing
  /// but the current mode — this is the explicit "let me hear it" action, so it
  /// always sounds regardless of the identifyPlaySound auto-play setting.
  void playCurrentPrompt() {
    if (isChordLab) {
      final shape = chordLabPrompt?.target;
      if (shape != null) unawaited(_playChord(shape));
      return;
    }
    if (isChordMode) {
      final shape = chordPrompt;
      if (shape != null) unawaited(_playChord(shape));
      return;
    }
    if (isIntervalMode) {
      if (intervalPrompt != null) unawaited(_playIntervalNotes());
      return;
    }
    // Find / Identify note modes: sound the highlighted target fret.
    final fret = highlightFret;
    if (fret != null && fret >= 0 && fret < fretList.length) {
      unawaited(fretList[fret].playSound());
    }
  }

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

    // A resume was queued from the Saved Sessions screen — apply it now that the
    // fresh-session reset above has run, so the restored score/clock survive.
    if (_pendingRestore != null) _applyPendingRestore();
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
            // Only the real Find game records the Find-mode split — the board
            // tap also reaches here from identify/name modes via the shared
            // handler, and those must not count as Find attempts.
            if (!isChoiceMode) {
              unawaited(PracticeStatsService.record(
                  StatsModule.note, 'mode:find', true));
              unawaited(
                  PracticeStatsService.recordHistory(StatsModule.note, true));
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
            if (!isChoiceMode) {
              unawaited(PracticeStatsService.record(
                  StatsModule.note, 'mode:find', false));
              unawaited(
                  PracticeStatsService.recordHistory(StatsModule.note, false));
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
    // Answer feedback: cheerful cue + a light tick. Every answer path routes
    // through here, so all modes get consistent feedback.
    unawaited(FeedbackSounds.instance.playCorrect());
    unawaited(HapticFeedback.lightImpact());
    update();
  }

  void decrementScore() {
    score = score - 1;
    isPlayed = true;
    selectedColor = JHGColors.primary;
    // Answer feedback: buzzer + a firmer tap so a miss is felt as well as heard.
    unawaited(FeedbackSounds.instance.playWrong());
    unawaited(HapticFeedback.mediumImpact());
    update();
  }

  bool isStart = false;
  bool isPaused = false;

  /// True only for a session launched from Home → **Quick start**. Quick start
  /// picks nothing for the user, so the board offers the in-place Modes shifter
  /// to swap Notes / Intervals / Chords. A Customized Practice session (or a
  /// resumed saved one) was configured deliberately in the wizard, so the
  /// shifter stays hidden there and the mode is changed from Home.
  bool quickStartSession = false;

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
          if (isStart) _startNextChordRound();
        });
      } else {
        _startNextChordRound();
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
    chordLabPrompt = null;
    chordLabActive = {};
    chordLabFlashIndex = null;
    chordLabDone = false;
    _lastLabRound = null;
  }

  /// The configured countdown length, floored so a stale or zeroed stored
  /// value can never produce a round that ends instantly.
  int get _countdownSeconds =>
      timerIntervalValue.value < kMinTimerIntervalSeconds
          ? kMinTimerIntervalSeconds
          : timerIntervalValue.value;

  /// Set once the session's timing has been chosen explicitly (the wizard's
  /// timing step, Quick start, or a restored session). While true,
  /// [initLocalDbData] leaves the timer alone — it used to overwrite the
  /// wizard's choice with the stored default every time the board was opened,
  /// so "10 minutes" became whatever Settings last held.
  bool timingChosen = false;

  void resetTimer() {
    // In choice modes (identify / interval) use timerMode; otherwise currentGameMode
    final effective = isChoiceMode ? timerMode.value : currentGameMode.value;
    if (effective == 'countdown') {
      secondsRemaining.value = _countdownSeconds;
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
    // Picking the clock from the board is as explicit as picking it in the
    // wizard — see [timingChosen].
    timingChosen = true;
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

  /// Applies the customize-session timing choice made in the wizard's timing
  /// step. [useTimer] false → a count-up stopwatch; true → a countdown from
  /// [minutes]. Sets the shared [timerMode] (which drives the timer in the
  /// choice modes) and, for the plain find-note modes, mirrors it onto
  /// [currentGameMode]. Call AFTER switchToXxx so isChoiceMode is already known.
  void applySessionTiming({required bool useTimer, int minutes = 10}) {
    timingChosen = true;
    if (useTimer) {
      timerMode.value = 'countdown';
      timerIntervalValue.value = (minutes <= 0 ? 1 : minutes) * 60;
    } else {
      timerMode.value = 'stopwatch';
    }
    if (!isChoiceMode) {
      currentGameMode.value = useTimer ? 'countdown' : 'stopwatch';
    }
    resetTimer();
    update();
  }

  // ── Saved sessions ─────────────────────────────────────────────────────────
  // A session snapshot the player can leave and return to. Restored config is
  // held in [_pendingRestore] until the board's initializeData() has run (which
  // otherwise resets score/state), then applied.
  SavedSession? _pendingRestore;

  int get _activeStringCount =>
      [string1, string2, string3, string4, string5, string6]
          .where((s) => s)
          .length;

  String _difficultyLabel(int index) =>
      const ['Easy', 'Medium', 'Difficult'][index.clamp(0, 2)];

  String _sessionTitle() {
    if (isChordMode) {
      if (isChordLab) return 'Chord Lab';
      return isChordBuild ? 'Build the Chord' : 'Name the Chord';
    }
    if (isIntervalMode) {
      return isIntervalBuild ? 'Build the Interval' : 'Name the Interval';
    }
    if (currentGameMode.value == 'reverse') return 'Identify the Note';
    return 'Find the Note';
  }

  String _sessionSubtitle() {
    final strings = _activeStringCount == 6
        ? 'all strings'
        : '$_activeStringCount string${_activeStringCount == 1 ? '' : 's'}';
    if (isChordMode) {
      if (isChordLab) {
        final n = chordLabTonalities.length;
        return '${_difficultyLabel(chordDifficulty.index)} · $n chord '
            'type${n == 1 ? '' : 's'}';
      }
      return _difficultyLabel(chordDifficulty.index);
    }
    if (isIntervalMode) {
      return '${_difficultyLabel(intervalDifficulty.index)} · $strings';
    }
    return strings;
  }

  /// Builds a snapshot of the current session (config + score + clock).
  SavedSession captureSession({String? customName, String? folderId}) {
    return SavedSession(
      customName: customName,
      folderId: folderId,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      gameMode: currentGameMode.value,
      intervalGameType: intervalGameType.index,
      chordGameType: chordGameType.index,
      intervalDifficulty: intervalDifficulty.index,
      chordDifficulty: chordDifficulty.index,
      strings: [string1, string2, string3, string4, string5, string6],
      selectedIntervals: selectedIntervals.toList(),
      chordLabKeys: chordLabKeys.toList(),
      chordLabTonalities: chordLabTonalities.toList(),
      chordLabRounds: chordLabRounds.map((r) => r.name).toList(),
      timerMode: timerMode.value,
      timerIntervalValue: timerIntervalValue.value,
      score: score,
      secondsRemaining: secondsRemaining.value,
      title: _sessionTitle(),
      subtitle: _sessionSubtitle(),
    );
  }

  /// Persists the current session so it can be resumed later. Returns false if
  /// there's nothing in progress to save.
  Future<bool> saveCurrentSession({
    String? customName,
    String? folderId,
  }) async {
    if (!sessionActive) return false;
    await SavedSessionsService.add(
        captureSession(customName: customName, folderId: folderId));
    return true;
  }

  /// The name pre-filled in the Save dialog, e.g. "Name the Interval, 24 pts".
  String defaultSessionName() =>
      score > 0 ? '${_sessionTitle()}, $score pts' : _sessionTitle();

  /// Stashes [s] to be restored once the board has finished initialising. Call
  /// then navigate to the board.
  void prepareRestore(SavedSession s) {
    _pendingRestore = s;
    modeChosen = true;
    stringsChosen = true;
  }

  void _applyPendingRestore() {
    final s = _pendingRestore;
    if (s == null) return;
    _pendingRestore = null;

    modeChosen = true;
    currentGameMode.value = s.gameMode;
    intervalGameType = IntervalGameType.values[
        s.intervalGameType.clamp(0, IntervalGameType.values.length - 1)];
    chordGameType = ChordGameType
        .values[s.chordGameType.clamp(0, ChordGameType.values.length - 1)];
    intervalDifficulty = IntervalDifficulty.values[
        s.intervalDifficulty.clamp(0, IntervalDifficulty.values.length - 1)];
    chordDifficulty = ChordDifficulty
        .values[s.chordDifficulty.clamp(0, ChordDifficulty.values.length - 1)];

    // Strings
    final st = s.strings;
    if (st.length == 6) {
      string1 = st[0];
      string2 = st[1];
      string3 = st[2];
      string4 = st[3];
      string5 = st[4];
      string6 = st[5];
      for (var i = 0; i < offString.length; i++) {
        offString[i] = isStringOn(6 - i);
      }
      stringsChosen = true;
    }

    if (s.selectedIntervals.isNotEmpty) {
      selectedIntervals = s.selectedIntervals.toSet();
    }
    if (s.chordLabKeys.isNotEmpty) chordLabKeys = s.chordLabKeys.toSet();
    if (s.chordLabTonalities.isNotEmpty) {
      chordLabTonalities = s.chordLabTonalities.toSet();
    }
    if (s.chordLabRounds.isNotEmpty) {
      chordLabRounds = s.chordLabRounds
          .map((n) => ChordLabRound.values
              .firstWhere((r) => r.name == n, orElse: () => ChordLabRound.name))
          .toSet();
    }

    timerMode.value = s.timerMode;
    timerIntervalValue.value = s.timerIntervalValue;
    timingChosen = true;

    // Restore the live progress and park it paused — the player taps Resume
    // (the play control) to continue from exactly here.
    score = s.score;
    secondsRemaining.value = s.secondsRemaining;
    isStart = false;
    isPaused = true;

    _primeRestoredRound();
    update();
  }

  /// Generates the first prompt for a restored session so the board isn't empty
  /// while it sits paused (score + clock already restored).
  void _primeRestoredRound() {
    if (isIntervalMode) {
      isIntervalBuild ? newBuildIntervalPrompt() : newIntervalPrompt();
    } else if (isChordMode) {
      if (_chordCatalog == null) {
        ensureChordCatalog().then((_) {
          if (isPaused) {
            _startNextChordRound();
            update();
          }
        });
      } else {
        _startNextChordRound();
      }
    } else {
      highLightTheGame();
    }
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

  // Which intervals the user chose to practise (semitone values 0..12). All by
  // default so an unconfigured / Random session covers the whole catalog.
  Set<int> selectedIntervals =
      {for (final iv in kIntervals) iv.semitones};

  /// Sets the practised-interval filter. Ignores an empty set (there must be at
  /// least one interval to generate a question).
  void setSelectedIntervals(Set<int> semitones) {
    if (semitones.isEmpty) return;
    selectedIntervals = {...semitones};
    update();
  }

  /// Resets the interval filter to the full catalog (used by Random Practice).
  void resetIntervalFilter() {
    selectedIntervals = {for (final iv in kIntervals) iv.semitones};
  }

  /// Turns every string back on — used by Random Practice ("everything") so a
  /// narrowed selection from an earlier customized session doesn't carry over.
  void resetStrings() {
    string1 = string2 = string3 = string4 = string5 = string6 = true;
    offString = [true, true, true, true, true, true];
    stringsChosen = true; // keep this explicit all-on choice for the session
    update();
  }

  void switchToIntervalMode({
    IntervalGameType? type,
    IntervalDifficulty? difficulty,
    Set<int>? intervals,
  }) {
    modeChosen = true;
    currentGameMode.value = 'interval';
    if (type != null) intervalGameType = type;
    if (difficulty != null) intervalDifficulty = difficulty;
    if (intervals != null && intervals.isNotEmpty) {
      selectedIntervals = {...intervals};
    }
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
      allowedSemitones: selectedIntervals,
    );
    if (prompt == null) return;

    intervalPrompt = prompt;
    intervalRootIndex = fretList.indexOf(prompt.root);
    intervalTargetIndex = null; // hidden — the user taps to find it
    intervalSelected = null;
    intervalWasCorrect = false;
    intervalBuildDone = false;
    _intervalStatDone = false;
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
    _recordIntervalStat(isCorrect);

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
      allowedSemitones: selectedIntervals,
    );
    if (prompt == null) return;

    intervalPrompt = prompt;
    intervalRootIndex = fretList.indexOf(prompt.root);
    intervalTargetIndex = fretList.indexOf(prompt.target);
    intervalChoicesList = intervalChoices(prompt.interval);
    intervalSelected = null;
    intervalWasCorrect = false;
    _intervalStatDone = false;

    if (identifyPlaySound) unawaited(_playIntervalNotes());
    update();
  }

  /// Records the first graded outcome for the current interval prompt, split by
  /// the interval quality (which interval) and by game type (name vs build).
  void _recordIntervalStat(bool correct) {
    if (_intervalStatDone) return;
    final interval = intervalPrompt?.interval;
    if (interval == null) return;
    _intervalStatDone = true;
    unawaited(PracticeStatsService.recordAll(
      StatsModule.interval,
      ['q:${interval.short}', 'mode:${isIntervalBuild ? 'build' : 'name'}'],
      correct,
    ));
    unawaited(PracticeStatsService.recordHistory(StatsModule.interval, correct));
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
    _recordIntervalStat(isCorrect);

    if (isCorrect) {
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 250)
          : const Duration(milliseconds: 650);
      Future.delayed(delay, () {
        if (isStart) newIntervalPrompt();
      });
    } else {
      // Wrong pick: dock a point and flash the tapped choice, but keep the
      // same question. Clear the selection after the flash so the user can
      // try again — we never reveal the answer or auto-advance on a miss.
      decrementScore();
      final tapped = choice;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (isStart && !intervalWasCorrect && intervalSelected == tapped) {
          intervalSelected = null;
          update();
        }
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

  /// Enters Chord Lab with the chosen keys, tonalities and difficulty.
  void switchToChordLab({
    required Set<String> keys,
    required Set<String> tonalities,
    required Set<ChordLabRound> rounds,
    required ChordDifficulty difficulty,
  }) {
    modeChosen = true;
    currentGameMode.value = 'chord';
    chordGameType = ChordGameType.lab;
    chordDifficulty = difficulty;
    if (keys.isNotEmpty) chordLabKeys = {...keys};
    if (tonalities.isNotEmpty) chordLabTonalities = {...tonalities};
    if (rounds.isNotEmpty) chordLabRounds = {...rounds};
    _clearChordState();
    ensureChordCatalog();
    resetGame(false);
    update();
  }

  /// Routes to the right chord-round generator for the current game type.
  void _startNextChordRound() {
    if (isChordLab) {
      newChordLabPrompt();
    } else if (isChordBuild) {
      newBuildChordPrompt();
    } else {
      newChordNamePrompt();
    }
  }

  /// Skips the current question and draws a fresh one — no score change. Works
  /// in every mode.
  void skipQuestion() {
    if (!isStart) return;
    if (isChordMode) {
      _startNextChordRound();
      return;
    }
    if (isIntervalMode) {
      isIntervalBuild ? newBuildIntervalPrompt() : newIntervalPrompt();
      return;
    }
    if (currentGameMode.value == 'reverse') {
      reverseSelectedNote = null;
      reverseWasCorrect = false;
      highLightTheGame();
      return;
    }
    // Find mode: a fresh target note.
    highLightTheGame();
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
    _chordStatDone = false;

    if (identifyPlaySound) unawaited(_playChord(shape));
    update();
  }

  /// Records the first graded outcome for the current chord prompt, split by
  /// chord quality (which chord) and game type (name vs build).
  void _recordChordStat(bool correct) {
    if (_chordStatDone) return;
    final shape = chordPrompt;
    if (shape == null) return;
    _chordStatDone = true;
    unawaited(PracticeStatsService.recordAll(
      StatsModule.chord,
      ['q:${shape.tonality}', 'mode:${isChordBuild ? 'build' : 'name'}'],
      correct,
    ));
    unawaited(PracticeStatsService.recordHistory(StatsModule.chord, correct));
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
    _chordStatDone = false;

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
    _recordChordStat(isCorrect);

    if (isCorrect) {
      incrementScore();
      final delay = identifyAutoAdvance
          ? const Duration(milliseconds: 350)
          : const Duration(milliseconds: 750);
      Future.delayed(delay, () {
        if (isStart) newChordNamePrompt();
      });
    } else {
      // Wrong pick: dock a point and flash the tapped symbol, but keep the
      // same question. Clear the selection after the flash so the user can
      // try again — we never reveal the answer or auto-advance on a miss.
      decrementScore();
      final tapped = symbol;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (isStart && !chordWasCorrect && chordSelected == tapped) {
          chordSelected = null;
          update();
        }
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
      _recordChordStat(true);
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

  /// Build mode: give up on the current chord — reveal a correct shape (green,
  /// with note names on the board) and wait. Counts as a miss. The round does
  /// NOT auto-advance: the Reveal control becomes "Next" and the user taps it
  /// (nextBuildChord) when they've studied the answer.
  void revealChordBuild() {
    if (!isStart || chordBuildDone) return;
    final sets = chordPrompt?.acceptableFrettedSets;
    if (sets == null || sets.isEmpty) return;
    chordBuildReveal = sets.first;
    chordBuildDone = true;
    _recordChordStat(false);
    decrementScore();
    update();
  }

  /// Build mode: advance to the next chord after a reveal (the "Next" control).
  void nextBuildChord() {
    if (!isStart) return;
    newBuildChordPrompt();
  }

  // ── Chord Lab ────────────────────────────────────────────────────────────

  /// Prepares the next Chord Lab round (a random variation on a chord drawn from
  /// the selected keys × tonalities).
  void newChordLabPrompt() {
    final cat = _chordCatalog;
    if (cat == null) return;
    final prompt = cat.nextLabPrompt(
      difficulty: chordDifficulty,
      keys: chordLabKeys,
      tonalities: chordLabTonalities,
      rounds: chordLabRounds,
      avoid: _lastLabRound,
    );
    if (prompt == null) return; // nothing playable for this selection

    chordLabPrompt = prompt;
    _lastLabRound = prompt.round;
    chordLabActive = {...prompt.initial};
    chordLabFlashIndex = null;
    chordLabDone = false;
    // Name rounds reuse the choice grid.
    chordChoicesList =
        prompt.round == ChordLabRound.name ? cat.labChoices(prompt.target) : [];
    chordSelected = null;
    chordWasCorrect = false;
    selectedFret = null;
    selectedColor = Colors.transparent;
    _labStatDone = false;
    _labHadWrong = false;

    if (identifyPlaySound) unawaited(_playChord(prompt.target));
    update();
  }

  /// Records the first graded outcome for the current Chord Lab prompt, split by
  /// round type (Name / Complete / Remove / Build) and by chord quality.
  void _recordLabStat(bool correct) {
    if (_labStatDone) return;
    final p = chordLabPrompt;
    if (p == null) return;
    _labStatDone = true;
    unawaited(PracticeStatsService.recordAll(
      StatsModule.chordLab,
      ['round:${p.round.name}', 'q:${p.target.tonality}'],
      correct,
    ));
    unawaited(PracticeStatsService.recordHistory(StatsModule.chordLab, correct));
  }

  void _advanceChordLab({Duration delay = const Duration(milliseconds: 700)}) {
    Future.delayed(delay, () {
      if (isStart && isChordLab) newChordLabPrompt();
    });
  }

  /// Name round (round A): pick the chord's name. Retry-until-right, like the
  /// other name modes.
  void selectChordLabName(String symbol) {
    if (!isStart || chordLabDone) return;
    if (chordSelected != null) return;
    final p = chordLabPrompt;
    if (p == null || p.round != ChordLabRound.name) return;

    final isCorrect = symbol == p.target.symbol;
    chordSelected = symbol;
    chordWasCorrect = isCorrect;

    _recordLabStat(isCorrect);
    if (isCorrect) {
      chordLabDone = true;
      incrementScore();
      _advanceChordLab();
    } else {
      decrementScore();
      final tapped = symbol;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (isStart && !chordWasCorrect && chordSelected == tapped) {
          chordSelected = null;
          update();
        }
      });
    }
    update();
  }

  /// Board rounds (Complete / Remove / Build): a single tap handler with greedy
  /// validation — a tap that can't lead to a valid voicing is rejected and
  /// costs a point; completing a valid voicing wins the round.
  void chordLabTap(int index) {
    if (!isStart || chordLabDone) return;
    final p = chordLabPrompt;
    if (p == null || index < 0 || index >= fretList.length) return;
    final fret = index ~/ 6;
    if (fret <= 0) {
      // Open string — sound it, but it's never part of a placed set.
      unawaited(fretList[index].playSound());
      return;
    }

    switch (p.round) {
      case ChordLabRound.name:
        return; // name rounds are answered via the choice grid

      case ChordLabRound.remove:
        if (!chordLabActive.contains(index)) return; // only remove lit notes
        final trial = {...chordLabActive}..remove(index);
        unawaited(fretList[index].playSound());
        if (_labMatches(p, trial)) {
          chordLabActive = trial;
          _winChordLab();
        } else {
          // Removing a real chord tone is wrong — dock a point, flash the note
          // red so the tap clearly registers, and keep it in place.
          _labHadWrong = true;
          decrementScore();
          _flashLab(index);
        }

      case ChordLabRound.complete:
      case ChordLabRound.build:
        if (p.locked.contains(index)) return; // given notes are fixed
        unawaited(fretList[index].playSound());
        if (chordLabActive.contains(index)) {
          // Toggle off your own placed note (free undo, no penalty).
          chordLabActive = {...chordLabActive}..remove(index);
          update();
          return;
        }
        final trial = {...chordLabActive, index};
        if (_labCanExtendTo(p, trial)) {
          chordLabActive = trial;
          if (_labMatches(p, trial)) {
            _winChordLab();
          } else {
            update();
          }
        } else {
          // A note that can't belong to any valid voicing — reject it with a
          // red flash so the tap is clearly acknowledged.
          _labHadWrong = true;
          decrementScore();
          _flashLab(index);
        }
    }
  }

  /// True if [set] exactly equals one of the round's accepted voicings.
  bool _labMatches(ChordLabPrompt p, Set<int> set) => p.acceptable
      .any((a) => a.length == set.length && a.containsAll(set));

  /// True if [set] is a subset of some accepted voicing (i.e. still completable).
  bool _labCanExtendTo(ChordLabPrompt p, Set<int> set) =>
      p.acceptable.any((a) => a.containsAll(set));

  void _winChordLab() {
    chordLabFlashIndex = null;
    chordLabDone = true;
    selectedColor = JHGColors.green;
    // A board round counts as "known" only if solved with no wrong taps.
    _recordLabStat(!_labHadWrong);
    incrementScore();
    _advanceChordLab(delay: const Duration(milliseconds: 850));
    update();
  }

  /// Briefly flashes [index] red after a wrong Chord Lab tap so the tap clearly
  /// registers (paired with the buzzer + haptic from decrementScore).
  void _flashLab(int index) {
    chordLabFlashIndex = index;
    update();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (chordLabFlashIndex == index) {
        chordLabFlashIndex = null;
        update();
      }
    });
  }

  /// Chord Lab: clear the notes the user has placed (leaves the given ones).
  void clearChordLab() {
    final p = chordLabPrompt;
    if (p == null || chordLabDone) return;
    chordLabActive = {...p.initial};
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
    unawaited(PracticeStatsService.record(
        StatsModule.note, 'mode:identify', isCorrect));
    unawaited(PracticeStatsService.recordHistory(StatsModule.note, isCorrect));

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
      // Wrong pick: dock a point and flash the tapped button, but keep the
      // same target note. Clear the selection after the flash so the user can
      // try again — we never reveal the answer or auto-advance on a miss.
      decrementScore();
      final tapped = note;
      Future.delayed(const Duration(milliseconds: 550), () {
        if (isStart && !reverseWasCorrect && reverseSelectedNote == tapped) {
          reverseSelectedNote = null;
          update();
        }
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

  /// Sets a string's active state by string number (1 = high e … 6 = low E),
  /// keeping [offString] in sync. Never lets every string turn off — the last
  /// remaining active string can't be disabled. Used by the customize-session
  /// Strings step (mirrors the per-string toggles in Settings).
  void setStringActive(int stringNumber, bool active) {
    final idx = 6 - stringNumber; // string6→0 (low E) … string1→5 (high e)
    if (idx < 0 || idx >= offString.length) return;
    switch (stringNumber) {
      case 1: string1 = active;
      case 2: string2 = active;
      case 3: string3 = active;
      case 4: string4 = active;
      case 5: string5 = active;
      case 6: string6 = active;
    }
    offString[idx] = active;
    // Guard: keep at least one string live.
    if (!offString.contains(true)) {
      offString[idx] = true;
      switch (stringNumber) {
        case 1: string1 = true;
        case 2: string2 = true;
        case 3: string3 = true;
        case 4: string4 = true;
        case 5: string5 = true;
        case 6: string6 = true;
      }
    }
    stringsChosen = true;
    update();
  }

  /// True when string [stringNumber] (1 = high e … 6 = low E) is active.
  bool isStringOn(int stringNumber) {
    switch (stringNumber) {
      case 1: return string1;
      case 2: return string2;
      case 3: return string3;
      case 4: return string4;
      case 5: return string5;
      case 6: return string6;
    }
    return false;
  }

  bool string1 = true;
  void setString1(int index) {
    string1 = !string1;
    offString[index] = string1;
    if (!offString.contains(true)) {
      offString[index] = true;
      string1 = true;
    }
    stringsChosen = true;
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
    stringsChosen = true;
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
    stringsChosen = true;
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
    stringsChosen = true;
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
    stringsChosen = true;
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
    stringsChosen = true;
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
      secondsRemaining.value = _countdownSeconds;
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
    // Only fall back to the stored defaults when the session hasn't already
    // said what it wants — see [timingChosen].
    if (!timingChosen) {
      minutesValue.value =
          await SharedPrefHelper.instance.getDefaultTimerMinutes();
      timerIntervalValue.value =
          await SharedPrefHelper.instance.getTimerInterval();
    }
    // Only pull the saved string set on a fresh session. Once the user has
    // picked strings (wizard or Settings), keep their live choice — otherwise
    // opening the board would silently turn every string back on.
    if (!stringsChosen) {
      string1 = await SharedPrefHelper.instance.getString1();
      string2 = await SharedPrefHelper.instance.getString2();
      string3 = await SharedPrefHelper.instance.getString3();
      string4 = await SharedPrefHelper.instance.getString4();
      string5 = await SharedPrefHelper.instance.getString5();
      string6 = await SharedPrefHelper.instance.getString6();
      for (var i = 0; i < offString.length; i++) {
        offString[i] = isStringOn(6 - i); // keep offString in sync (idx0=lowE)
      }
    }
  }
}
