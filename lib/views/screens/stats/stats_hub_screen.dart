// views/screens/stats/stats_hub_screen.dart
//
// The Stats landing. Each game gets its own card — overall accuracy ring, a
// mini per-sub-mode bar strip, and a one-line summary — and its own detail
// screen when tapped. The card / banner / shell design all live in
// jhg_elements (`JhgStats*`) so this screen matches Guitar Coach and Ear
// Training exactly; Fretboard keeps its own multi-dimensional data
// (HeatmapController / ModuleBreakdown) and its Notes → heatmap routing.

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/stats/module_stats_screen.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:fretboard/utils/routes.dart';
import 'package:get/get.dart';

const Color _gold = Color(0xFFD4AF37);

/// One game's presentation: the shared card spec plus the fixed (key, label)
/// sub-modes that drive its mini bar strip and which breakdown dimension to
/// read.
class _Game {
  const _Game(this.module, this.spec, this.subModes);
  final int module;
  final JhgStatModeSpec spec;
  final List<(String, String)> subModes;
}

const List<_Game> _games = [
  _Game(
    0,
    JhgStatModeSpec(
      id: 'Notes',
      title: 'Notes',
      subtitle: 'Find and name notes on the neck',
      icon: JhgIcons.note,
      accent: Color(0xFF34C6A5),
      placeholders: ['Find', 'Identify'],
    ),
    [('find', 'Find'), ('identify', 'Identify')],
  ),
  _Game(
    1,
    JhgStatModeSpec(
      id: 'Intervals',
      title: 'Intervals',
      subtitle: 'Name and build every interval',
      icon: Icons.straighten_rounded,
      accent: Color(0xFFFE5D43),
      placeholders: ['Name', 'Build'],
    ),
    [('name', 'Name'), ('build', 'Build')],
  ),
  _Game(
    2,
    JhgStatModeSpec(
      id: 'Chords',
      title: 'Chords',
      subtitle: 'Name and build chord shapes',
      icon: Icons.grid_goldenratio_rounded,
      accent: Color(0xFF7C9CFF),
      placeholders: ['Name', 'Build'],
    ),
    [('name', 'Name'), ('build', 'Build')],
  ),
  _Game(
    3,
    JhgStatModeSpec(
      id: 'Chord Lab',
      title: 'Chord Lab',
      subtitle: 'Four drills, mixed each round',
      icon: Icons.science_rounded,
      accent: Color(0xFFE8961A),
      placeholders: ['Name', 'Fill', 'Odd', 'Build'],
    ),
    [
      ('name', 'Name'),
      ('complete', 'Fill'),
      ('remove', 'Odd'),
      ('build', 'Build'),
    ],
  ),
];

class StatsHubScreen extends StatefulWidget {
  const StatsHubScreen({super.key});

  @override
  State<StatsHubScreen> createState() => _StatsHubScreenState();
}

class _StatsHubScreenState extends State<StatsHubScreen> {
  late final HeatmapController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HeatmapController>();
    controller.loadBreakdowns();
  }

  void _open(int module) {
    if (module == 0) {
      Get.to(
        () => const HeatmapScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 260),
      );
    } else {
      Get.to(
        () => ModuleStatsScreen(module: module),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 260),
      );
    }
  }

  JhgStatMiniDatum _sub(_Game g, (String, String) sub) {
    // Notes/Intervals/Chords read mode:*, Chord Lab reads round:*.
    final data = controller.breakdownFor(g.module);
    final e = g.module == 3 ? data.byRound[sub.$1] : data.byMode[sub.$1];
    return JhgStatMiniDatum(
      sub.$2,
      e == null
          ? null
          : JhgStatEntry.autoGraded(attempts: e.attempts, correct: e.correct),
    );
  }

  JhgStatHubCard _card(_Game g) {
    final attempts = controller.attemptsFor(g.module);
    final acc = controller.accuracyFor(g.module);
    final hasData = attempts > 0;
    return JhgStatHubCard(
      spec: g.spec,
      accuracy: acc,
      graded: hasData,
      hasData: hasData,
      attempts: attempts,
      summary: '$attempts tries · ${jhgAccWord(acc)}',
      strip: [for (final sub in g.subModes) _sub(g, sub)],
      onTap: () => _open(g.module),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Touch the reactive breakdowns so the hub rebuilds after loads.
      controller.noteStats.value;
      controller.intervalStats.value;
      controller.chordStats.value;
      controller.labStats.value;
      return JhgStatsHubScreen(
        title: 'Stats',
        subtitle: 'Pick a game to see your strong and weak spots',
        bottomNavigationBar: const AppNavBar(activeTab: AppTab.heatmap),
        topTile: JhgStatsBannerTile(
          title: 'Leaderboard',
          subtitle: 'See where you rank against everyone',
          badgeIcon: JhgIcons.trophy,
          accent: _gold,
          badgeColor: _gold,
          onTap: () => Get.to(
            () => const LeadershipScreen(),
            routeName: kLeaderboardRoute,
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 260),
          ),
        ),
        cards: [for (final g in _games) _card(g)],
      );
    });
  }
}
