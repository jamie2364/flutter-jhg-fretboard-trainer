import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/tour_controller.dart';
import 'package:fretboard/features/tour/tour_service.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
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
  bool _stringsExpanded = false;

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomeController>()..onDefaultTimerInitialized();
  }

  @override
  Widget build(BuildContext context) {
    final navBar = AppNavBar(
      activeTab: AppTab.settings,
      safeBottom: MediaQuery.paddingOf(context).bottom,
    );

    return Scaffold(
      backgroundColor: context.jhg.page,
      bottomNavigationBar: navBar,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: kIsWeb ? 568 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SettingsHeader(),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: GetBuilder<HomeController>(
                      builder: (controller) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                          children: [
                            const SettingsSectionLabel('IDENTIFY MODE'),
                            SettingsCard(
                              child: Column(
                                children: [
                                  SettingsSwitchTile(
                                    icon: LucideIcons.mapPin,
                                    title: 'Show position hint',
                                    subtitle:
                                        'Display string & fret below the answer buttons',
                                    value: controller.identifyShowPositionHint,
                                    onChanged: (_) {
                                      controller.identifyShowPositionHint =
                                          !controller.identifyShowPositionHint;
                                      controller.update();
                                    },
                                  ),
                                  const SettingsDivider(),
                                  SettingsSwitchTile(
                                    icon: LucideIcons.skipForward,
                                    title: 'Auto-advance',
                                    subtitle:
                                        'Move to next note automatically after a correct answer',
                                    value: controller.identifyAutoAdvance,
                                    onChanged: (_) {
                                      controller.identifyAutoAdvance =
                                          !controller.identifyAutoAdvance;
                                      controller.update();
                                    },
                                  ),
                                  const SettingsDivider(),
                                  SettingsSwitchTile(
                                    icon: LucideIcons.volume2,
                                    title: 'Auto-play sound',
                                    subtitle:
                                        'Play each note/chord automatically. Off by default — use the Listen button to hear it on demand',
                                    value: controller.identifyPlaySound,
                                    onChanged: (_) {
                                      controller.identifyPlaySound =
                                          !controller.identifyPlaySound;
                                      controller.update();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            const SettingsSectionLabel('STRINGS'),
                            SettingsCard(
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () => setState(
                                        () => _stringsExpanded = !_stringsExpanded),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          const SettingsIconChip(
                                              icon: LucideIcons.layers),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              'Guitar Strings',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            _stringsExpanded
                                                ? LucideIcons.chevronUp
                                                : LucideIcons.chevronDown,
                                            color: Colors.white24,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_stringsExpanded) ...[
                                    const SettingsDivider(),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: SettingsNestedCard(
                                        child: Column(
                                          children: [
                                            SettingsSwitchTile(
                                              title: AppStrings.string6,
                                              subtitle: 'Low E string',
                                              icon: LucideIcons.music,
                                              value: controller.string6,
                                              onChanged: (_) {
                                                controller.setString6(0);
                                                controller.saveStrings();
                                              },
                                            ),
                                            const SettingsDivider(),
                                            SettingsSwitchTile(
                                              title: AppStrings.string5,
                                              subtitle: 'A string',
                                              icon: LucideIcons.music,
                                              value: controller.string5,
                                              onChanged: (_) {
                                                controller.setString5(1);
                                                controller.saveStrings();
                                              },
                                            ),
                                            const SettingsDivider(),
                                            SettingsSwitchTile(
                                              title: AppStrings.string4,
                                              subtitle: 'D string',
                                              icon: LucideIcons.music,
                                              value: controller.string4,
                                              onChanged: (_) {
                                                controller.setString4(2);
                                                controller.saveStrings();
                                              },
                                            ),
                                            const SettingsDivider(),
                                            SettingsSwitchTile(
                                              title: AppStrings.string3,
                                              subtitle: 'G string',
                                              icon: LucideIcons.music,
                                              value: controller.string3,
                                              onChanged: (_) {
                                                controller.setString3(3);
                                                controller.saveStrings();
                                              },
                                            ),
                                            const SettingsDivider(),
                                            SettingsSwitchTile(
                                              title: AppStrings.string2,
                                              subtitle: 'B string',
                                              icon: LucideIcons.music,
                                              value: controller.string2,
                                              onChanged: (_) {
                                                controller.setString2(4);
                                                controller.saveStrings();
                                              },
                                            ),
                                            const SettingsDivider(),
                                            SettingsSwitchTile(
                                              title: AppStrings.string1,
                                              subtitle: 'High e string',
                                              icon: LucideIcons.music,
                                              value: controller.string1,
                                              onChanged: (_) {
                                                controller.setString1(5);
                                                controller.saveStrings();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            const SettingsSectionLabel('TIMER'),
                            SettingsCard(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: SettingsDefaultTimer(
                                    controller: homeController),
                              ),
                            ),
                            if (!kIsWeb) ...[
                              const SizedBox(height: 26),
                              const SettingsSectionLabel('SUPPORT'),
                              const _SupportSection(),
                            ],
                            const SizedBox(height: 26),
                            const SettingsSectionLabel('HELP'),
                            const SettingsCard(
                              child: SettingsActionTile(
                                icon: LucideIcons.circleHelp,
                                title: 'Replay App Tour',
                                subtitle: 'Show the guided walkthrough again',
                                onTap: _replayTour,
                              ),
                            ),
                            if (!kIsWeb) ...[
                              const SizedBox(height: 26),
                              const SettingsSectionLabel('ACCOUNT'),
                              SettingsCard(
                                child: SettingsDestructiveTile(
                                  icon: LucideIcons.logOut,
                                  title: AppStrings.logout,
                                  onTap: () async {
                                    await LocalDB.clearLocalDB();
                                    Nav.offAll(const WelcomeScreen());
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.jhg.surfaceChip,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: context.jhg.border),
              ),
              child: const Icon(LucideIcons.chevronLeft,
                  color: Colors.white70, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Settings',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Report/bug affordance — owned by the design system.
          const SettingsReportButton(),
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) {
    final c = SettingsControler(
      appName: AppStrings.appName,
      iosAppIdentifier: AppStrings.iOSBuildId,
      androidAppIdentifier: AppStrings.androidBuildId,
      appShareText:
          'Use Fretboard Trainer App to unlock your musical potential.\nDownload it here:\n',
      appStoreId: AppStrings.appStoreId,
      viewMoreAppsUrl: 'https://www.jamieharrisonguitar.com/apps',
    );

    final showRemoveAds = isFreePlan;

    return SettingsCard(
      child: Column(
        children: [
          SettingsActionTile(
            title: 'Share App',
            icon: LucideIcons.share2,
            onTap: c.onClickShareApp,
          ),
          const SettingsDivider(),
          SettingsActionTile(
            title: 'Rate Us',
            icon: LucideIcons.star,
            onTap: () => c.onClickRateUs(context),
          ),
          const SettingsDivider(),
          SettingsActionTile(
            title: 'Documentation',
            icon: LucideIcons.bookOpen,
            onTap: c.onClickDocumentation,
          ),
          const SettingsDivider(),
          SettingsActionTile(
            title: 'View More Apps',
            icon: LucideIcons.layers,
            onTap: c.onClickViewMoreApps,
          ),
          if (showRemoveAds) ...[
            const SettingsDivider(),
            SettingsActionTile(
              title: 'Remove Ads',
              icon: LucideIcons.zap,
              onTap: () => c.onRemoveAdsTap(context, null),
            ),
          ],
        ],
      ),
    );
  }
}

void _replayTour() async {
  await TourService.resetTour();
  if (Get.isRegistered<TourController>()) {
    Get.back();
    await Future.delayed(const Duration(milliseconds: 350));
    Get.find<TourController>().start();
  }
}
