import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart'; // ** Import HomeController **
import 'package:get/get.dart';

class CountTimerWidget extends StatelessWidget {
  const CountTimerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // ** Get HomeController instead of TimerController **
    final controller = Get.find<HomeController>();
    return Obx(
      () => controller.currentGameMode.value ==
              'countdown' // ** Check currentGameMode **
          ? JHGTimerWidget(
              isEnabled: !controller.isStart, // ** Use HomeController state **
              initialValue: controller
                  .secondsRemaining.value, // ** Use HomeController state **
              onChanged: (value) {
                controller.secondsRemaining.value =
                    value; // ** Use HomeController state **
              },
            )
          : Text(
              // ** Use HomeController state **
              controller.formatTime(controller.secondsRemaining.value),
              style: JHGTextStyles.bigNumberStyle,
            ),
    );
  }
}
