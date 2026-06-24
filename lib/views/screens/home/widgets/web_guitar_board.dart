import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:get/get.dart';

const int _webFretCount = 23;
const double _webParentWidth = 191.0;
const double _webBoardWidth = 178.0;
const double _webFretSpacing = 80.0;
const double _webBoardContentHeight =
    ((_webFretCount - 1) * _webFretSpacing) + 2;
const double _webNutHeight = 15.0;
const double _webStringStartX = 12.0;
const double _webStringGap = 33.5;
const List<double> _webStringWidths = [6, 5, 4, 3, 2, 1];
const List<double> _webLabelCenters = [15.0, 48.5, 82.0, 115.5, 149.0, 182.5];
const List<int> _singleDotFrets = [3, 5, 7, 9, 15, 17, 19, 21];

class WebPortraitGuitarBoard extends StatefulWidget {
  const WebPortraitGuitarBoard({
    super.key,
    this.boardWidth,
    this.boardHeight,
    this.boardContentHeight,
  });

  final double? boardWidth;
  final double? boardHeight;
  final double? boardContentHeight;

  static List<double> stringCenters(double width) {
    return List<double>.from(_webLabelCenters);
  }

  @override
  State<WebPortraitGuitarBoard> createState() => _WebPortraitGuitarBoardState();
}

class _WebPortraitGuitarBoardState extends State<WebPortraitGuitarBoard> {
  final ScrollController _scrollController = ScrollController();
  int? _lastAutoScrollFret;

