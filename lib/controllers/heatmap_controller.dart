import 'package:flutter/material.dart';
import 'package:fretboard/services/heatmap_service.dart';
import 'package:get/get.dart';

class HeatmapController extends GetxController {
  final RxMap<int, FretStats> stats = <int, FretStats>{}.obs;
  final RxBool isLoading = false.obs;

  // Detail panel state
  final RxInt selectedIndex = (-1).obs;

  static const Color _noDataColor = Color(0x26FFFFFF);
  static const Color _strugglingColor = Color(0xFFE05252);
  static const Color _learningColor = Color(0xFFE8961A);
  static const Color _goodColor = Color(0xFF4CB87A);
  static const Color _masteredColor = Color(0xFF2ECC71);

  @override
  void onInit() {
    super.onInit();
    loadStats();
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
