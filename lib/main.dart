import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/utils/app_subscription.dart';
import 'package:fretboard/views/screens/mode_select_screen.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';

import 'controllers/app_bindings.dart';

bool isFreePlan = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  JHGAdsHelper().init();
  StringsDownloadService();
  runApp(const MyApp());
}

final navKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     Nav.key = navKey;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarBrightness: Brightness.dark, // Dark text for status bar
    ));

    return FlutterSizer(
      builder: (BuildContext, Orientation, ScreenType) {
        return GetMaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          debugShowCheckedModeBanner: false,
          title: 'JHG Fretboard',
          theme: JHGTheme.themeData,
          initialBinding: AppBindings(),
          navigatorKey: navKey,
          home: kIsWeb
              ? const ModeSelectScreen()
              : SplashScreen(
                  yearlySubscriptionId: yearlySubscription(),
                  monthlySubscriptionId: monthlySubscription(),
                  appName: AppStrings.appName,
                  featuresList: getFeaturesList(),
                  navKey: navKey,
                  nextPage: () => const ModeSelectScreen(),
                ),
        );
      },
    );
  }
}
