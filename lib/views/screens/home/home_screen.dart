import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/controllers/leaderboard_controller.dart';
import 'package:fretboard/features/tour/tour_controller.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/features/tour/tour_overlay.dart';
import 'package:fretboard/features/tour/tour_service.dart';
import 'package:fretboard/features/tour/tour_step.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_subscription.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
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
    Get.put(TourController(steps: _buildTourSteps()));
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

  Future<void> _initTour() async {
    final seen = await TourService.hasSeenTour();
    if (!seen && mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Get.find<TourController>().start();
    }
  }

  List<TourStep> _buildTourSteps() {
    HomeController hc() => Get.find<HomeController>();
    TourController tc() => Get.find<TourController>();

    return [
      // ── 0. Greeting ────────────────────────────────────────────────────────
      TourStep(
        title: 'Welcome to Fretboard Trainer!',
        subtitle:
            'Interactive walkthrough — you\'ll play two live rounds and be ready to go.',
        actionLabel: 'Let\'s Go  →',
        onActivate: () {
          // Guarantee a clean state at tour start.
          if (hc().isStart) hc().resetGame(false);
          hc().switchToFindMode();
        },
      ),

      // ── 1. Timer ───────────────────────────────────────────────────────────
      TourStep(
        title: 'Set Your Timer',
        subtitle:
            'Tap the clock icon to switch between Stopwatch and Countdown.\nFor a countdown, use + and − to set the duration.',
        targetKey: tourKeyTimer,
        spotlightPadding: 14,
        actionLabel: 'Got it  →',
      ),

      // ── 2. Find Note Mode chip ─────────────────────────────────────────────
      TourStep(
        title: 'Find Note Mode',
        subtitle:
            'A note name appears at the bottom. Scroll the neck and tap that note on the fretboard to score.',
        targetKey: tourKeyModeChip,
        spotlightPadding: 10,
        actionLabel: 'Got it  →',
      ),

      // ── 3. Tap Play (Find Note) — compact spotlight, must tap ─────────────
      TourStep(
        title: 'Tap Play to Start',
        subtitle: 'Tap ▶ — the note you need to find will appear below.',
        targetKey: tourKeyPlayButton,
        spotlightPadding: 8,
        isInteractive: true,
        blockBackground: true,
        onSpotlightTap: () {
          hc().startTimer();
          hc().startTheGame();
          hc().isBottomPanelExpanded.value = false; // collapse → more fretboard space
          tc().next();
        },
      ),

      // ── 4. Find the note — card anchored just above timer, dynamic hint ────
      TourStep(
        title: 'Find It!',
        subtitleBuilder: () => GetBuilder<HomeController>(
          builder: (h) {
            final note = h.highlightNode ?? '—';
            final pos = h.reversePositionHint;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    children: [
                      const TextSpan(text: 'Look for '),
                      TextSpan(
                        text: note,
                        style: TextStyle(
                          color: JHGColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const TextSpan(text: ' on the neck'),
                    ],
                  ),
                ),
                if (pos.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(pos,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 3),
                const Text('Tap it to score!',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            );
          },
        ),
        isInteractive: true,
        blockBackground: false,
        showBackdrop: false,
        anchorAboveKey: tourKeyTimer, // positions card just above the timer
        onActivate: () {
          void fireOnce() {
            hc().onFretTappedDuringTour = null;
            Future.delayed(const Duration(milliseconds: 800), () {
              if (Get.isRegistered<TourController>()) tc().next();
            });
          }
          hc().onFretTappedDuringTour = fireOnce;
        },
      ),

      // ── 5. Switch to Identify Mode — spotlight chip, user does it ─────────
      TourStep(
        title: 'Switch to Identify Mode',
        subtitle:
            'Tap the mode button (highlighted) and select Identify Mode.',
        targetKey: tourKeyModeChip,
        spotlightPadding: 10,
        isInteractive: true,   // no Next button — user must act
        blockBackground: false, // taps pass through so user can tap chip
        showBackdrop: true,     // dark overlay draws attention to chip
        onActivate: () {
          hc().onFretTappedDuringTour = null;
          if (hc().isStart) hc().resetGame(false);
          hc().isBottomPanelExpanded.value = true; // expand so mode chip is visible
          // Watch currentGameMode — auto-advance when user switches to identify.
          final w = ever(hc().currentGameMode, (String mode) {
            if (mode == 'reverse') {
              Future.delayed(const Duration(milliseconds: 400), () {
                if (Get.isRegistered<TourController>()) tc().next();
              });
            }
          });
          tc().setActivationWorker(w);
        },
      ),

      // ── 6. Tap Play (Identify) ─────────────────────────────────────────────
      TourStep(
        title: 'Tap Play to Start',
        subtitle: 'Tap ▶ — a fret will glow on the neck.',
        targetKey: tourKeyPlayButton,
        spotlightPadding: 8,
        isInteractive: true,
        blockBackground: true,
        onActivate: () {
          if (hc().isStart) hc().resetGame(false);
        },
        onSpotlightTap: () {
          hc().startTimer();
          hc().startTheGame();
          tc().next();
        },
      ),

      // ── 7. Name the note — card anchored above timer, wait for answer ──────
      TourStep(
        title: 'Name That Note!',
        subtitle:
            'A fret is glowing on the neck.\nTap the correct note name from the 4 buttons below.',
        isInteractive: true,
        blockBackground: false,
        showBackdrop: false,
        anchorAboveKey: tourKeyTimer,
        onActivate: () {
          void fireOnce() {
            hc().onAnswerSelectedDuringTour = null;
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (Get.isRegistered<TourController>()) tc().next();
            });
          }
          hc().onAnswerSelectedDuringTour = fireOnce;
        },
      ),

      // ── 8. Heatmap — spotlight the nav icon, then navigate ────────────────
      TourStep(
        title: 'Your Mastery Map',
        subtitle:
            'The Heatmap shows which notes you struggle with most — darker means more practice needed.\nTap "View Heatmap" to explore it now.',
        targetKey: tourKeyHeatmapNav,
        spotlightPadding: 14,
        actionLabel: 'View Heatmap  →',
        onActivate: () {
          hc().onAnswerSelectedDuringTour = null;
          if (hc().isStart) hc().resetGame(false);
          TourService.scheduleHeatmapIntro();
        },
        onActionTap: () {
          tc().complete();
          Get.to(() => const HeatmapScreen(),
              transition: Transition.noTransition,
              duration: Duration.zero);
        },
      ),
    ];
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
          backgroundColor: JHGColors.secondryBlack,
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
                            color: JHGColors.secondryBlack,
                            child: WebBoard(controller: controller),
                          )
                        : Container(
                            width: width,
                            height: height,
                            color: JHGColors.secondryBlack,
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
          final tourCtrl = Get.find<TourController>();
          if (!tourCtrl.isVisible.value) return const SizedBox.shrink();
          return TourOverlay(controller: tourCtrl);
        }),
      ],
    );
  }
}
