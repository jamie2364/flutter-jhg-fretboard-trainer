import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/utils/app_subscription.dart';
import 'package:fretboard/views/widgets/default_timer.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reg_page/reg_page.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late HomeController homeController;
  StreamController<bool> expansionStream = StreamController<bool>.broadcast();
  bool _stringsExpanded = false;

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomeController>()..onDefaultTimerInitialized();
  }

  @override
  void dispose() {
    expansionStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width > 700 ? 48.0 : 20.0;
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(LucideIcons.chevronLeft300,
                  color: Colors.white, size: 22),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (!kIsWeb)
                GestureDetector(
                  onTap: () => Nav.to(BugReportScreen()),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(LucideIcons.bug,
                        color: JHGColors.primary, size: 22),
                  ),
                ),
            ],
          ),

          // ─── BODY ─────────────────────────────────────────────────
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── STRINGS ──────────────────────────────────────────
                _sectionHeader('STRINGS'),
                _card(
                  child: Column(
                    children: [
                      // Collapsible header
                      InkWell(
                        onTap: () => setState(() => _stringsExpanded = !_stringsExpanded),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.layers,
                                    color: Colors.white54, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Guitar Strings',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                _stringsExpanded
                                    ? LucideIcons.chevronUp
                                    : LucideIcons.chevronDown,
                                color: Colors.white38,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_stringsExpanded) ...[
                        _divider(),
                        _switchTile(
                          title: AppStrings.string6,
                          subtitle: 'Low E string',
                          value: controller.string6,
                          onChanged: (_) => controller.setString6(0),
                        ),
                        _divider(),
                        _switchTile(
                          title: AppStrings.string5,
                          subtitle: 'A string',
                          value: controller.string5,
                          onChanged: (_) => controller.setString5(1),
                        ),
                        _divider(),
                        _switchTile(
                          title: AppStrings.string4,
                          subtitle: 'D string',
                          value: controller.string4,
                          onChanged: (_) => controller.setString4(2),
                        ),
                        _divider(),
                        _switchTile(
                          title: AppStrings.string3,
                          subtitle: 'G string',
                          value: controller.string3,
                          onChanged: (_) => controller.setString3(3),
                        ),
                        _divider(),
                        _switchTile(
                          title: AppStrings.string2,
                          subtitle: 'B string',
                          value: controller.string2,
                          onChanged: (_) => controller.setString2(4),
                        ),
                        _divider(),
                        _switchTile(
                          title: AppStrings.string1,
                          subtitle: 'High e string',
                          value: controller.string1,
                          onChanged: (_) => controller.setString1(5),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── TIMER ─────────────────────────────────────────────
                _sectionHeader('TIMER'),
                _card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SettingsDefaultTimer(controller: controller),
                  ),
                ),

                const SizedBox(height: 24),

                // ── SUPPORT ───────────────────────────────────────────
                _sectionHeader('SUPPORT'),
                _card(
                  child: Column(
                    children: [
                      _actionTile(
                        icon: LucideIcons.share,
                        title: 'Share App',
                        onTap: () {},
                      ),
                      _divider(),
                      _actionTile(
                        icon: LucideIcons.star,
                        title: 'Rate the App',
                        onTap: () {},
                      ),
                      _divider(),
                      _actionTile(
                        icon: LucideIcons.book,
                        title: 'Documentation',
                        onTap: () {},
                      ),
                      _divider(),
                      _actionTile(
                        icon: LucideIcons.layers,
                        title: 'View More Apps',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // ─── BOTTOM BAR ───────────────────────────────────────────
          bottomNavigationBar: Container(
            padding: EdgeInsets.fromLTRB(
                hPad, 16, hPad, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Save
                GestureDetector(
                  onTap: () => controller.onClickSave(context),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: JHGColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.save,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Logout
                GestureDetector(
                  onTap: () async {
                    await LocalDB.clearLocalDB();
                    Nav.offAll(WelcomeScreen());
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.35)),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.logout,
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                if (isFreePlan) ...[
                  const SizedBox(height: 10),
                  JHGBannerAd(adId: bannerAdId),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              value ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: value ? JHGColors.primary : Colors.white38,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: JHGColors.primary,
            activeTrackColor: JHGColors.primary.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white54, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
