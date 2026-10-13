// views/screens/stats/module_stats_screen.dart
//
// The detail screen for one non-note game — Intervals, Chords, or Chord Lab —
// opened from the Stats hub. It wraps the charted [StatBreakdownView] in a
// scaffold with a back button, the game title, and a reset control.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/services/practice_stats_service.dart';
import 'package:fretboard/views/screens/heatmap/stats_breakdown_view.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:get/get.dart';

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
  List<DayStat> _history = const [];

  StatsModule get _statsModule => switch (widget.module) {
        1 => StatsModule.interval,
        2 => StatsModule.chord,
        _ => StatsModule.chordLab,
      };

  @override
  void initState() {
    super.initState();
    controller = Get.find<HeatmapController>();
    controller.loadBreakdowns();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await PracticeStatsService.loadHistory(_statsModule);
    if (mounted) setState(() => _history = h);
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

  void _confirmReset() async {
    final confirmed = await showJhgConfirm(
      context: context,
      title: 'Reset $_resetName stats?',
      message:
          'This permanently clears your $_resetName accuracy stats. Your other '
          'games and score history are unaffected.',
      confirmLabel: 'Reset',
      cancelLabel: 'Cancel',
      accent: context.jhg.danger,
    );
    if (confirmed && mounted) {
      controller.resetModule(widget.module);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    const webMaxWidth = 520.0;
    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ─── TOP BAR ──────────────────────────────────────────────
          JhgScreenHeader.detail(
            title: _title,
            onBack: () => Get.back(),
            actions: [
              _iconButton(
                // One glyph; `active` below carries the state.
                icon: JhgIcons.info,
                active: _showInfo,
                onTap: () => setState(() => _showInfo = !_showInfo),
              ),
              _iconButton(
                icon: JhgIcons.reset,
                onTap: _confirmReset,
              ),
            ],
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
                history: _history,
                showIntro: _showInfo,
              );
            }),
          ),

          // ─── NAV BAR ──────────────────────────────────────────────
          const AppNavBar(activeTab: AppTab.heatmap),
        ],
      ),
    );

    return JhgScaffold(
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
    final coral = context.jhg.accent;
    return JhgIconChipButton(
      icon: icon,
      onTap: onTap,
      iconColor: active ? coral : Colors.white54,
      background: active ? coral.withValues(alpha: 0.16) : null,
      borderColor: active ? coral.withValues(alpha: 0.5) : null,
    );
  }
}
