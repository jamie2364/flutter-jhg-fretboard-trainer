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

const _kNavBg     = Color(0xFF1C1B1B);
const _kNavActive  = Color(0xFFFF5F40);
const _kNavInactive = Color(0xFF7A7A7A);

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
    final bar = Container(
      height: 56 + safeBottom,
      decoration: const BoxDecoration(
        color: _kNavBg,
        border: Border(top: BorderSide(color: Color(0xFF2E2E2E))),
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
                  icon: Icons.music_note_rounded,
                  isActive: activeTab == AppTab.home,
                  onTap: () => _navigate(AppTab.home, context),
                ),
                _NavItem(
                  icon: LucideIcons.trophy300,
                  isActive: activeTab == AppTab.leaderboard,
                  onTap: () => _navigate(AppTab.leaderboard, context),
                ),
                _NavItem(
                  // Tour key only needed on the home screen; other screens
                  // share the same GlobalKey instance which would duplicate it.
                  key: activeTab == AppTab.home ? tourKeyHeatmapNav : null,
                  icon: Icons.insights_rounded,
                  isActive: activeTab == AppTab.heatmap,
                  onTap: () => _navigate(AppTab.heatmap, context),
                ),
                _NavItem(
                  icon: LucideIcons.settings300,
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
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kNavActive : _kNavInactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? _kNavActive.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}