  // Find the fretList entry nearest to [pos] and fire playSound.
  // Uses nearest-neighbour matching within a 35 px radius so stray taps are
  // ignored; this replaces 96 individual Positioned hit-area widgets, which
  // caused a StackOverflow in the DDC JavaScript engine.
  void _handleBoardTap(Offset pos, HomeController controller) {
    int bestIndex = -1;
    double bestDist = double.infinity;
    for (int i = 0; i < fretList.length; i++) {
      final e = fretList[i];
      final cx = _noteLeft(_stringVisualIndex(e.string!)) + 12.5;
      final cy = _noteTop(e.fret!) + 22.5;
      final dx = pos.dx - cx;
      final dy = pos.dy - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestDist) {
        bestDist = d2;
        bestIndex = i;
      }
    }
    const radius = 35.0;
    if (bestIndex >= 0 && bestDist <= radius * radius) {
      final e = fretList[bestIndex];
      controller.playSound(bestIndex, e.note!, e.string!, e.fretSound!);
    }
  }

  // Scroll so the highlighted fret is vertically centred in the viewport.
  void _scrollToFret(int highlightIndex, double viewportHeight) {
    if (highlightIndex == _lastAutoScrollFret) return;
    _lastAutoScrollFret = highlightIndex;
    final fret = fretList[highlightIndex].fret ?? 0;
    // noteTop is the top edge of the 45 px dot; add 22.5 to get its centre.
    final centre = _noteTop(fret) + 22.5;
    final target = (centre - viewportHeight / 2).clamp(0.0, double.infinity);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final parentWidth = widget.boardWidth ?? _webParentWidth;
    const boardWidth = _webBoardWidth;
    final viewportHeight =
        widget.boardHeight ?? (height * 0.62).clamp(430.0, 760.0).toDouble();
    final boardHeight = widget.boardContentHeight ?? _webBoardContentHeight;
    const nutHeight = _webNutHeight;
    const fretSpacing = _webFretSpacing;
    final stringCenters = WebPortraitGuitarBoard.stringCenters(parentWidth);
    const singleDotX = 2.5 * _webStringGap + 2;
    const doubleDotLeftX = 1.5 * _webStringGap + 2;
    const doubleDotRightX = 3.5 * _webStringGap + 2;

    return GetBuilder<HomeController>(builder: (controller) {
      // Auto-scroll to the highlighted fret in Identify mode.
      if (controller.isStart &&
          controller.currentGameMode.value == 'reverse' &&
          controller.highlightFret != null) {
        _scrollToFret(controller.highlightFret!, viewportHeight);
      } else {
        _lastAutoScrollFret = null;
      }
      return SizedBox(
        height: viewportHeight,
        width: parentWidth + 31,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //fretboard
                Stack(
                  children: [
                    Container(
                      height: boardHeight,
                      width: parentWidth,
                      alignment: Alignment.center,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Column(
                              children: [
                                Center(
                                  child: Container(
                                    width: boardWidth,
                                    height: nutHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      width: boardWidth,
                                      color: const Color(0xfff2e5d9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (int fret = 0; fret < _webFretCount; fret++)
                            Positioned(
                              left: 6,
                              right: 6,
                              top: fretSpacing * fret,
                              child: Container(
                                height: 2,
                                color: fret == 0
                                    ? Colors.transparent
                                    : Colors.grey,
                              ),
                            ),
                          for (int index = 0;
                              index < stringCenters.length;
                              index++)
                            Positioned(
                              top: 0,
                              bottom: 0,
                              left: _webStringStartX + (index * _webStringGap),
                              child: Container(
                                width: _webStringWidths[index],
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: controller.highlightString ==
                                            6 - index
                                        ? [
                                            JHGColors.primary,
                                            JHGColors.primary,
                                          ]
                                        : [
                                            Color.fromRGBO(196, 196, 196, 1),
                                            Color.fromRGBO(196, 196, 196, 1),
                                            Colors.black54,
                                            Colors.black87,
                                          ],
                                  ),
                                ),
                              ),
                            ),
                          for (final fret in _singleDotFrets)
                            _FretMarkerDot(
                              left: singleDotX,
                              top: _fretCenterY(
                                nutHeight,
                                fretSpacing,
                                fret,
                              ),
                            ),
                          _FretMarkerDot(
                            left: doubleDotLeftX,
                            top: _fretCenterY(nutHeight, fretSpacing, 12),
                          ),
                          _FretMarkerDot(
                            left: doubleDotRightX,
                            top: _fretCenterY(nutHeight, fretSpacing, 12),
                          ),
                          // Identify mode: highlight the fret the user must name
                          if (controller.isStart &&
                              controller.currentGameMode.value == 'reverse' &&
                              controller.highlightFret != null)
                            _SelectedNoteDot(
                              left: _noteLeft(_stringVisualIndex(
                                  fretList[controller.highlightFret!].string!)),
                              top: _noteTop(
                                  fretList[controller.highlightFret!].fret!),
                              color: JHGColors.primary,
                            ),

                          if (controller.selectedFret != null &&
                              controller.selectedFret! < fretList.length)
                            _SelectedNoteDot(
                              left: _noteLeft(_stringVisualIndex(
                                  fretList[controller.selectedFret!].string!)),
                              top: _noteTop(
                                  fretList[controller.selectedFret!].fret!),
                              color: controller.selectedColor,
                            ),
                          // Single tap-handler replaces 96 individual
                          // Positioned hit-area widgets. Nearest-neighbour
                          // matching within 35 px; same UX, far shallower tree.
                          Positioned.fill(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTapDown: (d) => _handleBoardTap(
                                    d.localPosition, controller),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                //SPACER
                SizedBox(width: 5),
                // NUMBERS
                Container(
                  height: boardHeight,
                  // color: Colors.red,
                  width: 26,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _FretNumberLabel(number: 0, height: 20),
                      _FretNumberLabel(number: 1, height: 30),
                      for (int fret = 2; fret <= 22; fret++)
                        _FretNumberLabel(
                          number: fret,
                          height: _webFretSpacing,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

int _stringVisualIndex(int stringNumber) => 6 - stringNumber;

double _fretCenterY(double nutHeight, double fretSpacing, int fret) {
  return ((fret - 1) * fretSpacing) + 38;
}

double _noteTop(int fret) {
  if (fret == 0) {
    return -10;
  }
  if (fret == 1) {
    return 18;
  }
  return ((fret - 1) * 81.0) + 10.0;
}

double _noteLeft(int visualStringIndex) {
  return (visualStringIndex * 33.0) + 1;
}

class _FretNumberLabel extends StatelessWidget {
  const _FretNumberLabel({
    required this.number,
    required this.height,
  });

  final int number;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          '$number',
          textAlign: TextAlign.center,
          softWrap: false,
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
              ),
        ),
      ),
    );
  }
}

class _FretMarkerDot extends StatelessWidget {
  const _FretMarkerDot({
    required this.left,
    required this.top,
  });

  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    return Positioned(
      left: left,
      top: top - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: JHGColors.secondryBlack,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SelectedNoteDot extends StatelessWidget {
  const _SelectedNoteDot({
    required this.left,
    required this.top,
    required this.color,
  });

  final double left;
  final double top;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 25,
        height: 45,
        decoration: BoxDecoration(
          color: color ?? JHGColors.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
