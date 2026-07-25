import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/tour_keys.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Mirrors the shared AppBottomNav used across the apps (dark bar, coral active,
// stacked icon + label, no pill).
const _kNavBg = Color(0xFF0F0F0F);
const _kNavActive = Color(0xFFFE5D43);
const _kNavInactive = Color(0xFF9E9A98);

enum AppTab { home, leaderboard, heatmap, settings }

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

    // Guard: while a session is in progress the user may only return Home —
    // every other tab is blocked so the running game can't be abandoned.
    if (tab != AppTab.home && hc.sessionActive) return;
    // Guard: settings is off-limits in leaderboard mode, from any screen.
    if (tab == AppTab.settings && hc.currentGameMode.value == 'leaderboard') {
      return;
    }

    switch (tab) {
      case AppTab.home:
        Get.back();
        break;
      case AppTab.leaderboard:
        if (activeTab == AppTab.home) {
          Get.to(() => LeadershipScreen(), transition: Transition.noTransition, duration: Duration.zero);
          if (isFreePlan) hc.interstitialAds?.showInterstitial();
        } else {
          Get.off(() => LeadershipScreen(), transition: Transition.noTransition, duration: Duration.zero);
        }
        break;
      case AppTab.heatmap:
        if (activeTab == AppTab.home) {
          Get.to(() => const HeatmapScreen(), transition: Transition.noTransition, duration: Duration.zero);
        } else {
          Get.off(() => const HeatmapScreen(), transition: Transition.noTransition, duration: Duration.zero);
        }
        break;
      case AppTab.settings:
        if (activeTab == AppTab.home) {
          hc.resetGame(false);
          Get.to(() => SettingScreen(), transition: Transition.noTransition, duration: Duration.zero);
          if (isFreePlan) hc.interstitialAds?.showInterstitial();
        } else {
          Get.off(() => SettingScreen(), transition: Transition.noTransition, duration: Duration.zero);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hc = controller ?? Get.find<HomeController>();
    // Mid-session everything but Home is locked; settings is also locked
    // whenever leaderboard mode is selected.
    final navLocked = hc.sessionActive;
    final settingsLocked =
        navLocked || hc.currentGameMode.value == 'leaderboard';

    final bar = Container(
      height: 56 + safeBottom,
      decoration: BoxDecoration(
        color: _kNavBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                  icon: LucideIcons.trophy300,
                  label: 'Leaders',
                  isActive: activeTab == AppTab.leaderboard,
                  disabled: navLocked && activeTab != AppTab.leaderboard,
                  onTap: () => _navigate(AppTab.leaderboard, context),
                ),
                _NavItem(
                  // Tour key only needed on the home screen; other screens
                  // share the same GlobalKey instance which would duplicate it.
                  key: activeTab == AppTab.home ? tourKeyHeatmapNav : null,
                  icon: Icons.insights_rounded,
                  label: 'Stats',
                  isActive: activeTab == AppTab.heatmap,
                  disabled: navLocked && activeTab != AppTab.heatmap,
                  onTap: () => _navigate(AppTab.heatmap, context),
                ),
                _NavItem(
                  icon: LucideIcons.settings300,
                  label: 'Settings',
                  isActive: activeTab == AppTab.settings,
                  disabled: settingsLocked && activeTab != AppTab.settings,
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
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? Colors.white12
        : isActive
            ? _kNavActive
            : _kNavInactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : onTap,
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
                decoration: TextDecoration.none,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
