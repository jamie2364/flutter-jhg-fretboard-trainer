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
import 'dart:async' show unawaited;
import 'package:fretboard/services/app_flags.dart';
import 'package:fretboard/services/saved_sessions_service.dart';

bool isFreePlan = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  JHGAdsHelper().init();
  StringsDownloadService();
  // Read before the first frame so Home knows whether this is a fresh install.
  await AppFlags.init();
  // Prime the saved-session count so Home can render Continue / Saved Sessions
  // without a blank flash.
  unawaited(SavedSessionsService.refreshCount());
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarBrightness: Brightness.dark, // Dark text for status bar
    ));

    return FlutterSizer(
      builder: (BuildContext, Orientation, ScreenType) {
        return GetMaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          debugShowCheckedModeBanner: false,
          title: 'JHG Fretboard',
          // Additively attach the design-system tokens; existing theme unchanged.
          theme: JHGTheme.themeData.copyWith(
            extensions: <ThemeExtension<dynamic>>[JhgTokens.dark()],
          ),
          initialBinding: AppBindings(),
          navigatorKey: navKey,
          home: kIsWeb
              ? const StartScreen()
              : SplashScreen(
                  yearlySubscriptionId: yearlySubscription(),
                  monthlySubscriptionId: monthlySubscription(),
                  appName: AppStrings.appName,
                  featuresList: getFeaturesList(),
                  navKey: navKey,
                  nextPage: () => const StartScreen(),
                ),
        );
      },
    );
  }
}
