import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/utils/app_subscription.dart';
import 'package:fretboard/views/widgets/default_timer.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  HomeController homeController = Get.find<HomeController>();
  String deviceName = 'Unknown';
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  Future<void> getDeviceInfo() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final device = await deviceInfoPlugin.androidInfo;
      deviceName = "${device.manufacturer} ${device.model}";
    } else if (Platform.isIOS) {
      final device = await deviceInfoPlugin.iosInfo;
      deviceName = device.name;
    } else if (Platform.isWindows) {
      print("window");
    } else if (Platform.isMacOS) {
      print("mac");
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPackageInfo();
    }
    homeController.onDefaultTimerInitialized();
  }

  Future<void> _initPackageInfo() async {
    await getDeviceInfo();
  }

  bool toggle = true;
  ValueNotifier<bool> isExpanded = ValueNotifier(false);
  StreamController<bool> expansionStream = StreamController<bool>.broadcast();

  @override
  void dispose() {
    expansionStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        return controller.isPortrait || kIsWeb
            ? JHGSettings(
                androidAppIdentifier: AppStrings.androidBuildId,
                iosAppIdentifier: AppStrings.iOSBuildId,
                appStoreId: AppStrings.appStoreId,
                appName: AppStrings.appName,
                viewMoreAppsUrl: kIsWeb
                    ? ""
                    : Platform.isAndroid
                        ? kJhgPlayStoreUrl
                        : null,
                bodyAppBar: JHGAppBar(
                  isResponsive: true,
                  title: Text(
                    'Settings',
                    style: JHGTextStyles.smlabelStyle,
                  ),
                  rowHeight: JHGAppBar.height,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  trailingWidget: kIsWeb
                      ? null
                      : JHGReportAnIssueBtn(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BugReportScreen(),
                              ),
                            );
                          },
                        ),
                ),
                trailing: isFreePlan
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: JHGBannerAd(adId: bannerAdId)
                        // JHGNativeBanner(
                        //   adID: nativeBannerAdId,
                        // ),
                        )
                    : const SizedBox(),
                body: settingPortrait(
                    controller: controller, height: height, width: width),
                onTapSave: () => controller.onClickSave(context),
                onTapLogout: () async {
                  await LocalDB.clearLocalDB();
                  // ignore: use_build_context_synchronously
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) {
                    return WelcomeScreen();
                  }), (route) => false);
                },
              )
            : JHGSettingsLandscape(
                androidAppIdentifier: AppStrings.androidBuildId,
                iosAppIdentifier: AppStrings.iOSBuildId,
                appStoreId: AppStrings.appStoreId,
                appName: AppStrings.appName,
                isExpanded: expansionStream.stream,
                bodyAppBar: JHGAppBar(
                  isResponsive: true,
                  title: Text(
                    'Settings',
                    style: JHGTextStyles.smlabelStyle,
                  ),
                  trailingWidget: kIsWeb
                      ? null
                      : JHGReportAnIssueBtn(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BugReportScreen(),
                              ),
                            );
                          },
                        ),
                ),
                trailing: isFreePlan
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: JHGBannerAd(adId: bannerAdId))
                    : const SizedBox(),
                body: settingLandscape(
                    controller: controller, height: height, width: width),
                onTapSave: () => controller.onClickSave(context),
                onTapLogout: () async {
                  await LocalDB.clearLocalDB();
                  // ignore: use_build_context_synchronously
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) {
                    return WelcomeScreen();
                  }), (route) => false);
                },
              );
      },
    );
  }

  Widget settingPortrait(
      {required HomeController controller,
      required double height,
      required double width}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSettingsUi(controller),
      ],
    );
  }

  Widget settingLandscape(
      {required HomeController controller,
      required double height,
      required double width}) {
    return Container(
        width: height,
        color: JHGColors.secondryBlack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSettingsUi(controller),
            SimpleDropdownButton(),
            SizedBox(
              height: width * 0.04,
            ),
          ],
        ));
  }

  Widget buildSettingsUi(HomeController controller) {
    return StreamBuilder<bool>(
      stream: expansionStream.stream,
      initialData: false,
      builder: (context, snapshot) {
        bool val = snapshot.data ?? false;
        return Column(
          children: [
            SizedBox(
              height: 20,
            ),
            JHGHeadWithActions(
              AppStrings.strings,
              margin: EdgeInsets.only(top: 6),
              subLabel: AppStrings.stringDescriptionLandscape,
              titleStyle: JHGTextStyles.labelStyle,
              subtitleStyle: JHGTextStyles.subLabelStyle.copyWith(fontSize: 12),
              onTapTitle: () {
                expansionStream.sink.add(!val);
              },
              onArrowDownTap: () {
                expansionStream.sink.add(!val);
              },
              arrowIcon:
                  val ? LucideIcons.chevronUp300 : LucideIcons.chevronDown300,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.2),
              ),
              child: JHGExpandableSection(
                expand: val,
                child: Column(
                  children: [
                    JHGSwitchInfoTile(
                        paddingTop: 0,
                        title: AppStrings.string6,
                        value: controller.string6,
                        onChanged: (val) {
                          controller.setString6(0);
                        }),
                    JHGSwitchInfoTile(
                        paddingTop: 0,
                        title: AppStrings.string5,
                        value: controller.string5,
                        onChanged: (val) {
                          controller.setString5(1);
                        }),
                    JHGSwitchInfoTile(
                        paddingTop: 0,
                        title: AppStrings.string4,
                        value: controller.string4,
                        onChanged: (val) {
                          controller.setString4(2);
                        }),
                    JHGSwitchInfoTile(
                        paddingTop: 0,
                        title: AppStrings.string3,
                        value: controller.string3,
                        onChanged: (val) {
                          controller.setString3(3);
                        }),
                    JHGSwitchInfoTile(
                        paddingTop: 0,
                        title: AppStrings.string2,
                        value: controller.string2,
                        onChanged: (val) {
                          controller.setString2(4);
                        }),
                    JHGSwitchInfoTile(
                        paddingTop: 0,
                        title: AppStrings.string1,
                        value: controller.string1,
                        onChanged: (val) {
                          controller.setString1(5);
                        }),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
                width: MediaQuery.sizeOf(context).height * 0.85,
                child: SettingsDefaultTimer(controller: controller)),
          ],
        );
      },
    );
  }
}

class SimpleDropdownButton extends StatefulWidget {
  @override
  _SimpleDropdownButtonState createState() => _SimpleDropdownButtonState();
}

class _SimpleDropdownButtonState extends State<SimpleDropdownButton> {
  String? _selectedItem; // Stores the currently selected item

  List<String> _dropdownItems = [
    'Option 1',
    'Option 2',
    'Option 3',
    'Option 4'
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DropdownButton<String>(
        value: _selectedItem, // The currently selected value
        hint: Text(
            'Select an option'), // Placeholder text when no item is selected
        items: _dropdownItems.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedItem = newValue; // Update the selected item
          });
        },
      ),
    );
  }
}
