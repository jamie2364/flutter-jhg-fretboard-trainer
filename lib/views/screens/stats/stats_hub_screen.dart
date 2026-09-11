// views/screens/stats/stats_hub_screen.dart
//
// The Stats landing. Each game gets its own card — overall accuracy ring, a
// mini per-sub-mode bar strip, and a one-line summary — and its own detail
// screen when tapped. No cramped tab bar: the four games live side by side as
// separate, tappable cards.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart' show JhgIconChipButton, JhgScreenHeader, LucideIcons;
import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/services/practice_stats_service.dart';
import 'package:fretboard/views/screens/heatmap/heatmap_screen.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/stats/module_stats_screen.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:fretboard/utils/routes.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const _cStruggle = Color(0xFFE05252);
const _cLearning = Color(0xFFE8961A);
const _cGood = Color(0xFF4CB87A);
const _cMastered = Color(0xFF2ECC71);
const _cNoData = Color(0xFF3A3A3A);

Color _accColor(double acc) {
  if (acc >= 0.85) return _cMastered;
  if (acc >= 0.70) return _cGood;
  if (acc >= 0.50) return _cLearning;
  return _cStruggle;
}

/// One game's presentation in the hub.
class _GameSpec {
  const _GameSpec(this.module, this.title, this.subtitle, this.icon,
      this.accent, this.subModes);
  final int module;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  /// Fixed (key, short-label) pairs for the mini bar strip.
  final List<(String, String)> subModes;
}

const List<_GameSpec> _games = [
  _GameSpec(0, 'Notes', 'Find and name notes on the neck',
      Icons.music_note_rounded, Color(0xFF34C6A5), [
    ('find', 'Find'),
    ('identify', 'Identify'),
  ]),
  _GameSpec(1, 'Intervals', 'Name and build every interval',
      Icons.straighten_rounded, Color(0xFFFE5D43), [
    ('name', 'Name'),
    ('build', 'Build'),
  ]),
  _GameSpec(2, 'Chords', 'Name and build chord shapes',
      Icons.grid_goldenratio_rounded, Color(0xFF7C9CFF), [
    ('name', 'Name'),
    ('build', 'Build'),
  ]),
  _GameSpec(3, 'Chord Lab', 'Four drills, mixed each round',
      Icons.science_rounded, Color(0xFFE8961A), [
    ('name', 'Name'),
    ('complete', 'Fill'),
    ('remove', 'Odd'),
    ('build', 'Build'),
  ]),
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
      Get.to(() => const HeatmapScreen(),
          transition: Transition.noTransition, duration: Duration.zero);
    } else {
      Get.to(() => ModuleStatsScreen(module: module),
          transition: Transition.noTransition, duration: Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    const webMaxWidth = 520.0;
    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Screen title, top-left — same position and type as Settings and
          // every other nav-bar destination.
          const JhgScreenHeader(
            title: 'Stats',
            subtitle: 'Pick a game to see your strong and weak spots',
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: _LeaderboardTile(
              onTap: () => Get.to(() => const LeadershipScreen(),
                  routeName: kLeaderboardRoute,
                  transition: Transition.noTransition,
                  duration: Duration.zero),
            ),
          ),
          Expanded(
            child: Obx(() {
              // Touch the reactive breakdowns so the hub rebuilds after loads.
              controller.noteStats.value;
              controller.intervalStats.value;
              controller.chordStats.value;
              controller.labStats.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  for (final g in _games) ...[
                    _GameCard(
                      spec: g,
                      controller: controller,
                      onTap: () => _open(g.module),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              );
            }),
          ),
          const AppNavBar(activeTab: AppTab.heatmap),
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
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.spec,
    required this.controller,
    required this.onTap,
  });
  final _GameSpec spec;
  final HeatmapController controller;
  final VoidCallback onTap;

  ModuleBreakdown get _data => controller.breakdownFor(spec.module);

  StatEntry? _subEntry(String key) {
    // Notes/Intervals/Chords use mode:*, Chord Lab uses round:*.
    if (spec.module == 3) return _data.byRound[key];
    return _data.byMode[key];
  }

  @override
  Widget build(BuildContext context) {
    final attempts = controller.attemptsFor(spec.module);
    final acc = controller.accuracyFor(spec.module);
    final hasData = attempts > 0;
    final ringColor = hasData ? _accColor(acc) : _cNoData;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // card surface (Settings system)
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: spec.accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ring(acc, hasData, ringColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: spec.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                Icon(spec.icon, color: spec.accent, size: 15),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            spec.title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasData
                            ? '$attempts tries · ${_accWord(acc)}'
                            : spec.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white30, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            // Mini per-sub-mode bar strip.
            Row(
              children: [
                for (var i = 0; i < spec.subModes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _miniBar(spec.subModes[i])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double acc, bool hasData, Color color) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: hasData ? acc.clamp(0.02, 1.0) : 0,
              strokeWidth: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasData ? '${(acc * 100).round()}' : '–',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              if (hasData)
                Text('%',
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBar((String, String) sub) {
    final e = _subEntry(sub.$1);
    final has = e?.hasData ?? false;
    final acc = e?.accuracy ?? 0;
    final color = has ? _accColor(acc) : _cNoData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                sub.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              has ? '${(acc * 100).round()}%' : '–',
              style: GoogleFonts.inter(
                color: has ? color : Colors.white24,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LayoutBuilder(
            builder: (_, c) => Stack(
              children: [
                Container(
                    height: 6, color: Colors.white.withValues(alpha: 0.07)),
                Container(
                  height: 6,
                  width: has
                      ? (c.maxWidth * acc).clamp(4.0, c.maxWidth)
                      : 0,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _accWord(double acc) {
  if (acc >= 0.85) return 'Mastered';
  if (acc >= 0.70) return 'Solid';
  if (acc >= 0.50) return 'Learning';
  return 'Shaky';
}

/// A gold-accented banner tile that opens the Leaderboard, sitting above the
/// Practice Stats header (the board is no longer a nav-bar tab).
class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.onTap});
  final VoidCallback onTap;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gold.withValues(alpha: 0.18),
              _gold.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withValues(alpha: 0.42)),
        ),
        child: Row(
          children: [
            const JhgIconChipButton.badge(
              icon: LucideIcons.trophy,
              color: _gold,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leaderboard',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'See where you rank against everyone',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _gold.withValues(alpha: 0.85), size: 24),
          ],
        ),
      ),
    );
  }
}
