import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';

class WebLandscapeGuitarBoard extends StatefulWidget {
  const WebLandscapeGuitarBoard({super.key});

  @override
  State<WebLandscapeGuitarBoard> createState() =>
      _WebLandscapeGuitarBoardState();
}

class _WebLandscapeGuitarBoardState extends State<WebLandscapeGuitarBoard> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    return GetBuilder<HomeController>(
        init: HomeController(),
        builder: (controller) {
          return Wrap(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //NUMBERS
                  Container(
                    width: width * 0.900,
                    height: 35,
                    // color: Colors.green,
                    child: ListView.builder(
                      itemCount: 16,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return numberLandscape(index, width);
                      },
                    ),
                  ),

                  //fretboard
                  Container(
                    height: height * 0.4,
                    width: width * 0.901,
                    // alignment: Alignment.,
                    child: Stack(
                      children: [
                        //  BOARD SIZE WITH COLOR
                        Row(
                          children: [
                            Container(
                              width: width * 0.015,
                            ),
                            Expanded(
                              child: Container(
                                width: width * 0.900,
                                color: AppColors.creamColor,
                              ),
                            ),
                          ],
                        ),

                        Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              height: height,
                              width: width * 0.015,
                              decoration: BoxDecoration(
                                  color: JHGColors.black,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10))),
                            )),

                        ///============================================================
                        /// BLACK CIRCLE
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                left: getLandscapeBlackSpace(index, width),
                              ),
                              child: Container(
                                // height: 7.h,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    blackLandscapeCircle(
                                        isColor: index == 11, width: width),
                                    SizedBox(
                                      height: 7.1.h,
                                    ),
                                    blackLandscapeCircle(
                                        width: width,
                                        isColor: index == 2 ||
                                            index == 4 ||
                                            index == 6 ||
                                            index == 8 ||
                                            index == 14),
                                    SizedBox(
                                      height: 7.1.h,
                                    ),
                                    blackLandscapeCircle(
                                        width: width, isColor: index == 11),
                                  ],
                                ),
                              ),
                            );
                          },
                          itemCount: 15,
                        ),

                        ///====================================
                        /// ROW
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 15,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, pos) {
                            return rowLandscapeDivider(pos, width);
                          },
                        ),

                        ///=========================================
                        /// COLUMN
                        ListView.builder(
                          itemCount: 6,
                          shrinkWrap: false,
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.vertical,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return colLandscapeDivider(
                                index, controller.highlightString, width);
                          },
                        ),

                        /// red green  With Grid
                        ///===========================================================

                        Transform.flip(
                          flipY: true,
                          child: AlignedGridView.count(
                            itemCount: 96,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 6,
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 20,
                            itemBuilder: (context, index) {
                              return redGreenLandscapeCircle(
                                width: width,
                                isColor: controller.selectedFret == index
                                    ? true
                                    : false,
                                color: controller.selectedColor,
                                index: index,
                              );
                            },
                          ),
                        ),

                        /// Fret press With Grid
                        ///===========================================================

                        Transform.flip(
                          flipY: true,
                          child: Transform.flip(
                            flipX: true,
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: AlignedGridView.count(
                                itemCount: 96,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 6,
                                mainAxisSpacing: width * 0.0080,
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
                                          child: Container(
                                            child: stringLandscapePress(
                                                index: index, width: width),
                                          )));
                                },
                              ),
                            ),
                          ),
                        ),

                        ///===========================================================
                      ],
                    ),
                  ),

                  //SPACER
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ],
          );
        });
  }

  Widget numberLandscape(int index, double width) {
    return Padding(
      padding: EdgeInsets.only(left: getLandscapeNumberSpace(index, width)),
      child: Container(
        child: Text(
          index.toString(),
          style: JHGTextStyles.subLabelStyle.copyWith(
            fontSize: width * 0.012,
          ),
        ),
      ),
    );
  }

  Widget rowLandscapeDivider(int index, double width) {
    return Padding(
      padding: EdgeInsets.only(left: getLandscapeFrethSpace(index, width)),
      child: Container(
        width: width * 0.0025,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                AppColors.whiteLight,
                AppColors.whiteLight,
                JHGColors.charcolGray,
                JHGColors.secondryBlack
              ]),
        ),
        // child: Text("r$index",style: TextStyle(color:Colors.white ),),
      ),
    );
  }

  Widget colLandscapeDivider(int index, int? selectedString, double width) {
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 10 : 39.0),
      child: Container(
        height: index == 6
            ? 5.5
            : index == 5
                ? 5
                : index == 4
                    ? 4.5
                    : index == 3
                        ? 4
                        : index == 2
                            ? 3.5
                            : 3,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selectedString == index + 1
                  ? [JHGColors.primary, JHGColors.primary]
                  : [
                      AppColors.whiteLight,
                      AppColors.whiteLight,
                      JHGColors.charcolGray,
                      JHGColors.secondryBlack
                    ]),
        ),
        //  child: Text("S$index",style: TextStyle(color:Colors.teal ),),
      ),
    );
  }

  Widget blackLandscapeCircle({
    bool? isColor,
    required double width,
  }) =>
      Container(
        width: width * 0.020,
        height: width * 0.020,
        decoration: BoxDecoration(
          color: isColor == true ? JHGColors.secondryBlack : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: EdgeInsets.all(width * 0.003),
          child: Container(
            width: width * 0.020,
            height: width * 0.020,
            decoration: BoxDecoration(
              color: isColor == true
                  ? JHGColors.secondryBlack.withValues(alpha: 0.5)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  Widget redGreenLandscapeCircle({
    bool? isColor,
    required color,
    required int index,
    required double width,
  }) =>
      Padding(
        padding: EdgeInsets.only(
            left: getLandscapeHighLightBasedOnIndex(index, width), top: 0),
        child: Container(
          width: width * 0.020,
          height: width * 0.020,
          decoration: BoxDecoration(
            // color: Colors.red,
            shape: BoxShape.circle,
            color: isColor == true ? color : Colors.transparent,
          ),
          // child: Text("${fretList[index].note}",style: TextStyle(color: Colors.red),),
        ),
      );

  Widget stringLandscapePress({
    required int index,
    required double width,
  }) =>
      Container(
        // width: 10,
        height: getLandscapeFretPressBasedOnIndex(index, width),
        decoration: BoxDecoration(
            // color: Colors.transparent
            // color: Colors.green.withOpacity(0.5)
            ),
        //child: Text("$index",style: TextStyle(color: Colors.red),),
      );

  double getLandscapeNumberSpace(
    int index,
    double width,
  ) {
    if (index == 0) {
      return width * 0.0045;
    } else if (index == 1) {
      return width * 0.0430;
    } else if (index == 2) {
      return width * 0.0500;
    } else if (index == 3) {
      return width * 0.0500;
    } else if (index == 4) {
      return width * 0.0500;
    } else if (index == 5) {
      return width * 0.0540;
    } else if (index == 6) {
      return width * 0.0500;
    } else if (index == 7) {
      return width * 0.0520;
    } else if (index == 8) {
      return width * 0.0550;
    } else if (index == 9) {
      return width * 0.0500;
    } else if (index == 10) {
      return width * 0.0470;
    } else if (index == 11) {
      return width * 0.0440;
    } else if (index == 12) {
      return width * 0.0430;
    } else if (index == 13) {
      return width * 0.0450;
    } else if (index == 14) {
      return width * 0.0470;
    } else {
      return width * 0.0490;
    }
  }

  double getLandscapeFrethSpace(
    int index,
    double width,
  ) {
    if (index == 0) {
      return width * 0.0548;
    } else if (index == 1) {
      return width * 0.0548;
    } else if (index == 2) {
      return width * 0.0548;
    } else if (index == 3) {
      return width * 0.0548;
    } else if (index == 4) {
      return width * 0.0548;
    } else if (index == 5) {
      return width * 0.0548;
    } else if (index == 6) {
      return width * 0.0548;
    } else if (index == 7) {
      return width * 0.0548;
    } else if (index == 8) {
      return width * 0.0548;
    } else if (index == 9) {
      return width * 0.0548;
    } else if (index == 10) {
      return width * 0.0548;
    } else if (index == 11) {
      return width * 0.0548;
    } else if (index == 12) {
      return width * 0.0548;
    } else if (index == 13) {
      return width * 0.0548;
    } else if (index == 14) {
      return width * 0.0548;
    } else {
      return width * 0.0548;
    }
  }

  double getLandscapeBlackSpace(
    int index,
    double width,
  ) {
    if (index == 0) {
      return width * 0.0263;
    } else if (index == 1) {
      return width * 0.0375;
    } else if (index == 2) {
      return width * 0.0375;
    } else if (index == 3) {
      return width * 0.0375;
    } else if (index == 4) {
      return width * 0.0375;
    } else if (index == 5) {
      return width * 0.0330;
    } else if (index == 6) {
      return width * 0.0330;
    } else if (index == 7) {
      return width * 0.0315;
    } else if (index == 8) {
      return width * 0.0263;
    } else if (index == 9) {
      return width * 0.0248;
    } else if (index == 10) {
      return width * 0.0248;
    } else if (index == 11) {
      return width * 0.0263;
    } else if (index == 12) {
      return width * 0.0225;
    } else if (index == 13) {
      return width * 0.0225;
    } else if (index == 14) {
      return width * 0.0188;
    } else {
      return width * 0.0210;
    }
  }

  double getLandscapeHighLightBasedOnIndex(
    int index,
    double width,
  ) {
    if (index >= 0 && index <= 5) {
      return 0;
    } else if (index >= 6 && index <= 11) {
      return width * 0.0075;
    } else if (index >= 12 && index <= 17) {
      return width * 0.0375;
    } else if (index >= 18 && index <= 23) {
      return width * 0.0398;
    } else if (index >= 24 && index <= 29) {
      return width * 0.0360;
    } else if (index >= 30 && index <= 35) {
      return width * 0.0345;
    } else if (index >= 36 && index <= 41) {
      return width * 0.0360;
    } else if (index >= 42 && index <= 47) {
      return width * 0.0323;
    } else if (index >= 48 && index <= 53) {
      return width * 0.0285;
    } else if (index >= 54 && index <= 59) {
      return width * 0.0330;
    } else if (index >= 60 && index <= 65) {
      return width * 0.0270;
    } else if (index >= 66 && index <= 71) {
      return width * 0.0255;
    } else if (index >= 72 && index <= 77) {
      return width * 0.0233;
    } else if (index >= 78 && index <= 83) {
      return width * 0.0210;
    } else if (index >= 84 && index <= 89) {
      return width * 0.0248;
    } else {
      return width * 0.0173;
    }
  }

  double getLandscapeFretPressBasedOnIndex(
    int index,
    double width,
  ) {
    if (index >= 0 && index <= 5) {
      return width * 0.015;
    } else if (index >= 6 && index <= 11) {
      return width * 0.0368;
    } else if (index >= 12 && index <= 17) {
      return width * 0.051;
    } else if (index >= 18 && index <= 23) {
      return width * 0.051;
    } else if (index >= 24 && index <= 29) {
      return width * 0.0488;
    } else if (index >= 30 && index <= 35) {
      return width * 0.0473;
    } else if (index >= 36 && index <= 41) {
      return width * 0.0458;
    } else if (index >= 42 && index <= 47) {
      return width * 0.0443;
    } else if (index >= 48 && index <= 53) {
      return width * 0.042;
    } else if (index >= 54 && index <= 59) {
      return width * 0.0600;
    } else if (index >= 60 && index <= 65) {
      return width * 0.0500;
    } else if (index >= 66 && index <= 71) {
      return width * 0.0480;
    } else if (index >= 72 && index <= 77) {
      return width * 0.0500;
    } else if (index >= 78 && index <= 83) {
      return width * 0.0500;
    } else if (index >= 84 && index <= 89) {
      return width * 0.0480;
    } else {
      return width * 0.0500;
    }
  }

  double getLandscapeSpace(
    int index,
    double width,
  ) {
    switch (index) {
      case 0:
        return width * 0.0225;
      case 1:
        return width * 0.0450;
      case 2:
        return width * 0.0473;
      case 3:
        return width * 0.0488;
      case 4:
        return width * 0.0450;
      case 5:
        return width * 0.0450;
      case 6:
        return width * 0.0450;
      case 7:
        return width * 0.0398;
      case 8:
        return width * 0.0398;
      case 9:
        return width * 0.0338;
      case 10:
        return width * 0.0285;
      case 11:
        return width * 0.0270;
      case 12:
        return width * 0.0263;
      case 13:
        return width * 0.0278;
      case 14:
        return width * 0.0248;
      case 15:
        return width * 0.0210;
      default:
        return width * 0.0210;
    }
  }
}

class WebPortraitGuitarBoard extends StatefulWidget {
  const WebPortraitGuitarBoard({super.key});

  @override
  State<WebPortraitGuitarBoard> createState() => _WebPortraitGuitarBoardState();
}

class _WebPortraitGuitarBoardState extends State<WebPortraitGuitarBoard> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final wMultiple = 0.21;
    return GetBuilder<HomeController>(
        init: HomeController(),
        builder: (controller) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //fretboard
              Stack(
                children: [
                  Container(
                    height: height * 0.95,
                    width: width * wMultiple,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // BOARD SIZE WITH COLOR
                        Column(
                          children: [
                            SizedBox(
                              height: height * 0.018,
                            ),
                            Expanded(
                              child: Container(
                                width: width * wMultiple,
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
                                width: width * wMultiple,
                                height: height * 0.018,
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
                                  top: getPortraitBlackSpace(index, height),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: blackPortraitCircle(
                                      height: height,
                                      isColor: index == 11,
                                    )),
                                    Expanded(child: SizedBox.shrink()),
                                    Expanded(
                                        child: blackPortraitCircle(
                                            height: height,
                                            isColor: index == 2 ||
                                                index == 4 ||
                                                index == 6 ||
                                                index == 8 ||
                                                index == 14)),
                                    Expanded(child: SizedBox.shrink()),
                                    Expanded(
                                        child: blackPortraitCircle(
                                            height: height,
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
                              return rowPortraitDivider(height, pos);
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
                                  width, index, controller.highlightString);
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
                                    height: height);
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
                                        height: height,
                                        width: width),
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
                height: height * 0.95,
                // color: Colors.red,
                width: 18,
                child: ListView.builder(
                  itemCount: 16,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return numberPortrait(height, index);
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
