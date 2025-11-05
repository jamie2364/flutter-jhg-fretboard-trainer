import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fretboard/utils/app_strings.dart';

String monthlySubscription() {
  return Platform.isAndroid
      ? AppStrings.androidMonthlySubscriptionId
      : AppStrings.iosMonthlySubscriptionId;
}

String yearlySubscription() {
  return Platform.isAndroid
      ? AppStrings.androidYearlySubscriptionId
      : AppStrings.iosYearlySubscriptionId;
}

String get nativeBannerAdId => kIsWeb
    ? ''
    : Platform.isAndroid
        ? 'ca-app-pub-8243857750402094/2199455522'
        : 'ca-app-pub-8243857750402094/6682261445';

String get bannerAdId => kIsWeb
    ? ''
    : Platform.isAndroid
        ? 'ca-app-pub-8243857750402094/7568946017'
        : 'ca-app-pub-8243857750402094/2891334408';

String get interstitialAdId => kIsWeb
    ? ''
    : Platform.isAndroid
        ? 'ca-app-pub-8243857750402094/3512537192'
        : 'ca-app-pub-8243857750402094/7038683778';

List<String> getFeaturesList() {
  var featuresList = <String>[];
  featuresList.add("Get Access to Fretboard Trainer");
  featuresList.add("Learn every note on the fretboard");
  featuresList.add("Ad-Free Experience");
  featuresList.add("Instant Access After Purchase");
  return featuresList;
}
