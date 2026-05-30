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
  late HomeController homeController;
  bool _stringsExpanded = false;

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomeController>()..onDefaultTimerInitialized();
  }

  @override
  Widget build(BuildContext context) {
    final shell = JHGSettingsScreenShell(
      appName: AppStrings.appName,
      iosAppIdentifier: AppStrings.iOSBuildId,
      androidAppIdentifier: AppStrings.androidBuildId,
      appStoreId: AppStrings.appStoreId,
      enableSupportSection: !kIsWeb,
      enableReportIssueButton: true,
      horizontalPadding: kIsWeb ? 24 : null,
      sectionSpacing: 24,
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

    if (!kIsWeb) return shell;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 568),
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: shell,
            ),
          ),
        ),
      ),
    );
  }
}
