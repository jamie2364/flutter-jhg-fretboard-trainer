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

// Note colour when the ball is NOT a root — a neutral grey, matching the
// dictionaries / drills fretboard (root = coral, every other note = grey).
const Color _kNoteGrey = Color(0xFF888888);
// Distinct pure red for the wrong-tap flash (stands apart from the coral notes).
const Color _kFlashRed = Color(0xFFE53935);
// Muted-string "×" colour — a clear blue so the open-string mutes read against
// the dark nut (they were near-invisible white38 before).
const Color _kMutedBlue = Color(0xFF5AA9FF);
// Dimmed look for a string the user has switched off (chip + wire).
const Color _kStringOffText = Color(0xFF6E6E6E);

// Ball top so the 28px ball sits in the MIDDLE of fret [fret]'s playing area
// (between wire F-1 and wire F), NOT on the wire itself — pixel-identical to the
// dictionaries / drills `bouncingBall`: fret F ⇒ top = 26 + (F-1)*80, so the
// ball's centre lands at (F-1)*80 + 40, the centre of the fret space. Fret 1 is
// nudged down (nut takes the top 14px) and the open string sits at the nut.
double _ballTopFor(int fret) {
  if (fret == 0) return 2.0;
  if (fret == 1) return 34.0;
  return 26.0 + (fret - 1) * _kFretSpacing;
}

// Ball centre (y) for a fret — used to build tap cells that track the balls.
double _ballCenterFor(int fret) => _ballTopFor(fret) + _kBallRadius;

// Tappable cell for a fret. Its bounds are the midpoints to the neighbouring
// frets' ball centres, so every cell is centred on its ball and adjacent cells
// tile the neck without overlapping.
double _cellTopFor(int fret) {
  if (fret == 0) return 0.0;
  return (_ballCenterFor(fret - 1) + _ballCenterFor(fret)) / 2;
}

