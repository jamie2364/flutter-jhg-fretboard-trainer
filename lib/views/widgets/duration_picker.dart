import 'package:flutter/cupertino.dart';
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
    return Obx(() => JHGHeadAndSubHWidget(
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
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: JHGColors.boxBorder)),
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
        ));
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
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: kBodyHrPadding),
            height: 350, // Adjusted height slightly
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    "Select Time", // Changed Title
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: initialMinutes),
                          itemExtent: 40,
                          magnification: 1.2,
                          onSelectedItemChanged: (index) {
                            selectedMinute = index;
                          },
                          children: List.generate(
                            60, // Limit minutes to 59
                            (i) => Center(child: Text("$i min")),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: initialSeconds),
                          itemExtent: 40,
                          magnification: 1.2,
                          onSelectedItemChanged: (index) {
                            selectedSecond = index;
                          },
                          children: List.generate(
                            60, // Limit seconds to 59
                            (i) => Center(child: Text("$i sec")),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: JHGOutlinedBtn(
                        height: 50,
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: JHGPrimaryBtn(
                        height: 50,
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Ensure at least 1 second is selected
                          if (selectedMinute == 0 && selectedSecond == 0) {
                             onSelected(0, 1); // Default to 1 second if 0:00 selected
                          } else {
                             onSelected(selectedMinute, selectedSecond);
                          }
                        },
                        label: "OK",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}