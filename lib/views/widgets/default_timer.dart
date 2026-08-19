import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/views/widgets/duration_picker.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsDefaultTimer extends StatelessWidget {
  const SettingsDefaultTimer({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SettingsIconChip(icon: LucideIcons.timer),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Default Timer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: SettingsDropdown(
                    items: controller.defaultTimer,
                    value: controller.defaultTimerSelectedValue.value,
                    onChanged: (String? value) {
                      if (value != null) {
                        controller.selectedDropDownValue.value = value;
                        controller.defaultTimerSelectedValue.value = value;
                        controller.saveTimerSettings();
                      }
                    },
                  ),
                ),
              ],
            ),
            if (controller.defaultTimerSelectedValue.value ==
                controller.defaultTimer[1]) ...[
              const SizedBox(height: 14),
              const SettingsDivider(),
              const SizedBox(height: 14),
              LabeledDurationPicker(
                label: 'Interval Time',
                subLabel: 'Set the countdown duration',
                controller: controller,
                currentSeconds: controller.timerIntervalValue.value,
                onSelected: (int m, int s) {
                  controller.timerIntervalValue.value = m * 60 + s;
                  if (controller.timerIntervalValue.value == 0) {
                    controller.timerIntervalValue.value = 1;
                  }
                  controller.minutesValue.value =
                      controller.timerIntervalValue.value ~/ 60;
                  controller.saveTimerSettings();
                },
              ),
            ],
          ],
        ));
  }
}
