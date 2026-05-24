import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:get/get.dart';

class WebPortraitGuitarBoard extends StatefulWidget {
  const WebPortraitGuitarBoard({
    super.key,
    this.boardWidth,
    this.boardHeight,
  });

  final double? boardWidth;
  final double? boardHeight;

  @override
  State<WebPortraitGuitarBoard> createState() => _WebPortraitGuitarBoardState();
}

class _WebPortraitGuitarBoardState extends State<WebPortraitGuitarBoard> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final boardWidth =
        widget.boardWidth ?? (width * 0.13).clamp(210.0, 230.0).toDouble();
    final boardHeight =
        widget.boardHeight ?? (height * 0.52).clamp(430.0, 540.0).toDouble();
    return GetBuilder<HomeController>(builder: (controller) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //fretboard
          Stack(
            children: [
              Container(
                height: boardHeight,
                width: boardWidth,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // BOARD SIZE WITH COLOR
                    Column(
                      children: [
                        SizedBox(
                          height: boardHeight * 0.026,
                        ),
                        Expanded(
                          child: Container(
                            width: boardWidth,
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
                            width: boardWidth,
                            height: boardHeight * 0.026,
                            decoration: BoxDecoration(
                                color: JHGColors.black,
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                )),
                          ),
                        )),

                    // BLACK CIRCE
                    Align(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 13),
                            padding: EdgeInsets.only(
                              top: getPortraitBlackSpace(index, boardHeight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: blackPortraitCircle(
                                  height: boardHeight,
                                  isColor: index == 11,
                                )),
                                Expanded(child: SizedBox.shrink()),
                                Expanded(
                                    child: blackPortraitCircle(
                                        height: boardHeight,
                                        isColor: index == 2 ||
                                            index == 4 ||
                                            index == 6 ||
                                            index == 8 ||
                                            index == 14)),
                                Expanded(child: SizedBox.shrink()),
                                Expanded(
                                    child: blackPortraitCircle(
                                        height: boardHeight,
                                        isColor: index == 11)),
                              ],
                            ),
                          );
                        },
                        itemCount: 15,
                      ),
                    ),

                    // ROW
                    Align(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        itemCount: 15,
                        shrinkWrap: true,
                        primary: false,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, pos) {
                          return rowPortraitDivider(boardHeight, pos);
                        },
                      ),
                    ),

                    // COLUMN
                    RotatedBox(
                      quarterTurns: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return colPortraitDivider(
                              boardWidth, index, controller.highlightString);
                        }),
                      ),
                    ),

                    Align(
                        alignment: Alignment.topCenter,
                        child: AlignedGridView.count(
                          itemCount: 96,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 6,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 10,
                          itemBuilder: (context, index) {
                            return redGreenPortraitCircle(
                                isColor: controller.selectedFret == index,
                                color: controller.selectedColor,
                                index: index,
                                height: boardHeight);
                          },
                        )),

                    // /// Fret press With Grid
                    // ///===========================================================
                    Align(
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
                          return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  controller.playSound(
                                      index,
                                      noteIndex.note!,
                                      noteIndex.string!,
                                      fretList[index].fretSound!);
                                },
                                child: stringPortraitPress(
                                    index: index,
                                    height: boardHeight,
                                    width: boardWidth),
                              ));
                        },
                      ),
                    ),

                    // ///===========================================================
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
            width: 18,
            child: ListView.builder(
              itemCount: 16,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return numberPortrait(boardHeight, index);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget numberPortrait(double height, int index) {
    return Padding(
      padding: EdgeInsets.only(top: getNumberPortraitSpace(index, height)),
      child: Container(
          child: RotatedBox(
        quarterTurns: 0,
        child: Text(
          index.toString(),
          style: JHGTextStyles.subLabelStyle.copyWith(fontSize: height * 0.022),
        ),
      )),
    );
  }

  Widget rowPortraitDivider(double height, int index) {
    return Padding(
      padding: EdgeInsets.only(top: getPortraitSpace(index, height)),
      child: Container(
        height: height * 0.003,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.whiteLight,
                AppColors.whiteLight,
                JHGColors.charcolGray,
                JHGColors.secondryBlack
              ]),
        ),
      ),
    );
  }

  Widget colPortraitDivider(double width, int index, int? selectedString) {
    return Padding(
      padding: EdgeInsets.only(
          left: index == 0 ? 12 : 0, right: index == 5 ? 12 : 0),
      child: Container(
        width: index == 6
            ? width * 0.0045
            : index == 5
                ? width * 0.0040
                : index == 4
                    ? width * 0.0035
                    : index == 3
                        ? width * 0.0030
                        : index == 2
                            ? width * 0.0025
                            : width * 0.002,
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
                      JHGColors.secondryBlack
                    ]),
        ),
      ),
    );
  }

  Widget blackPortraitCircle({bool? isColor, required double height}) =>
      Container(
        width: height * 0.022,
        height: height * 0.022,
        decoration: BoxDecoration(
          color: isColor == true ? JHGColors.secondryBlack : Colors.transparent,
          shape: BoxShape.circle,
        ),
      );

  Widget redGreenPortraitCircle(
          {bool? isColor,
          required color,
          required int index,
          required double height}) =>
      Padding(
        padding: EdgeInsets.only(
            bottom: getPortraitHighLightBasedOnIndex(index, height)),
        child: Container(
          width: height * 0.028,
          height: height * 0.028,
          decoration: BoxDecoration(
            color: isColor == true ? color : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget stringPortraitPress({
    required int index,
    required double height,
    required double width,
  }) =>
      Container(
        width: width * 0.040,
        height: getPortraitFretPressBasedOnIndex(index, height),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
      );

  double getPortraitHighLightBasedOnIndex(int index, double height) {
    if (index >= 0 && index <= 5) {
      return height * 0.008;
    } else if (index >= 6 && index <= 11) {
      return height * 0.038;
    } else if (index >= 12 && index <= 17) {
      return height * 0.045;
    } else if (index >= 18 && index <= 23) {
      return height * 0.045;
    } else if (index >= 24 && index <= 29) {
      return height * 0.042;
    } else if (index >= 30 && index <= 35) {
      return height * 0.038;
    } else if (index >= 36 && index <= 41) {
      return height * 0.038;
    } else if (index >= 42 && index <= 47) {
      return height * 0.035;
    } else if (index >= 48 && index <= 53) {
      return height * 0.031;
    } else if (index >= 54 && index <= 59) {
      return height * 0.031;
    } else if (index >= 60 && index <= 65) {
      return height * 0.028;
    } else if (index >= 66 && index <= 71) {
      return height * 0.028;
    } else if (index >= 72 && index <= 77) {
      return height * 0.024;
    } else if (index >= 78 && index <= 83) {
      return height * 0.024;
    } else if (index >= 84 && index <= 89) {
      return height * 0.024;
    } else {
      return height * 0.024;
    }
  }

  double getNumberPortraitSpace(
    int index,
    double height,
  ) {
    switch (index) {
      case 0:
        return height * 0.000;
      case 1:
        return height * 0.010;
      case 2:
        return height * 0.040;
      case 3:
        return height * 0.042;
      case 4:
        return height * 0.044;
      case 5:
        return height * 0.043;
      case 6:
        return height * 0.038;
      case 7:
        return height * 0.035;
      case 8:
        return height * 0.034;
      case 9:
        return height * 0.034;
      case 10:
        return height * 0.030;
      case 11:
        return height * 0.027;
      case 12:
        return height * 0.026;
      case 13:
        return height * 0.023;
      case 14:
        return height * 0.020;
      case 15:
        return height * 0.019;
      default:
        return height * 0.034;
    }
  }

  double getPortraitSpace(
    int index,
    double height,
  ) {
    switch (index) {
      case 0:
        return height * 0.068;
      case 1:
        return height * 0.066;
      case 2:
        return height * 0.063;
      case 3:
        return height * 0.061;
      case 4:
        return height * 0.059;
      case 5:
        return height * 0.057;
      case 6:
        return height * 0.055;
      case 7:
        return height * 0.053;
      case 8:
        return height * 0.051;
      case 9:
        return height * 0.048;
      case 10:
        return height * 0.046;
      case 11:
        return height * 0.044;
      case 12:
        return height * 0.042;
      case 13:
        return height * 0.040;
      case 14:
        return height * 0.038;
      case 15:
        return height * 0.036;
      default:
        return height * 0.034;
    }
  }

  double getPortraitBlackSpace(
    int index,
    double height,
  ) {
    if (index == 0) {
      return height * 0.040;
    } else if (index == 1) {
      return height * 0.042;
    } else if (index == 2) {
      return height * 0.048;
    } else if (index == 3) {
      return height * 0.049;
    } else if (index == 4) {
      return height * 0.048;
    } else if (index == 5) {
      return height * 0.044;
    } else if (index == 6) {
      return height * 0.042;
    } else if (index == 7) {
      return height * 0.041;
    } else if (index == 8) {
      return height * 0.037;
    } else if (index == 9) {
      return height * 0.035;
    } else if (index == 10) {
      return height * 0.032;
    } else if (index == 11) {
      return height * 0.032;
    } else if (index == 12) {
      return height * 0.028;
    } else if (index == 13) {
      return height * 0.028;
    } else if (index == 14) {
      return height * 0.025;
    } else {
      return height * 0.025;
    }
  }

  double getPortraitFretPressBasedOnIndex(int index, double height) {
    if (index >= 0 && index <= 5) {
      return height * 0.015;
    } else if (index >= 6 && index <= 11) {
      return height * 0.052;
    } else if (index >= 12 && index <= 17) {
      return height * 0.066;
    } else if (index >= 18 && index <= 23) {
      return height * 0.063;
    } else if (index >= 24 && index <= 29) {
      return height * 0.060;
    } else if (index >= 30 && index <= 35) {
      return height * 0.060;
    } else if (index >= 36 && index <= 41) {
      return height * 0.056;
    } else if (index >= 42 && index <= 47) {
      return height * 0.055;
    } else if (index >= 48 && index <= 53) {
      return height * 0.053;
    } else if (index >= 54 && index <= 59) {
      return height * 0.050;
    } else if (index >= 60 && index <= 65) {
      return height * 0.048;
    } else if (index >= 66 && index <= 71) {
      return height * 0.047;
    } else if (index >= 72 && index <= 77) {
      return height * 0.044;
    } else if (index >= 78 && index <= 83) {
      return height * 0.042;
    } else if (index >= 84 && index <= 89) {
      return height * 0.041;
    } else {
      return height * 0.039;
    }
  }

  double getPotraitHeight(int index, double height) {
    switch (index) {
      case 0:
        return height * 0.020;
      case 1:
        return height * 0.058;
      case 2:
        return height * 0.065;
      case 3:
        return height * 0.065;
      case 4:
        return height * 0.060;
      case 5:
        return height * 0.060;
      case 6:
        return height * 0.060;
      case 7:
        return height * 0.048;
      case 8:
        return height * 0.045;
      case 9:
        return height * 0.043;
      case 10:
        return height * 0.042;
      case 11:
        return height * 0.040;
      case 12:
        return height * 0.038;
      case 13:
        return height * 0.036;
      case 14:
        return height * 0.034;
      default:
        return height * 0.00;
    }
  }
}
