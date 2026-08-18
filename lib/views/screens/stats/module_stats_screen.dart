// views/screens/stats/module_stats_screen.dart
//
// The detail screen for one non-note game — Intervals, Chords, or Chord Lab —
// opened from the Stats hub. It wraps the charted [StatBreakdownView] in a
// scaffold with a back button, the game title, and a reset control.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/views/screens/heatmap/stats_breakdown_view.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ModuleStatsScreen extends StatefulWidget {
  const ModuleStatsScreen({super.key, required this.module});

  /// 1 = Intervals, 2 = Chords, 3 = Chord Lab.
  final int module;

  @override
  State<ModuleStatsScreen> createState() => _ModuleStatsScreenState();
}

class _ModuleStatsScreenState extends State<ModuleStatsScreen> {
  late final HeatmapController controller;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HeatmapController>();
    controller.loadBreakdowns();
  }

  String get _title => switch (widget.module) {
        1 => 'Interval Stats',
        2 => 'Chord Stats',
        _ => 'Chord Lab Stats',
      };

  String get _resetName => switch (widget.module) {
        1 => 'Intervals',
        2 => 'Chords',
        _ => 'Chord Lab',
      };

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset $_resetName stats?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This permanently clears your $_resetName accuracy stats. Your other '
          'games and score history are unaffected.',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.resetModule(widget.module);
            },
            child: Text('Reset',
                style: GoogleFonts.inter(
                    color: const Color(0xFFE05252),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const webMaxWidth = 568.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ─── TOP BAR ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _iconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Get.back(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
                _iconButton(
                  icon: _showInfo
                      ? Icons.info_rounded
                      : Icons.info_outline_rounded,
                  active: _showInfo,
                  onTap: () => setState(() => _showInfo = !_showInfo),
                ),
                const SizedBox(width: 8),
                _iconButton(
                  icon: Icons.restart_alt_rounded,
                  onTap: _confirmReset,
                ),
              ],
            ),
          ),

          // ─── BODY ─────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.breakdownLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white24, strokeWidth: 1.5),
                );
              }
              return StatBreakdownView(
                module: widget.module,
                data: controller.breakdownFor(widget.module),
                showIntro: _showInfo,
              );
            }),
          ),

          // ─── NAV BAR ──────────────────────────────────────────────
          AppNavBar(activeTab: AppTab.heatmap, safeBottom: bottomInset),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: kIsWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: webMaxWidth),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
  }) {
    const coral = Color(0xFFFE5D43);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: active
              ? coral.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? coral.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Icon(icon, color: active ? coral : Colors.white54, size: 20),
      ),
    );
  }
}
