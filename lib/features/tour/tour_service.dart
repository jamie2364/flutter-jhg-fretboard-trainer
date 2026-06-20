import 'package:shared_preferences/shared_preferences.dart';

class TourService {
  static const _key = 'fretboard_tour_v1_completed';
  static const _heatmapKey = 'fretboard_heatmap_intro_pending';

  static Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static void markTourCompleted() {
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_key, true));
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
    await prefs.setBool(_heatmapKey, false);
  }

  /// Set when the main tour ends — signals HeatmapScreen to show its intro.
  static void scheduleHeatmapIntro() {
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_heatmapKey, true));
  }

  static Future<bool> shouldShowHeatmapIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_heatmapKey) ?? false;
  }

  static Future<void> markHeatmapIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_heatmapKey, false);
  }
}
