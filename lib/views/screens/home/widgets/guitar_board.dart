import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

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
    final fret = controller.highlightFret;
    final isIdentify = controller.currentGameMode.value == 'reverse';

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
      // Estimate: 16 fret rows fill totalContent (maxExtent + viewport)
      final rowHeight = (maxExtent + viewport) / 16.0;
      // Target: center the row vertically
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
    bool isTablet =
        MediaQuery.of(context).size.width < 1100 &&
        MediaQuery.of(context).size.width >= 701 &&
        !kIsWeb;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final boardWidthFactor = isPortrait
        ? isTablet
              ? 0.3
              : 0.46
        : isTablet
        ? 0.3
        : 0.47;
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        _scrollToFret(controller);
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
                  // Explicit height = 16 fret rows × (h*0.076 spacing + h*0.0038 bar)
                  // = h*1.2768 for row dividers, plus h*0.088 bottom-fret padding
                  // = h*1.352 total content. Use h*1.36 for a tiny buffer.
                  Container(
                    width: width * boardWidthFactor,
                    height: height * 1.24,
                    alignment: Alignment.topCenter,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // BOARD SIZE WITH COLOR
                        Column(
                          children: [
                            SizedBox(height: height * 0.015),
                            Expanded(
                              child: Container(
                                width: width * 0.8,
                                color: AppColors.creamColor,
                              ),
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
                              decoration: BoxDecoration(
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
                                margin: EdgeInsets.symmetric(horizontal: 11),
                                height: height * 0.077,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: blackCircle(
                                        height: height,
                                        isColor: index == 11,
                                      ),
                                    ),
                                    Expanded(child: SizedBox.shrink()),
                                    Expanded(
                                      child: blackCircle(
                                        height: height,
                                        isColor:
                                            index == 2 ||
                                            index == 4 ||
                                            index == 6 ||
                                            index == 8 ||
                                            index == 14,
                                      ),
                                    ),
                                    Expanded(child: SizedBox.shrink()),
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
                              itemBuilder: (context, index) =>
                                  reverseTargetCircle(
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
                  SizedBox(width: 20),
                  // NUMBERS
                  // Portrait: labels "1"-"15", each exactly one fret row tall
                  // (h*0.0798 = h*0.076 spacing + h*0.0038 bar), text centered.
                  // Label N is then centered in fret N's playing area so
                  // position dots align with their correct number.
                  // Landscape: keep existing offset-based spacing.
                  Container(
                    width: width * 0.06,
                    child: ListView.builder(
                      itemCount: widget.isPortrait ? 16 : 16,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (widget.isPortrait) {
                          // index 0 → "0" (nut/open string) at nut-cap height
                          // indices 1-15 → "1"-"15" at one full fret-row height
                          // so label N is centered in fret N's playing area
                          if (index == 0) {
                            return SizedBox(
                              height: height * 0.015,
                              child: Center(
                                child: Text(
                                  '0',
                                  style: JHGTextStyles.lrlabelStyle.copyWith(
                                    fontSize: 11,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            );
                          }
                          return SizedBox(
                            height: height * 0.0798,
                            child: Center(
                              child: Text(
                                index.toString(),
                                style: JHGTextStyles.lrlabelStyle.copyWith(
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          );
                        }
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
              ),  // SingleChildScrollView
            ),    // Expanded
          ],
        );       // Column
      },
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
    final size = height * 0.038;
    return Padding(
      padding: EdgeInsets.only(bottom: getHighLightBasedOnIndex(index, height)),
      child: isTarget
          ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.30),
                shape: BoxShape.circle,
                border: Border.all(color: JHGColors.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: JHGColors.primary.withValues(alpha: 0.55),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
            )
          : SizedBox(width: size, height: size),
    );
  }

  Widget blackCircle({bool? isColor, required double height}) => Center(
    child: Container(
      width: height * 0.024,
      height: height * 0.024,
      decoration: BoxDecoration(
        color: isColor == true ? JHGColors.secondryBlack : Colors.transparent,
        shape: BoxShape.circle,
      ),
    ),
  );

  Widget redGreenCircle({
    bool? isColor,
    required color,
    required int index,
    required double height,
  }) => Padding(
    padding: EdgeInsets.only(bottom: getHighLightBasedOnIndex(index, height)),
    child: Container(
      width: height * 0.030,
      height: height * 0.030,
      decoration: BoxDecoration(
        color: isColor == true ? color : Colors.transparent,
        //color: Colors.red,
        shape: BoxShape.circle,
      ),
      // child: Text("${fretList[index].note}",style: TextStyle(color: Colors.red),),
    ),
  );

  Widget stringPress({
    required int index,
    required double height,
    required double width,
  }) => Container(
    width: width * 0.040,
    height: getFretPressBasedOnIndex(index, height),
    decoration: BoxDecoration(
      color: Colors.transparent,
      // color: Colors.green.withOpacity(0.5)
    ),
  );

  double getHighLightBasedOnIndex(int index, double height) {
    if (index >= 0 && index <= 5) {
      return height * 0.006;
    } else if (index >= 6 && index <= 11) {
      return height * 0.038;
    } else if (index >= 12 && index <= 17) {
      return height * 0.050;
    } else if (index >= 18 && index <= 23) {
      return height * 0.050;
    } else if (index >= 24 && index <= 29) {
      return height * 0.050;
    } else if (index >= 30 && index <= 35) {
      return height * 0.050;
    } else if (index >= 36 && index <= 41) {
      return height * 0.050;
    } else if (index >= 42 && index <= 47) {
      return height * 0.050;
    } else if (index >= 48 && index <= 53) {
      return height * 0.050;
    } else if (index >= 54 && index <= 59) {
      return height * 0.050;
    } else if (index >= 60 && index <= 65) {
      return height * 0.050;
    } else if (index >= 66 && index <= 71) {
      return height * 0.050;
    } else if (index >= 72 && index <= 77) {
      return height * 0.050;
    } else if (index >= 78 && index <= 83) {
      return height * 0.050;
    } else if (index >= 84 && index <= 89) {
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
    } else if (index >= 24 && index <= 29) {
      return height * 0.077;
    } else if (index >= 30 && index <= 35) {
      return height * 0.076;
    } else if (index >= 36 && index <= 41) {
      return height * 0.076;
    } else if (index >= 42 && index <= 47) {
      return height * 0.077;
    } else if (index >= 48 && index <= 53) {
      return height * 0.076;
    } else if (index >= 54 && index <= 59) {
      return height * 0.076;
    } else if (index >= 60 && index <= 65) {
      return height * 0.076;
    } else if (index >= 66 && index <= 71) {
      return height * 0.076;
    } else if (index >= 72 && index <= 77) {
      return height * 0.076;
    } else if (index >= 78 && index <= 83) {
      return height * 0.076;
    } else if (index >= 84 && index <= 89) {
      return height * 0.076;
    } else {
      return height * 0.076;
    }
  }

  double getPotraitHeight(int index, double height, bool isTablet) {
    switch (index) {
      case 0:
        return isTablet ? height * 0.06 : height * 0.015;
      case 1:
        return isTablet ? height * 0.07 : height * 0.055;
      case 2:
        return isTablet ? height * 0.068 : height * 0.065;
      case 3:
        return isTablet ? height * 0.07 : height * 0.065;
      case 4:
        return isTablet ? height * 0.065 : height * 0.056;
      case 5:
      case 6:
      case 7:
        return isTablet ? height * 0.065 : height * 0.062;
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
        return isTablet ? height * 0.07 : height * 0.061;
      default:
        return isTablet ? height * 0.07 : height * 0.055;
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
        padding: EdgeInsets.only(
          bottom: 10,
          left: isLand ? 0 : 0,
          right: isLand ? 0 : 0,
        ),
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
                  final centerX =
                      leftStringInset +
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
        color: JHGColors.charcolGray,
        shape: BoxShape.circle,
        border: Border.all(
          color: JHGColors.primary.withValues(alpha: 0.75),
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
