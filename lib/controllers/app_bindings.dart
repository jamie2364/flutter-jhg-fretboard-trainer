import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeaderBoardController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => HeatmapController(), fenix: true);
  }
}

//controllers