double _cellHeightFor(int fret) {
  final bottom = (_ballCenterFor(fret) + _ballCenterFor(fret + 1)) / 2;
  return bottom - _cellTopFor(fret);
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
  // Signature (minFret*100 + maxFret) of the note band last scrolled to, so an
  // unrelated update() that leaves the shown notes unchanged doesn't re-scroll.
  int? _lastScrollSig;

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

  // Fret numbers (0-15) of every note currently drawn on the board, so the
  // auto-scroll can keep as many as possible in view. Empty ⇒ nothing to show
  // (find mode / idle), so the board rests at the top (the open strings).
  List<int> _activeFrets(HomeController c) {
    if (!c.isStart) return const [];
    int? fretOf(int? index) =>
        (index == null || index < 0 || index >= fretList.length)
            ? null
            : (fretList[index].fret ?? index ~/ 6);

    final frets = <int>[];
    void add(int? index) {
      final f = fretOf(index);
      if (f != null) frets.add(f);
    }

    final mode = c.currentGameMode.value;
    if (mode == 'reverse') {
      add(c.highlightFret);
    } else if (mode == 'interval') {
      add(c.intervalRootIndex);
      if (!c.isIntervalBuild) add(c.intervalTargetIndex);
      add(c.intervalBuildRevealIndex);
    } else if (c.isChordName && c.chordPrompt != null) {
      for (final f in c.chordPrompt!.frets) {
        if (f != null) frets.add(f);
      }
    } else if (c.isChordBuild) {
      for (final idx in c.chordTapped) {
        add(idx);
      }
      final reveal = c.chordBuildReveal;
      if (reveal != null) {
        for (final idx in reveal) {
          add(idx);
        }
      }
    } else if (c.isChordLab) {
      final p = c.chordLabPrompt;
      if (p != null) {
        if (p.round == ChordLabRound.name) {
          for (final f in p.target.frets) {
            if (f != null) frets.add(f);
          }
        } else {
          for (final idx in c.chordLabActive) {
            add(idx);
          }
          if (p.regionLo != null) frets.add(p.regionLo!);
          if (p.regionHi != null) frets.add(p.regionHi!);
        }
      }
    }
    return frets;
  }

  // Called inside GetBuilder.builder after every update(). Scrolls so the band
  // of currently-shown notes is centred in the viewport — keeping the whole
  // chord / interval in view where it fits, and as much as possible when it
  // doesn't. Find mode and idle rest at the top.
  void _scrollToFret(HomeController controller) {
    final frets = _activeFrets(controller);

    if (frets.isEmpty) {
      // Nothing highlighted → return to the top (open strings).
      if (_lastScrollSig != null) {
        _lastScrollSig = null;
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

    int minF = frets.first, maxF = frets.first;
    for (final f in frets) {
      if (f < minF) minF = f;
      if (f > maxF) maxF = f;
    }
    final sig = minF * 100 + maxF;
    if (sig == _lastScrollSig) return; // same note band — no scroll needed
    _lastScrollSig = sig;

    // The note that MUST stay on screen when the whole band can't fit: the
    // interval root (so it's always visible even across an octave gap), or the
    // identify target. Chords are compact enough to just centre the band.
    int? anchorFret;
    final mode = controller.currentGameMode.value;
    if (mode == 'interval' && controller.intervalRootIndex != null) {
      anchorFret = fretList[controller.intervalRootIndex!].fret ?? 0;
    } else if (mode == 'reverse' && controller.highlightFret != null) {
      anchorFret = fretList[controller.highlightFret!].fret ?? 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;
      final viewport = _scrollController.position.viewportDimension;

      if (widget.isPortrait) {
        final bandTop = _cellTopFor(minF);
        final bandBottom = _cellTopFor(maxF) + _cellHeightFor(maxF);
        double offset;

        if (bandBottom - bandTop <= viewport || anchorFret == null) {
          // Whole band fits (or nothing special to anchor): centre it.
          offset = (bandTop + bandBottom) / 2 - viewport / 2;
        } else {
          // Band taller than the screen: keep the anchor note on screen and
          // show as much of the neck toward the far note as fits. Push the
          // anchor to the near edge so the gap fills the rest of the viewport.
          final anchorCenter =
              _cellTopFor(anchorFret) + _cellHeightFor(anchorFret) / 2;
          final farBelow = maxF > anchorFret; // a note higher up the neck
          final farAbove = minF < anchorFret; // a note lower down the neck
          if (farBelow && !farAbove) {
            offset = anchorCenter - viewport * 0.18; // anchor near the top
          } else if (farAbove && !farBelow) {
            offset = anchorCenter - viewport * 0.82; // anchor near the bottom
          } else {
            offset = anchorCenter - viewport / 2; // notes both sides — centre it
          }
        }

        _scrollController.animateTo(
          offset.clamp(0.0, maxExtent),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOut,
        );
        return;
      }
      // Legacy (landscape) estimate: 16 fret rows fill the total content.
      final rowHeight = (maxExtent + viewport) / 16.0;
      final bandCenter = ((minF + maxF) / 2 + 0.5) * rowHeight;
      _scrollController.animateTo(
        (bandCenter - viewport / 2).clamp(0.0, maxExtent),
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
    final bool isChordLab = controller.isChordLab;

    // Notes (find / identify) and interval modes let the player narrow the neck
    // to a chosen set of strings, so the string chips become live toggles and
    // the muted strings dim. Chord modes use fixed shapes, so their chips stay
    // static (dimming a string a chord actually uses would just mislead).
    final bool stringSelectable = !isChord;
    // Chord Lab is board-interactive on every round except Name (answered on
    // the choice grid).
    final bool isChordLabBoard = isChordLab &&
        controller.chordLabPrompt != null &&
        controller.chordLabPrompt!.round != ChordLabRound.name;

    // Board taps are live in find mode and in the BUILD variants of interval /
    // chord (where the user taps to answer). Identify and the NAME variants
    // answer with buttons instead.
    final bool tapMode = controller.isStart &&
        (isIntervalBuild ||
            isChordBuild ||
            isChordLabBoard ||
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
            child: _stringLabelsRow(controller, interactive: stringSelectable),
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
                              _string(col, highlightString,
                                  dim: stringSelectable &&
                                      !controller.isStringOn(6 - col)),

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
                                color: _kNoteGrey,
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

                            // Chord BUILD: a correct shape revealed in green,
                            // each note labelled so the answer is a teachable
                            // moment rather than just dots.
                            if (showChordReveal)
                              for (final idx in controller.chordBuildReveal!)
                                _noteBall(
                                  index: idx,
                                  color: JHGColors.green,
                                  label: fretList[idx].note,
                                ),

                            // Chord Lab: given/placed notes (+ region band for
                            // the Build round; full shape for the Name round).
                            if (isChordLab && controller.isStart)
                              ..._chordLabWidgets(controller),

                            // Transparent tap targets — MUST be the topmost
                            // layer so taps land on notes too (e.g. removing a
                            // note in Chord Lab), not get absorbed by the balls
                            // painted above the cells.
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
  // When [interactive] (notes / interval modes) each chip is a live toggle for
  // its string: tap to include/exclude it. An excluded string greys out so the
  // player can see at a glance which strings are in play.
  Widget _stringLabelsRow(HomeController c, {required bool interactive}) {
    const chipSize = 22.0;
    const stringCenters = [15.0, 48.5, 82.0, 115.5, 149.0, 182.5];

    return SizedBox(
      height: 30,
      width: _kBoardWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < _kOpenStringLabels.length; i++)
            () {
              // Column i (left→right) is low-E→high-e, i.e. string number 6-i.
              final stringNumber = 6 - i;
              final on = !interactive || c.isStringOn(stringNumber);
              final chip = AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: chipSize,
                height: chipSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? JHGColors.primary.withValues(alpha: 0.24)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on
                        ? JHGColors.primary.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.12),
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
                      style: TextStyle(
                        color: on ? Colors.white : _kStringOffText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              );
              return Positioned(
                // Shift back by the 4px hit-target padding so the chip stays
                // centred on its string when it's interactive.
                left: stringCenters[i] - (chipSize / 2) - (interactive ? 4 : 0),
                top: interactive ? -4 : 0,
                child: interactive
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => c.setStringActive(
                            stringNumber, !c.isStringOn(stringNumber)),
                        // A little padding grows the tap target past the 22px chip.
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: chip,
                        ),
                      )
                    : chip,
              );
            }(),
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

    // Inlay for fret (i+1) sits in the MIDDLE of that fret's playing area (the
    // 9px dot's centre lands at i*80 + 40.5), matching the dictionaries board.
    final double markerTop = i * _kFretSpacing + 36.0;
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
  // [dim] fades a string the player has switched off, so an excluded string is
  // visibly out of play (paired with the greyed string chip above the neck).
  Widget _string(int col, int? highlightString, {bool dim = false}) {
    final double thickness = 3.5 - col * 0.5;
    final int stringNumber = 6 - col; // col 0 = low E (string 6)
    final bool highlighted = highlightString == stringNumber;
    return Positioned(
      top: 0,
      bottom: 0,
      left: col * _kStringSpacing,
      child: Padding(
        padding: EdgeInsets.only(left: 12.0 - thickness / 2),
        child: Opacity(
          opacity: dim ? 0.28 : 1.0,
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
          } else if (controller.isChordLab) {
            controller.chordLabTap(index);
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
  // Pass [label] to print a note name inside the ball (used so chord shapes show
  // every note, not just the root).
  Widget _noteBall({required int index, required Color color, String? label}) {
    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    final col = index % 6;
    return Positioned(
      top: _ballTopFor(fret),
      left: _ballLeftFor(col),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: _cleanBall(color),
        child: label == null
            ? null
            : Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: label.length > 1 ? 10 : 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
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
      // Every sounding note is labelled with its name — the root keeps its coral
      // ring so it still stands out, the rest are grey.
      widgets.add(isRoot
          ? _rootBall(index, label: shape.root)
          : _noteBall(
              index: index, color: _kNoteGrey, label: fretList[index].note));
    }
    return widgets;
  }

  // ── Chord Lab: given notes (grey, locked), placed notes (coral → green on a
  // win), and a translucent region band for the Build round ──────────────────
  List<Widget> _chordLabWidgets(HomeController c) {
    final p = c.chordLabPrompt;
    if (p == null) return const [];
    // Name round draws the full shape, exactly like Chord Name mode.
    if (p.round == ChordLabRound.name) return _chordShapeWidgets(p.target);

    final out = <Widget>[];
    if (p.round == ChordLabRound.build &&
        p.regionLo != null &&
        p.regionHi != null) {
      out.add(_regionBand(p.regionLo!, p.regionHi!));
    }
    final done = c.chordLabDone;
    final flash = c.chordLabFlashIndex;
    for (final idx in c.chordLabActive) {
      if (idx < 0 || idx >= fretList.length) continue;
      final locked = p.locked.contains(idx);
      out.add(_noteBall(
        index: idx,
        color: idx == flash
            ? _kFlashRed
            : done
                ? JHGColors.green
                : (locked ? _kNoteGrey : JHGColors.primary),
      ));
    }
    // Complete / Build: a wrongly-tapped empty fret flashes red briefly.
    if (flash != null &&
        !c.chordLabActive.contains(flash) &&
        flash >= 0 &&
        flash < fretList.length) {
      out.add(_noteBall(index: flash, color: _kFlashRed));
    }
    return out;
  }

  Widget _regionBand(int lo, int hi) {
    final top = _cellTopFor(lo);
    final bottom = _cellTopFor(hi) + _cellHeightFor(hi);
    return Positioned(
      top: top,
      left: 0,
      width: _kBoardWidth,
      height: bottom - top,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: JHGColors.primary.withValues(alpha: 0.10),
            border: Border.symmetric(
              horizontal: BorderSide(
                color: JHGColors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Root ball: coral with a white ring so the chord root reads. Labelled with
  // the root's note name (falls back to "R" if none is supplied). ─────────────
  Widget _rootBall(int index, {String? label}) {
    final model = fretList[index];
    final fret = model.fret ?? (index ~/ 6);
    final col = index % 6;
    final text = (label == null || label.isEmpty) ? 'R' : label;
    return Positioned(
      top: _ballTopFor(fret) - 1.5,
      left: _ballLeftFor(col) - 1.5,
      child: Container(
        width: 31,
        height: 31,
        alignment: Alignment.center,
        decoration: _cleanBall(JHGColors.primary, ring: true),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: text.length > 1 ? 11 : 12.5,
                fontWeight: FontWeight.w800,
                height: 1)),
      ),
    );
  }

  // ── Muted-string "×" drawn at the nut for that string ───────────────────────
  // Rendered in a clear blue with extra weight so the open-string mutes actually
  // read against the dark nut (they were near-invisible white before).
  Widget _mutedMarker(int col) {
    return Positioned(
      top: _ballTopFor(0),
      left: _ballLeftFor(col),
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Text('✕',
              style: TextStyle(
                  color: _kMutedBlue,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
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
                SizedBox(
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
