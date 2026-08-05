import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

// ── Fixed-pixel fretboard geometry ────────────────────────────────────────────
// These match the dictionaries / drills apps exactly so the three boards render
// identically: 80px between fret wires, 33.5px between strings, a 178px ivory
// neck centred inside a 191px column, with a 26px fret-number gutter alongside.
const double _kFretSpacing = 80.0;
const double _kStringSpacing = 33.5;
const double _kNutHeight = 14.0;
const double _kBallRadius = 14.0; // note ball ≈ 28px, so radius 14
const double _kBoardWidth = 191.0;
const double _kNeckWidth = 178.0;
const int _kTotalFrets = 15; // frets 1..15 drawn below the open (nut) row

// Standard inlay positions (0-indexed fret rows): a dot drawn at row i sits in
// fret i+1's playing area — so {2,4,6,8,14} => frets 3,5,7,9,15 (single dots)
// and {11} => fret 12 (double dot). Mirrors the dictionaries inlay map.
const Set<int> _kSingleDotFrets = {2, 4, 6, 8, 14};
const Set<int> _kDoubleDotFrets = {11};

const List<String> _kOpenStringLabels = ['E', 'A', 'D', 'G', 'B', 'E'];

// Ball top so the 28px ball is centred ON fret [fret]'s wire (wire F at F*80),
// not floating in the middle of the fret space. Open string sits at the nut.
double _ballTopFor(int fret) {
  if (fret == 0) return 2.0;
  return fret * _kFretSpacing - _kBallRadius;
}

// Tappable cell for a fret, centred on its wire so a tap lands where the note
// is drawn. Fret F spans (F*80 - 40)..(F*80 + 40); the open zone is 0..40.
double _cellTopFor(int fret) {
  if (fret == 0) return 0.0;
  return fret * _kFretSpacing - _kFretSpacing / 2;
}

double _cellHeightFor(int fret) {
  if (fret == 0) return _kFretSpacing / 2;
  return _kFretSpacing;
}

// Horizontal position. Columns run low-E (col 0, left) → high-e (col 5, right),
// matching the string data where index%6 == 6 - string.
double _ballLeftFor(int col) => col * _kStringSpacing + 12.0 - _kBallRadius;
double _cellLeftFor(int col) => col * _kStringSpacing;

class GuitarBoard extends StatefulWidget {
  const GuitarBoard({super.key, required this.isPortrait});

  final bool isPortrait;

  @override
  State<GuitarBoard> createState() => _GuitarBoardAltState();
}

class _GuitarBoardAltState extends State<GuitarBoard> {
  late bool isPortrait;
  final ScrollController _scrollController = ScrollController();
  int? _lastScrolledFret; // avoid redundant scrolls on unrelated update() calls

