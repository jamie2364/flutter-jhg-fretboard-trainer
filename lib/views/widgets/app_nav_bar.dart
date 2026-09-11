import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/services/saved_sessions_service.dart';
import 'package:fretboard/utils/routes.dart';
import 'package:fretboard/views/screens/mode_select_screen.dart';
import 'package:fretboard/views/screens/saved/saved_sessions_screen.dart';
import 'package:fretboard/views/screens/stats/stats_hub_screen.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:fretboard/utils/board_nav.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Mirrors the shared AppBottomNav used across the apps (dark bar, coral active,
// stacked icon + label, no pill).
const _kNavBg = Color(0xFF0F0F0F);
const _kNavInactive = Color(0xFF9E9A98);

enum AppTab { home, train, saved, leaderboard, heatmap, settings }

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.activeTab,
    this.controller,
    this.safeBottom,
  });

  final AppTab activeTab;
  final HomeController? controller;

  /// Bottom safe-area inset. Omit it and the bar reads `viewPadding` itself —
  /// the same value whether it sits in a Scaffold's bottomNavigationBar or at
  /// the end of a Column, so the bar is exactly as tall on every screen.
  final double? safeBottom;

  void _navigate(AppTab tab, BuildContext context) {
    if (tab == activeTab) return;
    final hc = controller ?? Get.find<HomeController>();

    // Leaving an in-progress session (anything except staying on Train) ends
    // the round — confirm first with a professional dialog so a good streak
    // isn't lost by a stray tap. On confirm the session is auto-saved so it can
    // be resumed later from the Saved Sessions screen.
    if (hc.sessionActive && tab != AppTab.train) {
      _confirmLeaveSession(
        context,
        onSaveAndLeave: () async {
          await hc.saveCurrentSession();
          _go(tab, hc, endSession: true);
        },
        onLeave: () => _go(tab, hc, endSession: true),
      );
      return;
    }
    _go(tab, hc, endSession: false);
  }

  void _go(AppTab tab, HomeController hc, {required bool endSession}) {
    if (endSession) hc.resetGame(false);

    // Home and the training board are the two screens the landing screen sits
    // under, so from either of them we PUSH and the landing screen survives.
    // Between the secondary screens we replace, so the stack stays flat.
    // Getting this wrong is what killed the Home tab once Home gained a nav
    // bar: replacing from Home wiped the landing screen off the bottom of the
    // stack, leaving Home with nothing to go back to.
    final fromRoot = activeTab == AppTab.train || activeTab == AppTab.home;

    void goTo(Widget Function() page, String routeName) {
      fromRoot
          ? Get.to(page,
              routeName: routeName,
              transition: Transition.noTransition,
              duration: Duration.zero)
          : Get.off(page,
              routeName: routeName,
              transition: Transition.noTransition,
              duration: Duration.zero);
    }

    switch (tab) {
      case AppTab.home:
        hc.resetGame(false);
        hc.quickStartSession = false;
        // Pop back to the landing screen. The predicate runs on the route we
        // stop at, so it also tells us what we landed on.
        var landedOnStart = true;
        Get.until((r) {
          if (!r.isFirst) return false;
          landedOnStart = !kPushedRoutes.contains(r.settings.name);
          return true;
        });
        // If a pushed screen ended up at the bottom of the stack, the landing
        // screen was replaced at some point and popping found nothing. Put it
        // back rather than leaving the tab dead.
        if (!landedOnStart) {
          Get.off(() => const StartScreen(),
              transition: Transition.noTransition, duration: Duration.zero);
        }
        break;

      case AppTab.train:
        // Pop back to the board if it is already open…
        var foundBoard = false;
        Get.until((r) {
          if (r.settings.name == kBoardRoute) {
            foundBoard = true;
            return true;
          }
          return r.isFirst;
        });
        // …otherwise there is no session yet, so open the board on Find the
        // Note, exactly as Quick start does. Tapping Practice should land you
        // on the practice screen, never bounce you Home.
        if (!foundBoard) {
          hc.resetStrings();
          hc.switchToFindMode();
          hc.quickStartSession = true;
          hc.applySessionTiming(useTimer: false);
          openBoard();
        }
        break;

      case AppTab.saved:
        SavedSessionsService.refreshCount();
        goTo(() => const SavedSessionsScreen(), kSavedRoute);
        break;

      case AppTab.leaderboard:
        goTo(() => const LeadershipScreen(), kLeaderboardRoute);
        if (isFreePlan) hc.interstitialAds?.showInterstitial();
        break;

      case AppTab.heatmap:
        goTo(() => const StatsHubScreen(), kStatsRoute);
        break;

      case AppTab.settings:
        goTo(() => const SettingScreen(), kSettingsRoute);
        if (isFreePlan) hc.interstitialAds?.showInterstitial();
        break;
    }
  }

  void _confirmLeaveSession(
    BuildContext context, {
    required VoidCallback onSaveAndLeave,
    required VoidCallback onLeave,
  }) {
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: LucideIcons.save,
        title: 'Leave this session?',
        description: 'Save it and you can pick it up again from Saved '
            'Sessions, or just leave it.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            JHGFrostedPrimaryButton(
              label: 'Save & leave',
              onTap: () {
                Navigator.of(ctx).pop();
                onSaveAndLeave();
              },
            ),
            const SizedBox(height: 10),
            _secondaryButton(
              label: 'Leave without saving',
              onTap: () {
                Navigator.of(ctx).pop();
                onLeave();
              },
            ),
            const SizedBox(height: 10),
            _secondaryButton(
              label: 'Cancel',
              muted: true,
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: muted ? 0.04 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: muted ? Colors.white54 : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Every tab stays enabled and uniformly coloured — only the active one is
    // white. Leaving mid-session is gated by a confirm dialog (see _navigate),
    // not by greying tabs out.
    final safeBottom =
        this.safeBottom ?? MediaQuery.viewPaddingOf(context).bottom;

    // The bar itself is the shared suite component — height, hairline, colours
    // and type live in flutter_jhg_elements, so a change there lands here. This
    // widget only owns the tab list and the navigation rules.
    final bar = JHGBottomNav(
      background: _kNavBg,
      safeBottom: safeBottom,
      inactiveColor: _kNavInactive,
      items: [
        JHGNavItem(
          icon: LucideIcons.home,
          label: 'Home',
          isActive: activeTab == AppTab.home,
          onTap: () => _navigate(AppTab.home, context),
        ),
        JHGNavItem(
          icon: LucideIcons.dumbbell,
          label: 'Practice',
          isActive: activeTab == AppTab.train,
          onTap: () => _navigate(AppTab.train, context),
        ),
        JHGNavItem(
          icon: LucideIcons.save,
          label: 'Saved',
          isActive: activeTab == AppTab.saved,
          onTap: () => _navigate(AppTab.saved, context),
        ),
        JHGNavItem(
          // Tour key only needed on the training board (where the tour
          // runs); other screens would duplicate the same GlobalKey.
          itemKey: activeTab == AppTab.train ? tourKeyHeatmapNav : null,
          icon: Icons.insights_rounded,
          label: 'Stats',
          isActive: activeTab == AppTab.heatmap,
          onTap: () => _navigate(AppTab.heatmap, context),
        ),
        JHGNavItem(
          icon: LucideIcons.settings,
          label: 'Settings',
          isActive: activeTab == AppTab.settings,
          onTap: () => _navigate(AppTab.settings, context),
        ),
      ],
    );

    if (!kIsWeb) return bar;

    // On web, escape the parent ConstrainedBox so the dark background spans
    // the full screen width on leaderboard/heatmap/settings screens.
    // SizedBox fixes the height so the Column doesn't see an infinite child
    // (OverflowBox sizes to constraints.biggest, which is ∞ in a Column).
    final screenWidth = MediaQuery.sizeOf(context).width;
    final barHeight = 56.0 + safeBottom;
    return SizedBox(
      height: barHeight,
      child: OverflowBox(
        minWidth: screenWidth,
        maxWidth: screenWidth,
        minHeight: barHeight,
        maxHeight: barHeight,
        alignment: Alignment.bottomCenter,
        child: bar,
      ),
    );
  }
}
