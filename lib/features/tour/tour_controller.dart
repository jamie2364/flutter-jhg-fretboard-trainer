import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'tour_service.dart';
import 'tour_step.dart';

/// Drives the guided tour.
///
/// The step list is the *internal* granularity (the setup wizard needs one
/// entry per sub-screen so it can nudge the spotlight along). What the user
/// sees is the coarser **stage**: [railIndex] of [railTotal]. Several steps
/// sharing a [TourStep.stage] read as one step on the rail.
class TourController extends GetxController {
  final List<TourStep> steps;

  TourController({required this.steps});

  /// Bumped on every change. The overlay listens to this rather than to the
  /// individual observables, which is what keeps the painted layer free of any
  /// state-management library: the Provider-based apps in the suite (Rhythm
  /// Toolkit, Velocity) ship a [TourController] with the same surface built on
  /// [ValueNotifier], and the overlay cannot tell the difference.
  final revision = ValueNotifier<int>(0);

  final currentStep = 0.obs;
  final isVisible = false.obs;

  /// Flips true for a beat when the step's real action lands, so the overlay
  /// can flash the ring green before the dock cross-fades on.
  final stepCompleted = false.obs;

  /// Bumped whenever a blocked tap lands outside the cutout. The dock watches
  /// it and shakes, which is a much better answer than silently eating the tap.
  final misTap = 0.obs;

  int get totalSteps => steps.length;
  TourStep get currentTourStep => steps[currentStep.value];
  bool get isLastStep => currentStep.value == steps.length - 1;

  /// How many positions the progress rail has.
  late final int railTotal = steps.map((s) => s.stage).toSet().length;

  /// Which rail position the current step sits at, 0-based.
  int get railIndex => currentTourStep.stage;

  StreamSubscription<bool>? _completionSub;
  Timer? _advanceTimer;

  void _bump() => revision.value++;

  void start() {
    currentStep.value = 0;
    isVisible.value = true;
    _subscribeToCompletion(0);
    _bump();
  }

  void next() {
    _clearPending();
    if (!isLastStep) {
      currentStep.value++;
      _subscribeToCompletion(currentStep.value);
      _bump();
    } else {
      complete();
    }
  }

  /// Jump straight to [index]. Used when a screen's own navigation drives the
  /// tour, such as the setup wizard auto-advancing when the user picks a song.
  void goToStep(int index) {
    final target = index.clamp(0, steps.length - 1);
    if (currentStep.value == target && isVisible.value) return;
    _clearPending();
    isVisible.value = true;
    currentStep.value = target;
    _subscribeToCompletion(target);
    _bump();
  }

  void reportMisTap() {
    misTap.value++;
    _bump();
  }

  void skip() {
    _clearPending();
    complete();
  }

  void complete() {
    isVisible.value = false;
    TourService.markTourCompleted();
    _bump();
  }

  void _clearPending() {
    if (stepCompleted.value) {
      stepCompleted.value = false;
      _bump();
    }
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _completionSub?.cancel();
    _completionSub = null;
  }

  void _subscribeToCompletion(int stepIdx) {
    _completionSub?.cancel();
    _completionSub = null;

    // A closing step carries no action: it sits long enough to be read and then
    // finishes. The overlay runs the real countdown so it can fade the message
    // out first; this is the safety net for the case where no overlay is
    // mounted to do it, so it deliberately waits longer and never beats the
    // fade to the punch.
    final dismissAfter = steps[stepIdx].autoDismiss;
    if (dismissAfter != null) {
      _advanceTimer?.cancel();
      _advanceTimer = Timer(
        dismissAfter + const Duration(milliseconds: 1200),
        () {
          if (currentStep.value == stepIdx && isVisible.value) complete();
        },
      );
      return;
    }

    final stream = steps[stepIdx].completionStream;
    if (stream == null) return;
    _completionSub = stream.listen((done) {
      if (!done || currentStep.value != stepIdx || !isVisible.value) return;
      if (stepCompleted.value) return;
      // Flash the ring green, then move on. Short enough that it reads as
      // acknowledgement rather than a freeze, long enough to be seen.
      stepCompleted.value = true;
      _bump();
      _advanceTimer?.cancel();
      _advanceTimer = Timer(const Duration(milliseconds: 620), () {
        if (currentStep.value == stepIdx && isVisible.value) next();
      });
    });
  }

  @override
  void onClose() {
    _advanceTimer?.cancel();
    _completionSub?.cancel();
    super.onClose();
  }
}
