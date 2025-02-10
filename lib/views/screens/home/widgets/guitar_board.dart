import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class GuitarBoard extends StatefulWidget {
  const GuitarBoard({super.key, required this.isPortrait});
  final bool isPortrait;
  @override
  State<GuitarBoard> createState() => _GuitarBoardAltState();
}

class _GuitarBoardAltState extends State<GuitarBoard> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return GetBuilder<HomeController>(
        init: HomeController(),
        builder: (controller) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: height * 0.0),
            child: SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // fretboard
                  Container(
                    width: width * 0.48,
                    constraints: BoxConstraints(maxHeight: height * 1.2),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // BOARD SIZE WITH COLOR
                        Column(
                          children: [
                            SizedBox(
                              height: height * 0.015,
                            ),
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
                                      bottomRight: Radius.circular(10))),
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
                                height: height * 0.077,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    blackCircle(
                                      height: height,
                                      isColor: index == 11 ? true : false,
                                    ),
                                    SizedBox(
                                      width: index == 11
                                          ? width * 0.073
                                          : width * 0.089,
                                    ),
                                    blackCircle(
                                        height: height,
                                        isColor: index == 2 ||
                                                index == 4 ||
                                                index == 6 ||
                                                index == 8 ||
                                                index == 14
                                            ? true
                                            : false),
                                    SizedBox(
                                      width: index == 11
                                          ? width * 0.070
                                          : width * 0.089,
                                    ),
                                    blackCircle(
                                        height: height,
                                        isColor: index == 11 ? true : false),
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
                          child: ListView.builder(
                            itemCount: 6,
                            shrinkWrap: false,
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return colDivider(
                                  width, index, controller.highlightString);
                            },
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
                                  isColor: controller.selectedFret == index
                                      ? true
                                      : false,
                                  color: controller.selectedColor,
                                  // controller.selectedNote == controller.previousHighlightNode
                                  //     ? JHGColors.green
                                  //     : JHGColors.primary,
                                  index: index,
                                  height: height);
                            },
                          ),
                        ),

                        /// Fret press With Grid
                        ///===========================================================

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
                              // final sound = fretList[index].fretSound;
                              return GestureDetector(
                                onTap: () {
                                  controller.playSound(
                                      index,
                                      noteIndex.note!,
                                      noteIndex.string!,
                                      fretList[index].fretSound!);
                                },
                                child: stringPress(
                                    index: index, height: height, width: width),
                              );
                            },
                          ),
                        ),

                        ///===========================================================
                      ],
                    ),
                  ),
                  //SPACER
                  SizedBox(
                    width: width * 0.05,
                  ),
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
                            bottom: widget.isPortrait == true
                                ? getPotraitHeight(index, height)
                                : getLandscapeHeight(index, height),
                          ),
                          child: RotatedBox(
                            quarterTurns: widget.isPortrait ? 0 : 1,
                            child: Text(
                              index.toString(),
                              style: JHGTextStyles.lrlabelStyle.copyWith(
                                fontSize: 14,
                                height: widget.isPortrait == true ? 1.2 : 2,
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
          );
        });
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
                JHGColors.secondryBlack
              ]),
        ),
      ),
    );
  }

  Widget colDivider(double width, int index, int? selectedString) {
    return Padding(
      padding:
          EdgeInsets.only(left: index == 0 ? width * 0.028 : width * 0.076),
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
                      JHGColors.secondryBlack
                    ]),
        ),
      ),
    );
  }

  Widget blackCircle({bool? isColor, required double height}) => Container(
        width: height * 0.024,
        height: height * 0.024,
        decoration: BoxDecoration(
          color: isColor == true ? JHGColors.secondryBlack : Colors.transparent,
          shape: BoxShape.circle,
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
  }) =>
      Container(
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

  double getPotraitHeight(int index, double height) {
    switch (index) {
      case 0:
        return height * 0.025;
      case 1:
        return height * 0.05;
      case 2:
        return height * 0.055;
      case 3:
        return height * 0.060;
      case 4:
        return height * 0.056;
      case 5:
      case 6:
      case 7:
        return height * 0.062;
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
        return height * 0.060;
      default:
        return height * 0.05;
    }
  }

  double getLandscapeHeight(int index, double height) {
    switch (index) {
      case 0:
        return height * 0.035;
      case 1:
        return height * 0.060;
      case 2:
        return height * 0.065;
      case 3:
        return height * 0.070;
      case 4:
        return height * 0.072;
      case 5:
      case 6:
      case 7:
      case 8:
        return height * 0.072;
      case 9:
        return height * 0.050;
      case 10:
        return height * 0.055;
      case 11:
        return height * 0.060;
      case 12:
      case 13:
      case 14:
        return height * 0.060;
      default:
        return height * 0.05;
    }
  }
}