  @override
  void initState() {
    super.initState();
    isPortrait = widget.isPortrait;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Called inside GetBuilder.builder after every update(). Scrolls to the
  // highlighted fret when in IDENTIFY mode so it's always centered on screen.
  void _scrollToFret(HomeController controller) {
    // Interval mode centres between the two notes; identify centres the target.
    // Chord NAME centres on the shape's highest note so the whole grip is in
    // view; chord BUILD stays at the top (nothing to reveal yet).
    final bool isInterval = controller.currentGameMode.value == 'interval';
    final bool isChordName = controller.isChordName;
    final int? chordFocus = (isChordName && controller.chordPrompt != null)
        ? _chordFocusIndex(controller.chordPrompt!)
        : null;
    final int? fret = isInterval
        ? (controller.intervalTargetIndex ?? controller.intervalRootIndex)
        : isChordName
            ? chordFocus
            : controller.highlightFret;
    final isIdentify = controller.currentGameMode.value == 'reverse' ||
        isInterval ||
        isChordName;

    if (!isIdentify || !controller.isStart || fret == null) {
      // Scroll back to top when not in identify mode or game stopped
      if (_lastScrolledFret != null) {
        _lastScrolledFret = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut);
          }
        });
      }
      return;
    }

    if (fret == _lastScrolledFret) return; // same fret — no scroll needed
    _lastScrolledFret = fret;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;
      final viewport = _scrollController.position.viewportDimension;
      // fretList index → actual fret number 0-15
      final fretNumber = fretList[fret].fret ?? 0;
      if (widget.isPortrait) {
        // Fixed-pixel board: centre the highlighted fret's cell in the viewport.
        // In interval mode, centre on the midpoint of the two notes so both stay
        // in view (they can sit several frets apart at higher difficulty).
        double cellCenter =
            _cellTopFor(fretNumber) + _cellHeightFor(fretNumber) / 2;
        if (isInterval && controller.intervalRootIndex != null) {
          final rootFret =
              fretList[controller.intervalRootIndex!].fret ?? 0;
          final rootCenter =
              _cellTopFor(rootFret) + _cellHeightFor(rootFret) / 2;
          cellCenter = (cellCenter + rootCenter) / 2;
        }
        _scrollController.animateTo(
          (cellCenter - viewport / 2).clamp(0.0, maxExtent),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOut,
        );
        return;
      }
      // Legacy (landscape) estimate: 16 fret rows fill the total content.
      final rowHeight = (maxExtent + viewport) / 16.0;
      final targetOffset =
          (fretNumber * rowHeight + rowHeight / 2) - viewport / 2;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        _scrollToFret(controller);
        return widget.isPortrait
            ? _buildPortraitFixed(context, controller)
            : _buildLegacy(context, controller);
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NEW portrait board — pixel-identical to the dictionaries / drills fretboard.
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPortraitFixed(BuildContext context, HomeController controller) {
    final isReverse = controller.currentGameMode.value == 'reverse';
    final int? selected = controller.selectedFret;
    final int? target = controller.highlightFret;
    final int? highlightString = controller.highlightString;

    final bool isInterval = controller.currentGameMode.value == 'interval';
    final bool isIntervalBuild = controller.isIntervalBuild;

    final bool isChord = controller.isChordMode;
    final bool isChordBuild = controller.isChordBuild;
    final bool isChordName = controller.isChordName;

    // Board taps are live in find mode and in the BUILD variants of interval /
    // chord (where the user taps to answer). Identify and the NAME variants
    // answer with buttons instead.
    final bool tapMode = controller.isStart &&
        (isIntervalBuild ||
            isChordBuild ||
            (!isReverse && !isInterval && !isChord));

    // Whether the coral "identify this fret" glow is showing right now.
    final bool showReverseTarget = isReverse &&
        controller.isStart &&
        controller.reverseSelectedNote == null &&
        target != null;

    // Interval mode: the root ball always shows; the second (target) ball only
    // in NAME mode (in build mode the user has to find it). Same clean coral
    // ball as the rest of the app (dictionaries / drills style).
    final bool showIntervalRoot =
        isInterval && controller.isStart && controller.intervalRootIndex != null;
    final bool showIntervalTarget = isInterval &&
        !isIntervalBuild &&
        controller.isStart &&
        controller.intervalTargetIndex != null;
    // Build mode: after a wrong tap, reveal a correct target in green.
    final bool showBuildReveal = isIntervalBuild &&
        controller.isStart &&
        controller.intervalBuildRevealIndex != null;

    // Chord NAME: the whole shape lights up (root ringed, muted strings marked).
    final bool showChordShape =
        isChordName && controller.isStart && controller.chordPrompt != null;
    // Chord BUILD: the user's placed notes (green once the shape is complete).
    final bool showChordTaps = isChordBuild && controller.isStart;
    // Chord BUILD: a correct shape revealed in green after "Reveal".
    final bool showChordReveal = isChordBuild &&
        controller.isStart &&
        controller.chordBuildReveal != null;

    return Column(
      children: [
        const SizedBox(height: 10),
        // ── Pinned string-name chips (never scroll away) ──────────────────────
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 26),
            child: _stringLabelsRow(),
          ),
        ),
        const SizedBox(height: 8),
        // ── Scrollable fretboard ──────────────────────────────────────────────
        Expanded(
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _kBoardWidth,
                    height: (15 + (_kTotalFrets * _kFretSpacing) + 50),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Nut + ivory neck
                        Positioned.fill(
                          child: Column(
                            children: [
                              Container(
                                width: _kNeckWidth,
                                height: _kNutHeight,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF111111),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: _kNeckWidth,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEAE2D4),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Fret wires + inlay dots + strings
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (int i = 0; i <= _kTotalFrets; i++) _fretWire(i),
                            for (int i = 0; i < _kTotalFrets; i++) ..._inlay(i),
                            for (int col = 0; col < 6; col++)
                              _string(col, highlightString),

                            // Find-mode tap targets (transparent)
                            IgnorePointer(
                              ignoring: !tapMode,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (int index = 0;
                                      index < fretList.length;
                                      index++)
                                    _tapCell(controller, index),
                                ],
                              ),
                            ),

                            // Correct / wrong feedback ball (find mode)
                            if (selected != null &&
                                selected >= 0 &&
                                selected < fretList.length)
                              _noteBall(
                                index: selected,
                                color: controller.selectedColor ??
                                    JHGColors.primary,
                              ),

                            // Identify-mode target glow
                            if (showReverseTarget)
                              _reverseTargetBall(target),

                            // Interval-mode notes — clean coral balls (same as
                            // the rest of the suite). Root + target in name
                            // mode; root only in build mode.
                            if (showIntervalRoot)
                              _noteBall(
                                index: controller.intervalRootIndex!,
                                color: JHGColors.primary,
                              ),
                            if (showIntervalTarget)
                              _noteBall(
                                index: controller.intervalTargetIndex!,
                                color: JHGColors.primary,
                              ),
                            // Build mode: green reveal of a correct target.
                            if (showBuildReveal)
                              _noteBall(
                                index: controller.intervalBuildRevealIndex!,
                                color: JHGColors.green,
                              ),

                            // Chord NAME: the full shape (root ringed, muted
                            // strings marked with ×).
                            if (showChordShape)
                              ..._chordShapeWidgets(controller.chordPrompt!),

                            // Chord BUILD: the user's placed notes. Turn green
                            // once the placed set completes the chord.
                            if (showChordTaps)
                              for (final idx in controller.chordTapped)
                                _noteBall(
                                  index: idx,
                                  color: (controller.chordBuildDone &&
                                          controller.chordBuildReveal == null)
                                      ? JHGColors.green
                                      : JHGColors.primary,
                                ),

                            // Chord BUILD: a correct shape revealed in green.
                            if (showChordReveal)
                              for (final idx in controller.chordBuildReveal!)
                                _noteBall(
                                  index: idx,
                                  color: JHGColors.green,
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Fret-number gutter (0..15) — each number sits on its fret's
                  // wire, level with the notes on that line.
                  SizedBox(
                    width: 26,
                    height: (15 + (_kTotalFrets * _kFretSpacing) + 50),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int f = 0; f <= _kTotalFrets; f++)
                          Positioned(
                            top: (f == 0 ? 16.0 : f * _kFretSpacing) - 10.0,
                            left: 0,
                            right: 0,
                            child: Center(child: _fretNumberLabel('$f')),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Pinned string label chips (coral wash, matches dictionaries) ────────────
  Widget _stringLabelsRow() {
    const chipSize = 22.0;
    const stringCenters = [15.0, 48.5, 82.0, 115.5, 149.0, 182.5];

    return SizedBox(
      height: 30,
      width: _kBoardWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < _kOpenStringLabels.length; i++)
            Positioned(
              left: stringCenters[i] - (chipSize / 2),
              top: 0,
              child: Container(
                width: chipSize,
                height: chipSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: JHGColors.primary.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: JHGColors.primary.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -0.4),
                    child: Text(
                      _kOpenStringLabels[i],
                      textAlign: TextAlign.center,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── A single fret wire (i == 0 is the nut, drawn separately, so skipped) ────
  Widget _fretWire(int i) {
    return Positioned(
      top: i.toDouble() * _kFretSpacing,
      left: 6.0,
      right: 6.0,
      child: Container(
        height: i == 0 ? 0 : 1.2,
        decoration: i == 0
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFAAAAAA),
                    Color(0xFF777777),
                    Color(0xFF555555),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Inlay position dots (single + double) ───────────────────────────────────
  List<Widget> _inlay(int i) {
    Widget dot() => Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFF888888),
            shape: BoxShape.circle,
          ),
        );

    // Inlay for fret (i+1) sits on that fret's wire, to match the notes.
    final double markerTop = (i + 1) * _kFretSpacing - 4.5;
    if (_kDoubleDotFrets.contains(i)) {
      return [
        Positioned(
          top: markerTop,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 9,
            child: Stack(
              children: [
                Align(alignment: const Alignment(-0.35, 0), child: dot()),
                Align(alignment: const Alignment(0.35, 0), child: dot()),
              ],
            ),
          ),
        ),
      ];
    }
    if (_kSingleDotFrets.contains(i)) {
      return [
        Positioned(
          top: markerTop,
          left: 0,
          right: 0,
          child: Center(child: dot()),
        ),
      ];
    }
    return const [];
  }

  // ── A string wire (thick low-E on the left → thin high-e on the right) ──────
  Widget _string(int col, int? highlightString) {
    final double thickness = 3.5 - col * 0.5;
    final int stringNumber = 6 - col; // col 0 = low E (string 6)
    final bool highlighted = highlightString == stringNumber;
    return Positioned(
      top: 0,
      bottom: 0,
      left: col * _kStringSpacing,
      child: Padding(
        padding: EdgeInsets.only(left: 12.0 - thickness / 2),
        child: Container(
          width: thickness,
          decoration: BoxDecoration(
            gradient: highlighted
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [JHGColors.primary, JHGColors.primary],
                  )
                : LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      const Color(0xFF4A4A4A),
                      const Color(0xFF222222),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Transparent find-mode tap target for one (string, fret) cell ────────────
  Widget _tapCell(HomeController controller, int index) {
    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    final col = index % 6;
    return Positioned(
      top: _cellTopFor(fret),
      left: _cellLeftFor(col),
      width: _kStringSpacing,
      height: _cellHeightFor(fret),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (controller.isIntervalBuild) {
            controller.selectBuildIntervalFret(index);
          } else if (controller.isChordBuild) {
            controller.tapChordFret(index);
          } else {
            controller.playSound(
              index,
              model.note!,
              model.string!,
              model.fretSound!,
            );
          }
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── A clean note ball (feedback dot) at [index] ─────────────────────────────
  Widget _noteBall({required int index, required Color color}) {
    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    final col = index % 6;
    return Positioned(
      top: _ballTopFor(fret),
      left: _ballLeftFor(col),
      child: Container(
        width: 28,
        height: 28,
        decoration: _cleanBall(color),
      ),
    );
  }

  // ── The identify-mode target (white-ringed coral ball with a "?") ───────────
  Widget _reverseTargetBall(int index) {
    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    final col = index % 6;
    return Positioned(
      top: _ballTopFor(fret) - 1.5,
      left: _ballLeftFor(col) - 1.5,
      child: Container(
        width: 31,
        height: 31,
        decoration: _cleanBall(JHGColors.primary, ring: true).copyWith(
          boxShadow: [
            BoxShadow(
              color: JHGColors.primary.withValues(alpha: 0.55),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.question_mark_rounded,
              color: Colors.white, size: 15),
        ),
      ),
    );
  }

  // Board index of the shape's highest-fret sounding note — the scroll anchor
  // so the whole grip (which extends up-neck from the nut) stays in view.
  int? _chordFocusIndex(ChordShape shape) {
    int? bestIndex;
    int bestFret = -1;
    for (int col = 0; col < 6; col++) {
      final f = shape.frets[col];
      if (f == null) continue;
      if (f > bestFret) {
        bestFret = f;
        bestIndex = f * 6 + col;
      }
    }
    return bestIndex;
  }

  // ── Chord NAME: the full shape drawn on the neck ────────────────────────────
  // One ball per sounding string (root ringed + "R"), and an "×" over the nut
  // for every muted string — the standard chord-diagram reading.
  List<Widget> _chordShapeWidgets(ChordShape shape) {
    final widgets = <Widget>[];
    for (int col = 0; col < 6; col++) {
      final f = shape.frets[col];
      if (f == null) {
        widgets.add(_mutedMarker(col));
        continue;
      }
      final index = f * 6 + col;
      if (index < 0 || index >= fretList.length) continue;
      final isRoot = fretList[index].note == shape.root;
      widgets.add(isRoot
          ? _rootBall(index)
          : _noteBall(index: index, color: JHGColors.primary));
    }
    return widgets;
  }

  // ── Root ball: coral with a white ring and an "R" so the chord root reads ───
  Widget _rootBall(int index) {
    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    final col = index % 6;
    return Positioned(
      top: _ballTopFor(fret) - 1.5,
      left: _ballLeftFor(col) - 1.5,
      child: Container(
        width: 31,
        height: 31,
        decoration: _cleanBall(JHGColors.primary, ring: true),
        child: const Center(
          child: Text('R',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1)),
        ),
      ),
    );
  }

  // ── Muted-string "×" drawn at the nut for that string ───────────────────────
  Widget _mutedMarker(int col) {
    return Positioned(
      top: _ballTopFor(0),
      left: _ballLeftFor(col),
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Text('×',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1)),
        ),
      ),
    );
  }

  // ── A single fret-number label (positioned on its wire by the gutter) ───────
  Widget _fretNumberLabel(String label) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: JHGTextStyles.labelStyle.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        height: 1.2,
        color: Colors.white.withValues(alpha: 0.75),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // LEGACY board — kept for the landscape layout (orientation-locked out on
  // phones, so effectively unused, but retained so nothing regresses).
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLegacy(BuildContext context, HomeController controller) {
    bool isTablet = MediaQuery.of(context).size.width < 1100 &&
        MediaQuery.of(context).size.width >= 701 &&
        !kIsWeb;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final boardWidthFactor = isPortrait
        ? isTablet
            ? 0.3
            : 0.44
        : isTablet
            ? 0.3
            : 0.47;
    // Column with sticky string names above the scrollable fretboard
    return Column(
      children: [
        // ── String name chips — pinned at top, never scroll away ──────
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: isPortrait
                ? EdgeInsets.only(right: width * 0.11)
                : EdgeInsets.zero,
            margin: EdgeInsets.only(
              right: isPortrait ? 0 : width * 0.170,
            ),
            child: Padding(
              padding: isPortrait
                  ? EdgeInsets.zero
                  : EdgeInsets.only(left: isTablet ? 70 : 30),
              child: StringsNameWidget(
                width: width * boardWidthFactor,
                isPortrait: isPortrait,
                isTablet: isTablet,
              ),
            ),
          ),
        ),
        // ── Scrollable fretboard ──────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // nut (0.015h) + 15 fret rows (1.197h) = 1.212h — ends at fret-15 bar
                Container(
                  width: width * boardWidthFactor,
                  height: height * 1.212,
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      // BOARD SIZE WITH COLOR — nut + exactly 15 fret rows
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: height * 0.015),
                          Container(
                            width: width * 0.8,
                            height: height * 1.197,
                            color: AppColors.creamColor,
                          ),
                        ],
                      ),

                      Align(
                        alignment: Alignment.topCenter,
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: Container(
                            width: double.infinity,
                            height: height * 0.015,
                            decoration: const BoxDecoration(
                              color: JHGColors.black,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // BLACK CIRCE
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: height * 0.002),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 11),
                              height: height * 0.077,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: blackCircle(
                                      height: height,
                                      isColor: index == 11,
                                    ),
                                  ),
                                  const Expanded(child: SizedBox.shrink()),
                                  Expanded(
                                    child: blackCircle(
                                      height: height,
                                      isColor: index == 2 ||
                                          index == 4 ||
                                          index == 6 ||
                                          index == 8 ||
                                          index == 14,
                                    ),
                                  ),
                                  const Expanded(child: SizedBox.shrink()),
                                  Expanded(
                                    child: blackCircle(
                                      height: height,
                                      isColor: index == 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: 15,
                      ),

                      // ROW
                      ListView.builder(
                        itemCount: 15,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, pos) {
                          return rowDivider(height, pos);
                        },
                      ),

                      // COLUMN
                      RotatedBox(
                        quarterTurns: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return colDivider(
                              width,
                              index,
                              controller.highlightString,
                            );
                          }),
                        ),
                      ),

                      /// red green  With Grid
                      ///===========================================================
                      Align(
                        alignment: Alignment.topCenter,
                        child: AlignedGridView.count(
                          itemCount: 96,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 6,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 7,
                          itemBuilder: (context, index) {
                            return redGreenCircle(
                              isColor: controller.selectedFret == index,
                              color: controller.selectedColor,
                              index: index,
                              height: height,
                            );
                          },
                        ),
                      ),

                      /// Reverse mode: glow circle on the fret to identify
                      if (controller.currentGameMode.value == 'reverse' &&
                          controller.isStart &&
                          controller.reverseSelectedNote == null)
                        Align(
                          alignment: Alignment.topCenter,
                          child: AlignedGridView.count(
                            itemCount: 96,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 6,
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 7,
                            itemBuilder: (context, index) => reverseTargetCircle(
                              isTarget: controller.highlightFret == index,
                              index: index,
                              height: height,
                            ),
                          ),
                        ),

                      /// Fret press With Grid — only active in find-note mode
                      ///===========================================================
                      IgnorePointer(
                        ignoring: !controller.isStart ||
                            controller.currentGameMode.value == 'reverse',
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: AlignedGridView.count(
                            itemCount: 96,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 6,
                            mainAxisSpacing: 3,
                            crossAxisSpacing: 4,
                            itemBuilder: (context, index) {
                              final noteIndex = fretList[index];
                              return GestureDetector(
                                onTap: () {
                                  controller.playSound(
                                    index,
                                    noteIndex.note!,
                                    noteIndex.string!,
                                    fretList[index].fretSound!,
                                  );
                                },
                                child: stringPress(
                                  index: index,
                                  height: height,
                                  width: width,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      ///===========================================================
                    ],
                  ),
                ),
                //SPACER
                const SizedBox(width: 20),
                // NUMBERS
                Container(
                  width: width * 0.06,
                  child: ListView.builder(
                    itemCount: 16,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: getLandscapeHeight(index, height, isTablet),
                        ),
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            index.toString(),
                            style: JHGTextStyles.lrlabelStyle.copyWith(
                              fontSize: 14,
                              height: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget rowDivider(double height, int index) {
    return Padding(
      padding: EdgeInsets.only(top: height * 0.076),
      child: Container(
        height: height * 0.0038,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.whiteLight,
              AppColors.whiteLight,
              JHGColors.charcolGray,
              JHGColors.secondryBlack,
            ],
          ),
        ),
      ),
    );
  }

  Widget colDivider(double width, int index, int? selectedString) {
    return Padding(
      padding: EdgeInsets.only(
        left: index == 0 ? 12 : 0,
        right: index == 5 ? 12 : 0,
      ),
      child: Container(
        width: index == 6
            ? width * 0.011
            : index == 5
                ? width * 0.010
                : index == 4
                    ? width * 0.009
                    : index == 3
                        ? width * 0.008
                        : index == 2
                            ? width * 0.007
                            : width * 0.006,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: selectedString == index + 1
                ? [JHGColors.primary, JHGColors.primary]
                : [
                    AppColors.whiteLight,
                    AppColors.whiteLight,
                    JHGColors.charcolGray,
                    JHGColors.secondryBlack,
                  ],
          ),
        ),
      ),
    );
  }

  Widget reverseTargetCircle({
    required bool isTarget,
    required int index,
    required double height,
  }) {
    final fret = index ~/ 6;
    final cellHeight = fret == 0 ? height * 0.015 : height * 0.0798;
    final ballSize = height * 0.044;
    return SizedBox(
      height: cellHeight,
      child: Center(
        child: isTarget
            ? Container(
                width: ballSize,
                height: ballSize,
                decoration: _cleanBall(JHGColors.primary, ring: true).copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: JHGColors.primary.withValues(alpha: 0.65),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.question_mark_rounded,
                      color: Colors.white, size: 15),
                ),
              )
            : null,
      ),
    );
  }

  Widget blackCircle({bool? isColor, required double height}) => Center(
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: isColor == true
                ? const Color(0xFF888888)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget redGreenCircle({
    bool? isColor,
    required color,
    required int index,
    required double height,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: getHighLightBasedOnIndex(index, height)),
        child: Container(
          width: height * 0.030,
          height: height * 0.030,
          decoration: isColor == true
              ? _cleanBall(color is Color ? color : JHGColors.primary)
              : const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
        ),
      );

  Widget stringPress({
    required int index,
    required double height,
    required double width,
  }) =>
      Container(
        width: width * 0.040,
        height: getFretPressBasedOnIndex(index, height),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
      );

  double getHighLightBasedOnIndex(int index, double height) {
    if (index >= 0 && index <= 5) {
      return height * 0.006;
    } else if (index >= 6 && index <= 11) {
      return height * 0.038;
    } else if (index >= 12 && index <= 17) {
      return height * 0.050;
    } else {
      return height * 0.050;
    }
  }

  double getFretPressBasedOnIndex(int index, double height) {
    if (index >= 0 && index <= 5) {
      return height * 0.014;
    } else if (index >= 6 && index <= 11) {
      return height * 0.063;
    } else if (index >= 12 && index <= 17) {
      return height * 0.075;
    } else if (index >= 18 && index <= 23) {
      return height * 0.077;
    } else {
      return height * 0.076;
    }
  }

  double getLandscapeHeight(int index, double height, bool isTablet) {
    switch (index) {
      case 0:
        return isTablet ? height * 0.07 : height * 0.035;
      case 1:
        return isTablet ? height * 0.075 : height * 0.065;
      case 2:
        return isTablet ? height * 0.075 : height * 0.068;
      case 3:
        return isTablet ? height * 0.075 : height * 0.070;
      case 4:
        return isTablet ? height * 0.075 : height * 0.072;
      case 5:
      case 6:
      case 7:
      case 8:
        return isTablet ? height * 0.075 : height * 0.075;
      case 9:
        return isTablet ? height * 0.075 : height * 0.055;
      case 10:
        return isTablet ? height * 0.075 : height * 0.065;
      case 11:
        return isTablet ? height * 0.075 : height * 0.070;
      case 12:
      case 13:
      case 14:
        return isTablet ? height * 0.075 : height * 0.065;
      default:
        return isTablet ? height * 0.075 : height * 0.05;
    }
  }
}

