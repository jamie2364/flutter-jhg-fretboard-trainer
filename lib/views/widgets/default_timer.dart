import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/views/widgets/add_sub_button.dart';
import 'package:fretboard/views/widgets/expansion_tile_dropdown.dart';
import 'package:get/get.dart';

class SettingsDefaultTimer extends StatelessWidget {
  const SettingsDefaultTimer({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Padding(
            //   padding: const EdgeInsets.only(top: 20),
            //   child: Row(
            //     children: [
            //       const Expanded(
            //         flex: 2,
            //         child: Text(
            //           "Default Timer",
            //           style: JHGTextStyles.subLabelStyle,
            //         ),
            //       ),
            //       Expanded(
            //           flex: 2,
            //           child: JHGDropDown<String>(
            //             value: controller.defaultTimerSelectedValue.value,
            //             items: controller.defaultTimer,
            //             onChanged: (String? value) {
            //               if (value != null) {
            //                 controller.selectedDropDownValue.value = value;
            //                 controller.defaultTimerSelectedValue.value = value;
            //               }
            //             },
            //           )),
            //     ],
            //   ),
            // ),

            ExpansionPanelDropdown<String>(
              label: "Default Timer",
              value: controller.defaultTimerSelectedValue.value,
              items: controller.defaultTimer,
              onChanged: (value) async {
                controller.defaultTimerSelectedValue.value = value;
                controller.selectedDropDownValue.value = value;
              },
            ),
            Padding(
                padding: const EdgeInsets.only(top: 20),
                child: JHGExpandableSection(
                    expand: controller.defaultTimerSelectedValue.value ==
                        controller.defaultTimer[1],
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TimerWidget(
                        //   title: "Minutes",
                        //   value: controller.minutesValue.value.toString(),
                        //   onIncrementTap: () {
                        //     controller.minutesValue++;
                        //   },
                        //   onDecrementTap: () {
                        //     if (controller.minutesValue.value > 1) {
                        //       controller.minutesValue--;
                        //     }
                        //   },
                        // ),
                        JHGHeadAndSubHWidget(
                          "Minutes",
                          actions: [
                            JHGValueIncDec(
                                initialValue: controller.minutesValue.value,
                                onChanged: (value) {
                                  controller.minutesValue.value = value;
                                },
                                maxValue: 300)
                          ],
                        ),
                        JHGHeadAndSubHWidget(
                          "Interval Time",
                          subLabel: "Set the intervals in Seconds",
                          actions: [
                            JHGValueIncDec(
                                initialValue:
                                    controller.timerIntervalValue.value,
                                onChanged: (value) {
                                  controller.timerIntervalValue.value = value;
                                },
                                maxValue: 300)
                          ],
                        ),
                        // TimerWidget(
                        //   title: "Interval Time",
                        //   subtitle: "Set the intervals in Seconds",
                        //   value: controller.timerIntervalValue.value.toString(),
                        //   isExpend: controller.timerIntervalExpanded.value,
                        //   isInfoEnable: true,
                        //   onInfoTap: () {
                        //     controller.timerIntervalExpanded.value =
                        //         !controller.timerIntervalExpanded.value;
                        //   },
                        //   onIncrementTap: () {
                        //     controller.timerIntervalValue++;
                        //   },
                        //   onDecrementTap: () {
                        //     if (controller.timerIntervalValue.value > 1) {
                        //       controller.timerIntervalValue--;
                        //     }
                        //   },
                        // )
                      ],
                    ))),
          ],
        ));
  }
}

class TimerWidget extends StatelessWidget {
  TimerWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onIncrementTap,
    required this.onDecrementTap,
    this.isExpend,
    this.isInfoEnable,
    this.onInfoTap,
  });

  final String title;
  final String? subtitle;
  final String value;
  final VoidCallback onIncrementTap;
  final VoidCallback onDecrementTap;
  final bool? isExpend;
  final bool? isInfoEnable;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      //MediaQuery.sizeOf(context).height*0.070,
      // color: Colors.green,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: JHGTextStyles.subLabelStyle,
                      ),
                      isInfoEnable == true
                          ? JHGIconButton(
                              onTap: onInfoTap,
                              childPadding: const EdgeInsets.only(left: 8),
                              iconData: Icons.info_outline_rounded,
                              iconColor: JHGColors.white,
                              size: 20,
                            )
                          : SizedBox(),
                    ],
                  ),
                  isInfoEnable == true
                      ? JHGExpandableSection(
                          expand: isExpend ?? false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle ?? " ",
                              style: JHGTextStyles.subLabelStyle
                                  .copyWith(fontSize: 12),
                            ),
                          ),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                AddAndSubtractButton(onTap: onDecrementTap, isAdd: false),
                SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: JHGColors.boxBorder)),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: JHGTextStyles.lrlabelStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                AddAndSubtractButton(onTap: onIncrementTap, isAdd: true),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class JHGValueChangeWidget extends StatelessWidget {
  const JHGValueChangeWidget({
    super.key,
    required this.onDecrementTap,
    required this.value,
    required this.onIncrementTap,
  });

  final VoidCallback onDecrementTap;
  final String value;
  final VoidCallback onIncrementTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AddAndSubtractButton(onTap: onDecrementTap, isAdd: false),
        SizedBox(width: 10),
        Container(
          width: 200,
          height: 200,
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: JHGColors.boxBorder)),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: JHGTextStyles.lrlabelStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 10),
        AddAndSubtractButton(onTap: onIncrementTap, isAdd: true),
      ],
    );
  }
}
