import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
import 'package:fretboard/features/tour/fretboard_tour.dart';
import 'package:fretboard/features/tour/tour_controller.dart';
import 'package:fretboard/features/tour/tour_overlay.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_subscription.dart';
import 'package:fretboard/views/screens/home/widgets/landscape_board.dart';
import 'package:fretboard/views/screens/home/widgets/portrait_board.dart';
import 'package:fretboard/views/screens/home/widgets/web_board.dart';
import 'package:fretboard/views/widgets/show_toast.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final TourController _tour;

  // Set expiry date when user login to the app
  // we will expire user login after 14 days
  setExpiryDate() async {
    DateTime currentDate = DateTime.now();
    DateTime endDate = currentDate.add(const Duration(days: 14));
    await LocalDB.storeEndDate(endDate.toString());
  }

  @override
  void initState() {
    final homeController = Get.find<HomeController>();
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    Get.find<LeaderBoardController>().getLeaderBoard();
    homeController.initializeData();
    if (kIsWeb) {
      homeController.getUserNameFromRL();
    }
    setExpiryDate();
    _tour = ensureFretboardTour();
    super.initState();
    if (!kIsWeb) {
      StringsDownloadService().isStringsDownloaded("jhg-fretboard-trainer");

      isFreePlan = SplashScreen.session.isFreePlan;
      if (isFreePlan) {
        homeController.interstitialAds = JHGInterstitialAd(interstitialAdId);
        homeController.interstitialAds?.loadAd();
      }
    }
    _initTour();
  }

  /// The cross-screen seam.
  ///
  /// Home's Quick start step has no completion stream — the honest signal that
  /// the user got in is this screen existing. Advancing here rather than at the
  /// tap site is what makes it survive every route into the board, and a
  /// missing seam is invisible to `flutter analyze`.
  void _initTour() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_tour.isVisible.value) return;
      if (_tour.currentStep.value == TourSteps.quickStart) {
        _tour.goToStep(TourSteps.play);
      }
    });
  }

  HomeController? homeController;

  @override
  void didChangeDependencies() {
    homeController = Get.find<HomeController>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: GetBuilder<HomeController>(
              init: HomeController(),
              builder: (controller) {
                final isPortraitViewport = height >= width;

                return GestureDetector(
                  child: AbsorbPointer(
                    absorbing: kIsWeb ? !controller.isActive : false,
                    child: kIsWeb
                        ? Container(
                            height: height,
                            width: width,
                            color: const Color(0xFF0F0F0F),
                            child: WebBoard(controller: controller),
                          )
                        : Container(
                            width: width,
                            height: height,
                            color: const Color(0xFF0F0F0F),
                            child: isPortraitViewport
                                ? PortraitBoard(controller: controller)
                                : LandscapeBoard(controller: controller),
                          ),
                  ),
                  onTap: () {
                    if (!controller.isActive) {
                      showCustomToast(
                          context: context,
                          message:
                              "Sorry but you do not have an active subscription");
                    }
                  },
                );
              }),
        ),
        // ── Tour overlay ────────────────────────────────────────────────────
        Obx(() {
          if (!_tour.isVisible.value) return const SizedBox.shrink();
          return TourOverlay(
            controller: _tour,
            ownerScreenId: TourScreens.board,
          );
        }),
      ],
    );
  }
}
