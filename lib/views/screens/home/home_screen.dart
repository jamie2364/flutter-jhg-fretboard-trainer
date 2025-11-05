import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
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
    Get.find<LeaderBoardController>().getLeaderBoard();
    homeController.initializeData();
    if (kIsWeb) {
      homeController.getUserNameFromRL();
    }
    setExpiryDate();
    super.initState();
    if (!kIsWeb) {
      StringsDownloadService().isStringsDownloaded("jhg-fretboard-trainer");

      isFreePlan = SplashScreen.session.isFreePlan;
      if (isFreePlan) {
        homeController.interstitialAds = JHGInterstitialAd(interstitialAdId);
        homeController.interstitialAds?.loadAd();
      }
    }
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

    return Scaffold(
      backgroundColor: JHGColors.secondryBlack,
      body: GetBuilder<HomeController>(
          init: HomeController(),
          builder: (controller) {
            return GestureDetector(
              child: AbsorbPointer(
                absorbing: kIsWeb ? !controller.isActive : false,
                child: kIsWeb
                    ? Container(
                        height: height,
                        width: width,
                        color: JHGColors.secondryBlack,
                        child: WebBoard(controller: controller),
                      )
                    : Container(
                        width: width,
                        height: height,
                        color: JHGColors.secondryBlack,
                        child: controller.isPortrait == true
                            ? JHGBody(
                                body: PortraitBoard(controller: controller))
                            : JHGBody(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                body: LandscapeBoard(controller: controller)),
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
    );
  }
}
