import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/services/local_db_service.dart'
    show kMinTimerIntervalSeconds;
import 'package:get/get.dart';

class CountTimerWidget extends StatelessWidget {
  const CountTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ** Get HomeController instead of TimerController **
    final controller = Get.find<HomeController>();
    return Obx(() {
      // In the choice modes (identify / interval / chord) the timer sub-mode is
      // tracked via timerMode, not currentGameMode — this has to resolve
      // exactly the way the controller's resetTimer/startTimer do, or the
      // display and the running clock disagree (Interval and Chord modes were
      // missing the countdown adjuster entirely while a countdown ran).
      final effectiveMode = controller.isChoiceMode
          ? controller.timerMode.value
          : controller.currentGameMode.value;
      return effectiveMode == 'countdown'
          ? _CountdownTimerAdjuster(
              isEnabled: !controller.isStart && !controller.isPaused,
              value: controller.secondsRemaining.value,
              onChanged: (value) {
                controller.secondsRemaining.value = value;
                controller.timerIntervalValue.value = value;
                // An explicit choice — don't let re-entering the board reset it
                // to the stored Settings default.
                controller.timingChosen = true;
              },
            )
          : Text(
              controller.formatTime(controller.secondsRemaining.value),
              style: JHGTextStyles.bigNumberStyle,
            );
    });
  }
}

class _CountdownTimerAdjuster extends StatefulWidget {
  const _CountdownTimerAdjuster({
    required this.value,
    required this.onChanged,
    required this.isEnabled,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool isEnabled;

  @override
  State<_CountdownTimerAdjuster> createState() =>
      _CountdownTimerAdjusterState();
}

class _CountdownTimerAdjusterState extends State<_CountdownTimerAdjuster> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TimerAdjustButton(
          icon: LucideIcons.minus,
          enabled: widget.isEnabled,
          onTap: _decrement,
          onLongPressStart: () => _startRepeating(_decrement),
          onLongPressEnd: _stopRepeating,
        ),
        SizedBox(
          width: 144,
          child: Text(
            _formatSecondsToMMSS(widget.value),
            textAlign: TextAlign.center,
            style: JHGTextStyles.bigNumberStyle,
          ),
        ),
        _TimerAdjustButton(
          icon: LucideIcons.plus,
          enabled: widget.isEnabled,
          onTap: _increment,
          onLongPressStart: () => _startRepeating(_increment),
          onLongPressEnd: _stopRepeating,
        ),
      ],
    );
  }

  void _startRepeating(VoidCallback callback) {
    if (!widget.isEnabled) return;
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 120),
      (_) => callback(),
    );
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _increment() {
    if (!widget.isEnabled) return;
    widget.onChanged(widget.value + 10);
  }

  void _decrement() {
    // Never below the minimum round length — a 0s countdown ends the instant
    // it starts.
    if (!widget.isEnabled || widget.value <= kMinTimerIntervalSeconds) return;
    final nextValue = widget.value - 10;
    widget.onChanged(
        nextValue < kMinTimerIntervalSeconds ? kMinTimerIntervalSeconds : nextValue);
  }

  String _formatSecondsToMMSS(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TimerAdjustButton extends StatelessWidget {
  const _TimerAdjustButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Hold-to-repeat lives here; the chip is a face only so its own tap
      // handler cannot swallow the long press.
      onTap: enabled ? onTap : null,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      child: JhgIconChipButton.compact(
        icon: icon,
        onTap: null,
        isActive: enabled,
        enabled: enabled,
      ),
    );
  }
}
