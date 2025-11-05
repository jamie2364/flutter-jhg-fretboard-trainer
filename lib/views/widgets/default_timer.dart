import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/views/widgets/duration_picker.dart';
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
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56, // Match standard dropdown height
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Default Timer',
                          style: JHGTextStyles.labelStyle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    // ** Replaced JHGInlineDropDown with JHGDropDown **
                    child: JHGDropDown<String>(
                      value: controller.defaultTimerSelectedValue.value,
                      items: controller.defaultTimer,
                      hint: 'Select Timer', // Added a hint
                      onChanged: (String? value) {
                        if (value != null) {
                          controller.selectedDropDownValue.value = value;
                          controller.defaultTimerSelectedValue.value = value;
                          // Optional: Reset timer value when mode changes in settings
                          // if (value == 'Stopwatch') {
                          //    controller.timerIntervalValue.value = 120; // Default Stopwatch time
                          // } else {
                          //    controller.timerIntervalValue.value = 120; // Default Countdown time
                          // }
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Visibility(
                visible: controller.defaultTimerSelectedValue.value ==
                    controller.defaultTimer[1], // Show only for "Countdown"
                child: LabeledDurationPicker(
                  label: 'Interval Time',
                  subLabel: 'Set the countdown duration',
                  controller: controller,
                  currentSeconds: controller.timerIntervalValue.value,
                  onSelected: (int m, int s) {
                    debugPrint("Picked: $m min, $s sec");
                    controller.timerIntervalValue.value = m * 60 + s;
                    if (controller.timerIntervalValue.value == 0) {
                      controller.timerIntervalValue.value =
                          1; // Ensure minimum 1 second
                    }
                  },
                ),
              ),
            ),
          ],
        ));
  }
}
