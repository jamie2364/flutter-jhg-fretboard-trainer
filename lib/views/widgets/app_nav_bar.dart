import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/routes.dart';
import 'package:fretboard/views/screens/stats/stats_hub_screen.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Mirrors the shared AppBottomNav used across the apps (dark bar, coral active,
// stacked icon + label, no pill).
const _kNavBg = Color(0xFF0F0F0F);
const _kNavInactive = Color(0xFF9E9A98);

enum AppTab { home, train, leaderboard, heatmap, settings }

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.activeTab,
    this.controller,
    this.safeBottom = 0,
  });

  final AppTab activeTab;
  final HomeController? controller;
  final double safeBottom;

  void _navigate(AppTab tab, BuildContext context) {
    if (tab == activeTab) return;
    final hc = controller ?? Get.find<HomeController>();

    // Leaving an in-progress session (anything except staying on Train) ends
    // the round — confirm first with a professional dialog so a good streak
    // isn't lost by a stray tap.
    if (hc.sessionActive && tab != AppTab.train) {
      _confirmLeaveSession(context, () => _go(tab, hc, endSession: true));
      return;
    }
    _go(tab, hc, endSession: false);
  }

  void _go(AppTab tab, HomeController hc, {required bool endSession}) {
    if (endSession) hc.resetGame(false);
    final fromBoard = activeTab == AppTab.train;
    switch (tab) {
      case AppTab.home:
        // Home → the very first screen (StartScreen is the root route).
        hc.resetGame(false);
        Get.until((r) => r.isFirst);
        break;
      case AppTab.train:
        // Practice → back to the training board (tagged with kBoardRoute when
        // launched). Falls back to the first route if it isn't in the stack.
        Get.until((r) => r.settings.name == kBoardRoute || r.isFirst);
        break;
      case AppTab.leaderboard:
        // From the board, push (so Practice can return to it); between the
        // secondary screens, replace so the stack stays flat.
        fromBoard
            ? Get.to(() => const LeadershipScreen(),
                transition: Transition.noTransition, duration: Duration.zero)
            : Get.off(() => const LeadershipScreen(),
                transition: Transition.noTransition, duration: Duration.zero);
        if (isFreePlan) hc.interstitialAds?.showInterstitial();
        break;
      case AppTab.heatmap:
        fromBoard
            ? Get.to(() => const StatsHubScreen(),
                transition: Transition.noTransition, duration: Duration.zero)
            : Get.off(() => const StatsHubScreen(),
                transition: Transition.noTransition, duration: Duration.zero);
        break;
      case AppTab.settings:
        fromBoard
            ? Get.to(() => const SettingScreen(),
                transition: Transition.noTransition, duration: Duration.zero)
            : Get.off(() => const SettingScreen(),
                transition: Transition.noTransition, duration: Duration.zero);
        if (isFreePlan) hc.interstitialAds?.showInterstitial();
        break;
    }
  }

  void _confirmLeaveSession(BuildContext context, VoidCallback onConfirm) {
    showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: Icons.logout_rounded,
        title: 'End this session?',
        description:
            'Leaving this screen will end your current practice session. '
            'Your score for this round won\'t be saved.',
        content: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: JHGFrostedPrimaryButton(
                label: 'Continue',
                onTap: () {
                  Navigator.of(ctx).pop();
                  onConfirm();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Every tab stays enabled and uniformly coloured — only the active one is
    // white. Leaving mid-session is gated by a confirm dialog (see _navigate),
    // not by greying tabs out.
    final bar = Container(
      height: 56 + safeBottom,
      decoration: BoxDecoration(
        color: _kNavBg,
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.12), width: 1.5),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 568),
          child: Padding(
            padding: EdgeInsets.only(bottom: safeBottom),
            child: Row(
              children: [
                _NavItem(
                  icon: LucideIcons.home300,
                  label: 'Home',
                  isActive: activeTab == AppTab.home,
                  onTap: () => _navigate(AppTab.home, context),
                ),
                _NavItem(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Practice',
                  isActive: activeTab == AppTab.train,
                  onTap: () => _navigate(AppTab.train, context),
                ),
                _NavItem(
                  icon: LucideIcons.trophy300,
                  label: 'Leaders',
                  isActive: activeTab == AppTab.leaderboard,
                  onTap: () => _navigate(AppTab.leaderboard, context),
                ),
                _NavItem(
                  // Tour key only needed on the training board (where the tour
                  // runs); other screens would duplicate the same GlobalKey.
                  key: activeTab == AppTab.train ? tourKeyHeatmapNav : null,
                  icon: Icons.insights_rounded,
                  label: 'Stats',
                  isActive: activeTab == AppTab.heatmap,
                  onTap: () => _navigate(AppTab.heatmap, context),
                ),
                _NavItem(
                  icon: LucideIcons.settings300,
                  label: 'Settings',
                  isActive: activeTab == AppTab.settings,
                  onTap: () => _navigate(AppTab.settings, context),
                ),
              ],
            ),
          ),
        ),
      ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : _kNavInactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 10,
                height: 1.0,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
