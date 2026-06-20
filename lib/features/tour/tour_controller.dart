import 'package:fretboard/controllers/home_controller.dart';
import 'package:get/get.dart';
import 'tour_service.dart';
import 'tour_step.dart';

class TourController extends GetxController {
  final List<TourStep> steps;
  TourController({required this.steps});

  final currentStep = 0.obs;
  final isVisible = false.obs;

  // Holds a reactive Worker created by a step's onActivate (e.g. watching
  // currentGameMode). Disposed whenever the step changes or tour ends.
  Worker? _activationWorker;

  int get totalSteps => steps.length;
  TourStep get currentTourStep => steps[currentStep.value];
  bool get isLastStep => currentStep.value == steps.length - 1;

  /// Call from onActivate to register a Worker that will be auto-disposed on
  /// step change or tour end.
  void setActivationWorker(Worker w) {
    _activationWorker?.dispose();
    _activationWorker = w;
  }

  void start() {
    currentStep.value = 0;
    isVisible.value = true;
  }

  void next() {
    _activationWorker?.dispose();
    _activationWorker = null;
    if (!isLastStep) {
      currentStep.value++;
    } else {
      complete();
    }
  }

  void skip() => complete();

  void complete() {
    _activationWorker?.dispose();
    _activationWorker = null;
    isVisible.value = false;
    TourService.markTourCompleted();
    _clearGameHooks();
  }

  void _clearGameHooks() {
    if (!Get.isRegistered<HomeController>()) return;
    final hc = Get.find<HomeController>();
    hc.onFretTappedDuringTour = null;
    hc.onAnswerSelectedDuringTour = null;
    hc.isBottomPanelExpanded.value = true;
    if (hc.isStart) hc.resetGame(false);
  }
}
