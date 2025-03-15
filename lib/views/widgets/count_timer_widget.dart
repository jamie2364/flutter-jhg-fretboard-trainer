import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:get/get.dart';

class CountTimerWidget extends StatelessWidget {
  const CountTimerWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(
      () => controller.timerMode
          ? JHGTimerWidget(
              isEnabled: !controller.isStart,
              initialValue: controller.secondsRemaining.value,
              onChanged: (value) {
                controller.secondsRemaining.value = value;
              },
            )
          : Text(
              controller.formatTime(controller.secondsRemaining.value),
              style: JHGTextStyles.bigNumberStyle,
            ),
    );
  }
}