class StringsNameWidget extends StatelessWidget {
  const StringsNameWidget({
    super.key,
    required this.width,
    this.isPortrait,
    this.isTablet,
  });

  final bool? isPortrait;
  final bool? isTablet;
  final double width;

  @override
  Widget build(BuildContext context) {
    bool isLand = false;
    if (isPortrait != null) {
      isLand = !isPortrait!;
    }
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const chipSize = 28.0;
            final leftStringInset = isLand ? 0.0 : 12.0;
            final rightStringInset = isLand ? 0.0 : 12.0;
            final stringSpan =
                constraints.maxWidth - leftStringInset - rightStringInset;

            return SizedBox(
              height: chipSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(AppStrings.guitarStrings.length, (i) {
                  final centerX = leftStringInset +
                      (stringSpan / (AppStrings.guitarStrings.length - 1)) * i;
                  final chip = _StringNameChip(
                    label: AppStrings.guitarStrings[i],
                    size: chipSize,
                  );

                  return Positioned(
                    left: centerX - chipSize / 2,
                    top: 0,
                    child: isPortrait == null
                        ? chip
                        : RotatedBox(
                            quarterTurns: isPortrait! ? 0 : 1,
                            child: chip,
                          ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StringNameChip extends StatelessWidget {
  const _StringNameChip({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: JHGColors.primary.withValues(alpha: 0.24),
        shape: BoxShape.circle,
        border: Border.all(
          color: JHGColors.primary.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: JHGTextStyles.labelStyle.copyWith(
          color: JHGColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// A clean note ball matching the dictionaries / drills apps: a soft top-left
// sheen over the flat base colour and a thin light rim — no heavy glossy sphere
// or drop shadow, so dots read crisp rather than cartoonish. When [ring] is set
// the ball gets a bright white outline (used for the identify-mode target).
BoxDecoration _cleanBall(Color base, {bool ring = false}) {
  final highlight = Color.lerp(base, Colors.white, 0.28)!;
  return BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      center: const Alignment(-0.45, -0.5),
      radius: 1.0,
      colors: [highlight, base],
      stops: const [0.0, 0.6],
    ),
    border: ring
        ? Border.all(color: Colors.white.withValues(alpha: 0.95), width: 2.4)
        : Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.0),
  );
}

// Retained for any external references to the old glossy ball styling.
BoxDecoration glossyBall(Color base) => _cleanBall(base);
