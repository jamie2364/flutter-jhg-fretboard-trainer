import 'package:flutter/material.dart';
import 'package:fretboard/services/heatmap_service.dart';
import 'package:fretboard/services/practice_stats_service.dart';
import 'package:get/get.dart';

class HeatmapController extends GetxController {
  final RxMap<int, FretStats> stats = <int, FretStats>{}.obs;
  final RxBool isLoading = false.obs;

  // Detail panel state (Notes fretboard tap-to-inspect)
  final RxInt selectedIndex = (-1).obs;

  // ── Stats-hub module breakdowns ─────────────────────────────────────────────
  // 0 = Notes, 1 = Intervals, 2 = Chords, 3 = Chord Lab. Each game gets its own
  // detail screen; the hub reads these summaries.
  final Rx<ModuleBreakdown> noteStats = ModuleBreakdown.empty.obs;
  final Rx<ModuleBreakdown> intervalStats = ModuleBreakdown.empty.obs;
  final Rx<ModuleBreakdown> chordStats = ModuleBreakdown.empty.obs;
  final Rx<ModuleBreakdown> labStats = ModuleBreakdown.empty.obs;
  final RxBool breakdownLoading = false.obs;

  Future<void> loadBreakdowns() async {
    breakdownLoading.value = true;
    noteStats.value =
        await PracticeStatsService.loadBreakdown(StatsModule.note);
    intervalStats.value =
        await PracticeStatsService.loadBreakdown(StatsModule.interval);
    chordStats.value =
        await PracticeStatsService.loadBreakdown(StatsModule.chord);
    labStats.value =
        await PracticeStatsService.loadBreakdown(StatsModule.chordLab);
    breakdownLoading.value = false;
  }

  ModuleBreakdown breakdownFor(int module) {
    switch (module) {
      case 1:
        return intervalStats.value;
      case 2:
        return chordStats.value;
      case 3:
        return labStats.value;
      default:
        return noteStats.value;
    }
  }

  StatsModule statsModuleFor(int module) {
    switch (module) {
      case 1:
        return StatsModule.interval;
      case 2:
        return StatsModule.chord;
      case 3:
        return StatsModule.chordLab;
      default:
        return StatsModule.note;
    }
  }

  /// Resets one module's stats. Notes also clears the per-fret heatmap store.
  Future<void> resetModule(int module) async {
    await PracticeStatsService.clear(statsModuleFor(module));
    if (module == 0) await clearStats();
    await loadBreakdowns();
  }

  // Hub-card summaries. Every module — Notes included — reads from its reactive
  // ModuleBreakdown (Notes records the same Find/Identify attempts the per-fret
  // heatmap does), so the hub rebuilds cleanly when a breakdown reloads.
  double accuracyFor(int module) => breakdownFor(module).accuracy;
  int attemptsFor(int module) => breakdownFor(module).totalAttempts;

  static const Color _noDataColor = Color(0x26FFFFFF);
  static const Color _strugglingColor = Color(0xFFE05252);
  static const Color _learningColor = Color(0xFFE8961A);
  static const Color _goodColor = Color(0xFF4CB87A);
  static const Color _masteredColor = Color(0xFF2ECC71);

  @override
  void onInit() {
    super.onInit();
    loadStats();
    loadBreakdowns();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    final data = await HeatmapService.loadAll();
    stats.value = data;
    isLoading.value = false;
  }

  Future<void> clearStats() async {
    isLoading.value = true;
    await HeatmapService.clearAll();
    final data = await HeatmapService.loadAll();
    stats.value = data;
    selectedIndex.value = -1;
    isLoading.value = false;
  }

  Color getHeatColor(int index) {
    final stat = stats[index];
    if (stat == null || !stat.hasData) return _noDataColor;
    final acc = stat.accuracy;
    if (acc >= 0.85) return _masteredColor;
    if (acc >= 0.70) return _goodColor;
    if (acc >= 0.50) return _learningColor;
    return _strugglingColor;
  }

  Color getBorderColor(int index) {
    final stat = stats[index];
    if (stat == null || !stat.hasData) return const Color(0x40FFFFFF);
    return getHeatColor(index);
  }

  // Summary stats
  int get totalPracticed =>
      stats.values.where((s) => s.hasData).length;

  int get mastered =>
      stats.values.where((s) => s.hasData && s.accuracy >= 0.85).length;

  int get struggling =>
      stats.values.where((s) => s.hasData && s.accuracy < 0.50).length;

  void selectFret(int index) {
    selectedIndex.value = selectedIndex.value == index ? -1 : index;
  }
}
