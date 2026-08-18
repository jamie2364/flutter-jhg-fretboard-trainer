import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
// ** Corrected Import Path **
import 'package:fretboard/controllers/home_controller.dart';
import 'package:get/get.dart';

class LabeledDurationPicker extends StatelessWidget {
  const LabeledDurationPicker({
    super.key,
    required this.label,
    this.subLabel,
    required this.currentSeconds,
    required this.onSelected,
    required this.controller,
  });

  final String label;
  final String? subLabel;
  final int currentSeconds;
  final Function(int, int) onSelected;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    // Use Obx to rebuild when timerIntervalValue changes
    return Obx(
      () => JHGHeadAndSubHWidget(
        label,
        subLabel: subLabel,
        actions: [
          InkWell(
            onTap: () {
              // Read the current value directly from the controller
              int currentTotalSeconds = controller.timerIntervalValue.value;
              showIntervalTimeDialog(
                context,
                initialMinutes: currentTotalSeconds ~/ 60,
                initialSeconds: currentTotalSeconds % 60,
                onSelected: onSelected,
              );
            },
            child: Container(
              width: 180, // Consider making this responsive if needed
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: JHGColors.darkBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JHGColors.boxBorder),
              ),
              child: Text(
                // Use the value from the controller for display
                formatTime(controller.timerIntervalValue.value),
                textAlign: TextAlign.center,
                style: JHGTextStyles.lrlabelStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> showIntervalTimeDialog(
    BuildContext context, {
    int initialMinutes = 0,
    int initialSeconds = 0,
    required Function(int minutes, int seconds) onSelected,
  }) async {
    int selectedMinute = initialMinutes;
    int selectedSecond = initialSeconds;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final dialogWidth = kIsWeb
            ? (MediaQuery.sizeOf(context).width - 96)
                .clamp(360.0, 520.0)
                .toDouble()
            : null;
        const dialogHeight = kIsWeb ? 256.0 : 326.0;
        const pickerHeight = kIsWeb ? 126.0 : 178.0;
        const pickerItemExtent = kIsWeb ? 34.0 : 44.0;
        const pickerTextSize = kIsWeb ? 16.0 : 20.0;
        const buttonHeight = kIsWeb ? 40.0 : 48.0;

        return Dialog(
          backgroundColor: JHGColors.charcolGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: dialogWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: kIsWeb ? 18 : kBodyHrPadding,
            ),
            height: dialogHeight,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: kIsWeb ? 14 : 20,
                    bottom: kIsWeb ? 10 : 14,
                  ),
                  child: Text(
                    "Select Time",
                    style: JHGTextStyles.dialogTitleStyle.copyWith(
                      fontSize: kIsWeb ? 18 : null,
                      height: 1,
                    ),
                  ),
                ),
                Container(
                  height: pickerHeight,
                  decoration: BoxDecoration(
                    color: JHGColors.darkBackground,
                    borderRadius: BorderRadius.circular(kIsWeb ? 12 : 14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: initialMinutes,
                          ),
                          itemExtent: pickerItemExtent,
                          magnification: kIsWeb ? 1.05 : 1.15,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: kIsWeb ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: JHGColors.greyPrimary.withValues(
                                alpha: 0.42,
                              ),
                              borderRadius: BorderRadius.circular(
                                kIsWeb ? 8 : 10,
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (index) {
                            selectedMinute = index;
                          },
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(
                                "$i min",
                                style: JHGTextStyles.lrlabelStyle.copyWith(
                                  color: JHGColors.whiteText,
                                  fontSize: pickerTextSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: initialSeconds,
                          ),
                          itemExtent: pickerItemExtent,
                          magnification: kIsWeb ? 1.05 : 1.15,
                          selectionOverlay: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: kIsWeb ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: JHGColors.greyPrimary.withValues(
                                alpha: 0.42,
                              ),
                              borderRadius: BorderRadius.circular(
                                kIsWeb ? 8 : 10,
                              ),
                            ),
                          ),
                          onSelectedItemChanged: (index) {
                            selectedSecond = index;
                          },
                          children: List.generate(
                            60,
                            (i) => Center(
                              child: Text(
                                "$i sec",
                                style: JHGTextStyles.lrlabelStyle.copyWith(
                                  color: JHGColors.whiteText,
                                  fontSize: pickerTextSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kIsWeb ? 12 : 16),
                JHGPrimaryBtn(
                  height: buttonHeight,
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (selectedMinute == 0 && selectedSecond == 0) {
                      onSelected(0, 1);
                    } else {
                      onSelected(selectedMinute, selectedSecond);
                    }
                  },
                  label: "Done",
                ),
                const SizedBox(height: kIsWeb ? 10 : 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
