import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/widgets/default_timer.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  static const double _webContentWidth = 520.0;

  late HomeController homeController;
  bool _stringsExpanded = false;

  double _resolveHorizontalPadding(BuildContext context) {
    if (!kIsWeb) return 24.0;
    final width = MediaQuery.of(context).size.width;
    return ((width - _webContentWidth) / 2)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomeController>()..onDefaultTimerInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return JHGSettingsScreenShell(
      appName: AppStrings.appName,
      iosAppIdentifier: AppStrings.iOSBuildId,
      androidAppIdentifier: AppStrings.androidBuildId,
      appStoreId: AppStrings.appStoreId,
      enableSupportSection: !kIsWeb,
      enableReportIssueButton: !kIsWeb,
      showSettingsLabel: !kIsWeb,
      appBarLeading: kIsWeb ? const _CompactSettingsHeader() : null,
      horizontalPadding: _resolveHorizontalPadding(context),
      sectionSpacing: kIsWeb ? 20 : 24,
      sections: [
        JHGSettingsScreenSectionData(
          title: 'STRINGS',
          child: GetBuilder<HomeController>(
            builder: (controller) => JHGSettingsCard(
              child: Column(
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => _stringsExpanded = !_stringsExpanded),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: JHGColors.greyishBlack,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.layers,
                                color: Colors.white54, size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Guitar Strings',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
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
                    const JHGSettingsDivider(),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: JHGSettingsNestedCard(
                        child: Column(
                          children: [
                            JHGSettingsSwitchTile(
                              title: AppStrings.string6,
                              subtitle: 'Low E string',
                              icon: LucideIcons.music,
                              value: controller.string6,
                              onChanged: (_) {
                                controller.setString6(0);
                                controller.saveStrings();
                              },
                            ),
                            const JHGSettingsDivider(),
                            JHGSettingsSwitchTile(
                              title: AppStrings.string5,
                              subtitle: 'A string',
                              icon: LucideIcons.music,
                              value: controller.string5,
                              onChanged: (_) {
                                controller.setString5(1);
                                controller.saveStrings();
                              },
                            ),
                            const JHGSettingsDivider(),
                            JHGSettingsSwitchTile(
                              title: AppStrings.string4,
                              subtitle: 'D string',
                              icon: LucideIcons.music,
                              value: controller.string4,
                              onChanged: (_) {
                                controller.setString4(2);
                                controller.saveStrings();
                              },
                            ),
                            const JHGSettingsDivider(),
                            JHGSettingsSwitchTile(
                              title: AppStrings.string3,
                              subtitle: 'G string',
                              icon: LucideIcons.music,
                              value: controller.string3,
                              onChanged: (_) {
                                controller.setString3(3);
                                controller.saveStrings();
                              },
                            ),
                            const JHGSettingsDivider(),
                            JHGSettingsSwitchTile(
                              title: AppStrings.string2,
                              subtitle: 'B string',
                              icon: LucideIcons.music,
                              value: controller.string2,
                              onChanged: (_) {
                                controller.setString2(4);
                                controller.saveStrings();
                              },
                            ),
                            const JHGSettingsDivider(),
                            JHGSettingsSwitchTile(
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
          ),
        ),
        JHGSettingsScreenSectionData(
          title: 'TIMER',
          child: JHGSettingsCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SettingsDefaultTimer(controller: homeController),
                ),
              ],
            ),
          ),
        ),
        JHGSettingsScreenSectionData(
          title: 'ACCOUNT',
          visible: !kIsWeb,
          child: JHGSettingsCard(
            child: JHGSettingsDestructiveTile(
              title: AppStrings.logout,
              icon: LucideIcons.logOut,
              onTap: () async {
                await LocalDB.clearLocalDB();
                Nav.offAll(WelcomeScreen());
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactSettingsHeader extends StatelessWidget {
  const _CompactSettingsHeader();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.chevronLeft,
              color: Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 2),
            Text(
              'Settings',
              style: JHGTextStyles.labelStyle.copyWith(
                color: Colors.white54,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
