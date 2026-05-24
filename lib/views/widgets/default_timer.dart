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
                    child: _SettingsTimerDropdown(
                      value: controller.defaultTimerSelectedValue.value,
                      items: controller.defaultTimer,
                      onChanged: (String? value) {
                        if (value != null) {
                          controller.selectedDropDownValue.value = value;
                          controller.defaultTimerSelectedValue.value = value;
                          controller.saveTimerSettings();
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
                    controller.minutesValue.value =
                        controller.timerIntervalValue.value ~/ 60;
                    controller.saveTimerSettings();
                  },
                ),
              ),
            ),
          ],
        ));
  }
}

class _SettingsTimerDropdown extends StatelessWidget {
  const _SettingsTimerDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PopupMenuButton<String>(
          initialValue: value,
          onSelected: onChanged,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          color: JHGColors.darkBackground,
          elevation: 8,
          constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: JHGColors.white.withValues(alpha: 0.06),
            ),
          ),
          itemBuilder: (context) {
            return items.map((item) {
              return PopupMenuItem<String>(
                value: item,
                height: 48,
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.transparent,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item,
                    style: JHGTextStyles.labelStyle.copyWith(
                      color: JHGColors.whiteText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList();
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: JHGColors.darkBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: JHGColors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JHGTextStyles.labelStyle.copyWith(
                      color: JHGColors.whiteText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.chevronDown300,
                  color: JHGColors.whiteGrey,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
