import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/features/tour/tour_service.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  late HeatmapController controller;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HeatmapController>();
    controller.loadStats();
    _checkTourIntro();
  }

  Future<void> _checkTourIntro() async {
    final pending = await TourService.shouldShowHeatmapIntro();
    if (pending && mounted) {
      await TourService.markHeatmapIntroSeen();
      setState(() => _showIntro = true);
    }
  }

  void _dismissIntro() => setState(() => _showIntro = false);

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset mastery data?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently clear all your accuracy stats. Your score history is unaffected.',
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 13,
          ),
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
              controller.clearStats();
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
    final height = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    const webMaxWidth = 568.0;
    final width = kIsWeb ? webMaxWidth : screenWidth;
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
                      GestureDetector(
                        onTap: _confirmReset,
                        child: Container(
                          height: 44, width: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.restart_alt_rounded,
                              color: Colors.white54, size: 20),
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'MASTERY MAP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ),
                      // Legend pill
                      GestureDetector(
                        onTap: () => _showLegendSheet(context),
                        child: Container(
                          height: 44, width: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Colors.white54, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── STATS STRIP ──────────────────────────────────────────
                Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      _statChip(
                        value: controller.totalPracticed.toString(),
                        label: 'Practiced',
                        color: Colors.white54,
                        bgColor: const Color(0xFF2C2C2C),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        value: controller.mastered.toString(),
                        label: 'Mastered',
                        color: const Color(0xFF2ECC71),
                        bgColor: const Color(0x1A2ECC71),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        value: controller.struggling.toString(),
                        label: 'Struggling',
                        color: const Color(0xFFE05252),
                        bgColor: const Color(0x1AE05252),
                      ),
                    ],
                  ),
                )),

                // ─── FRETBOARD ────────────────────────────────────────────
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white24, strokeWidth: 1.5),
                      );
                    }
                    return _HeatmapFretboard(
                        controller: controller, height: height, width: width);
                  }),
                ),

                // ─── DETAIL PANEL ─────────────────────────────────────────
                Obx(() {
                  final idx = controller.selectedIndex.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: idx >= 0 ? 96 : 0,
                    child: ClipRect(
                      child: OverflowBox(
                        minHeight: 0,
                        maxHeight: double.infinity,
                        alignment: Alignment.topCenter,
                        child: idx >= 0
                            ? _DetailPanel(index: idx, controller: controller)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }),

                // ─── HINT + LEGEND ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap any fret to see details',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _inlineLegend(),
                    ],
                  ),
                ),

                // ─── NAV BAR ──────────────────────────────────────────────
                AppNavBar(
                  activeTab: AppTab.heatmap,
                  safeBottom: bottomInset,
                ),
              ],
            ),
          );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: JHGColors.secondryBlack,
          body: kIsWeb
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: webMaxWidth),
                    child: content,
                  ),
                )
              : content,
        ),
        if (_showIntro) _HeatmapIntroOverlay(onDismiss: _dismissIntro),
      ],
    );
  }

  void _showLegendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      // Keep it a tidy card instead of a full-width slab on web.
      constraints: const BoxConstraints(maxWidth: 440),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 10, 20, MediaQuery.of(ctx).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Color Guide', style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...{
              const Color(0xFFE05252): ('Struggling', 'Under 50% correct'),
              const Color(0xFFE8961A): ('Learning', '50–74% correct'),
              const Color(0xFF4CB87A): ('Good', '75–89% correct'),
              const Color(0xFF2ECC71): ('Mastered', '90%+ correct'),
              const Color(0x66FFFFFF): ('No data', 'Not practiced yet'),
            }.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              // Label + description on ONE line so each row is half as tall.
              child: Row(
                children: [
                  Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(color: e.key, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(e.value.$1, style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(e.value.$2, style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 11)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _inlineLegend() {
    const items = [
      (Color(0xFFE05252), 'S'),
      (Color(0xFFE8961A), 'L'),
      (Color(0xFF4CB87A), 'G'),
      (Color(0xFF2ECC71), 'M'),
      (Color(0x66FFFFFF), '–'),
    ];
    return Row(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: item.$1, shape: BoxShape.circle),
        ),
      )).toList(),
    );
  }

  Widget _statChip({
    required String value,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ─── DETAIL PANEL ─────────────────────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel(
      {required this.index, required this.controller});

  final int index;
  final HeatmapController controller;

  @override
  Widget build(BuildContext context) {
    final fret = fretList[index];
    final stat = controller.stats[index];
    final hasData = stat != null && stat.hasData;
    final acc = hasData ? stat!.accuracy : 0.0;
    final color = controller.getHeatColor(index);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Center(
              child: Text(
                fret.note ?? '',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'String ${fret.string}  •  Fret ${fret.fret}',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (!hasData)
                  Text(
                    'Not practiced yet',
                    style: GoogleFonts.inter(
                        color: Colors.white24, fontSize: 11),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: acc,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(acc * 100).round()}%',
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (hasData)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stat!.correct}/${stat.attempts}',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'correct',
                  style: GoogleFonts.inter(
                      color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── HEATMAP FRETBOARD ────────────────────────────────────────────────────────

class _HeatmapFretboard extends StatelessWidget {
  const _HeatmapFretboard({
    required this.controller,
    required this.height,
    required this.width,
  });

  final HeatmapController controller;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    // On web the canvas is a fixed 568px, so the old 0.50 factor gave a fat
    // 284px slab. Slim it to ~193px to match the Find Note screen's neck.
    // Mobile keeps 0.50 (real screen width already yields a good ~195px neck).
    final boardWidthFactor = kIsWeb ? 0.34 : 0.50;
    final boardWidth = width * boardWidthFactor;

    // Vertical basis. On web, lock the fret pitch to the SAME neck proportion
    // as the Find Note board (fret 80 : string 33.5 ≈ 2.39), so both boards look
    // identical regardless of window height. boardWidth*5.17 makes
    // vh*0.077 (one fret) equal (boardWidth/6)*2.39 (2.39 string-columns tall).
    // Mobile keeps the real screen height, pixel-identical to before.
    final vh = kIsWeb ? boardWidth * 5.17 : height;

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 45.8),
        child: Column(
        children: [
          // String name chips.
          // Right padding must equal the board Row's right-side gutter
          // (SizedBox 20 + fret-number column width*0.06) so the centred chip
          // block lines up exactly over the board columns below it.
          Center(
            child: Container(
              padding: EdgeInsets.only(right: 20 + width * 0.06),
              child: _StringNameRow(width: boardWidth),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fretboard
              Container(
                width: boardWidth,
                height: vh * 1.212,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Cream board — nut + exactly 15 fret rows
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: vh * 0.015),
                        Container(
                          width: width * 0.8,
                          height: vh * 1.197,
                          color: AppColors.creamColor,
                        ),
                      ],
                    ),
                    // Nut
                    Align(
                      alignment: Alignment.topCenter,
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: Container(
                          width: double.infinity,
                          height: vh * 0.015,
                          decoration: BoxDecoration(
                            color: JHGColors.black,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Inlay dots
                    ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 15,
                      itemBuilder: (_, i) => Padding(
                        padding: EdgeInsets.only(bottom: vh * 0.002),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 11),
                          height: vh * 0.077,
                          child: Row(
                            children: [
                              Expanded(child: _inlayDot(vh, i == 11)),
                              const Expanded(child: SizedBox.shrink()),
                              Expanded(
                                  child: _inlayDot(
                                      vh,
                                      i == 2 ||
                                          i == 4 ||
                                          i == 6 ||
                                          i == 8 ||
                                          i == 14)),
                              const Expanded(child: SizedBox.shrink()),
                              Expanded(child: _inlayDot(vh, i == 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Row dividers (frets)
                    ListView.builder(
                      itemCount: 15,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, pos) => Padding(
                        padding: EdgeInsets.only(top: vh * 0.076),
                        child: Container(
                          height: vh * 0.0038,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.whiteLight,
                                AppColors.whiteLight,
                                JHGColors.charcolGray,
                                JHGColors.secondryBlack,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Column dividers (strings)
                    RotatedBox(
                      quarterTurns: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 12 : 0,
                              right: i == 5 ? 12 : 0,
                            ),
                            child: Container(
                              width: i == 5
                                  ? width * 0.010
                                  : i == 4
                                      ? width * 0.009
                                      : i == 3
                                          ? width * 0.008
                                          : i == 2
                                              ? width * 0.007
                                              : i == 1
                                                  ? width * 0.006
                                                  : width * 0.006,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.whiteLight,
                                    AppColors.whiteLight,
                                    JHGColors.charcolGray,
                                    JHGColors.secondryBlack,
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Heatmap circles
                    // Top padding = nut height so fret-0 circles
                    // appear below the nut instead of behind it.
                    Align(
                      alignment: Alignment.topCenter,
                      child: AlignedGridView.count(
                        itemCount: 96,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 6,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 7,
                        itemBuilder: (_, i) =>
                            _HeatmapCell(
                          index: i,
                          height: vh,
                          // Width of a single string column, minus the 5 gaps
                          // (crossAxisSpacing 7) between the 6 columns. Circles
                          // scale to this so they fit any board width.
                          cellWidth: (boardWidth - 7 * 5) / 6,
                          controller: controller,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Fret numbers
              SizedBox(
                width: width * 0.06,
                child: ListView.builder(
                  itemCount: 16,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(
                        bottom: _fretNumPadding(i, vh)),
                    child: Text(
                      i.toString(),
                      style: JHGTextStyles.lrlabelStyle.copyWith(
                          fontSize: 14, height: 1.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _inlayDot(double height, bool show) => Center(
        child: Container(
          width: height * 0.024,
          height: height * 0.024,
          decoration: BoxDecoration(
            color: show ? JHGColors.secondryBlack : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      );

  double _fretNumPadding(int index, double height) {
    switch (index) {
      case 0:
        return height * 0.015;
      case 1:
        return height * 0.055;
      case 2:
        return height * 0.065;
      case 3:
        return height * 0.065;
      case 4:
        return height * 0.056;
      case 5:
      case 6:
      case 7:
        return height * 0.062;
      default:
        return height * 0.061;
    }
  }
}

// ─── HEATMAP CELL ─────────────────────────────────────────────────────────────

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.index,
    required this.height,
    required this.cellWidth,
    required this.controller,
  });

  final int index;
  final double height;
  final double cellWidth;
  final HeatmapController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final color = controller.getHeatColor(index);
      final stat = controller.stats[index];
      final hasData = stat != null && stat.hasData;
      final note = fretList[index].note ?? '';
      final isSelected = controller.selectedIndex.value == index;
      // On web the neck is slimmer, so size the circle to the string column
      // (capped at the original height-based size) to avoid overflow/collision.
      // Mobile keeps the original height-based size, pixel-identical to before.
      final circleSize = kIsWeb
          ? (cellWidth * 0.92).clamp(0.0, height * 0.033).toDouble()
          : height * 0.033;

      return GestureDetector(
        onTap: () => controller.selectFret(index),
        child: Padding(
          // Keep each cell's total height at the fret-row pitch (height*0.077)
          // so circles stay centered in their fret regardless of circleSize.
          padding: EdgeInsets.symmetric(
              vertical: (height * 0.077 - circleSize) / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: hasData
                  ? color.withValues(alpha: isSelected ? 1.0 : 0.82)
                  : Colors.black.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : hasData
                        ? color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.18),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Center(
              child: Text(
                note,
                style: TextStyle(
                  color: hasData
                      ? Colors.white.withValues(alpha: isSelected ? 1.0 : 0.88)
                      : Colors.black.withValues(alpha: 0.4),
                  // Web: fill the smaller circle so labels stay legible.
                  // Mobile: keep the original height-based sizes, unchanged.
                  fontSize: kIsWeb
                      ? (note.length > 1 ? circleSize * 0.44 : circleSize * 0.56)
                      : (note.length > 1 ? height * 0.0085 : height * 0.010),
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── STRING NAME ROW ──────────────────────────────────────────────────────────

class _StringNameRow extends StatelessWidget {
  const _StringNameRow({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const chipSize = 28.0;
            // Match the circle grid's outer-column centres: each of the 6
            // columns is (width - 5*7)/6 wide, so the first/last centre sits
            // half a column in from the board edge. Keeps chips over strings.
            final inset = (constraints.maxWidth - 7 * 5) / 12;
            final leftInset = inset;
            final rightInset = inset;
            final span = constraints.maxWidth - leftInset - rightInset;
            return SizedBox(
              height: chipSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(AppStrings.guitarStrings.length, (i) {
                  final cx = leftInset +
                      (span / (AppStrings.guitarStrings.length - 1)) * i;
                  return Positioned(
                    left: cx - chipSize / 2,
                    top: 0,
                    child: Container(
                      height: chipSize,
                      width: chipSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: JHGColors.charcolGray,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: JHGColors.primary.withValues(alpha: 0.75),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        AppStrings.guitarStrings[i],
                        style: JHGTextStyles.labelStyle.copyWith(
                          color: JHGColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Heatmap tour intro overlay ────────────────────────────────────────────────

class _HeatmapIntroOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const _HeatmapIntroOverlay({required this.onDismiss});

  @override
  State<_HeatmapIntroOverlay> createState() => _HeatmapIntroOverlayState();
}

class _HeatmapIntroOverlayState extends State<_HeatmapIntroOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _dismiss() {
    _fade.reverse().whenComplete(widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final cardW = (size.width - 56.0).clamp(0.0, 400.0);
    final left = (size.width - cardW) / 2;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Dark backdrop
              const IgnorePointer(
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: Color(0xCC000000)),
                  child: SizedBox.expand(),
                ),
              ),
              // Card
              Positioned(
                left: left,
                top: size.height / 2 - 160,
                width: cardW,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                  decoration: BoxDecoration(
                    color: const Color(0xE8111111),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: JHGColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.insights_rounded,
                            color: JHGColors.primary, size: 28),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Your Mastery Map',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Each cell shows one note position. '
                        'Darker red = more attempts needed. '
                        'Green = mastered.\n\n'
                        'Practise the red spots to build a complete mastery of the neck.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _dismiss,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          decoration: BoxDecoration(
                            color: JHGColors.primary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: JHGColors.primary
                                    .withValues(alpha: 0.40),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: const Text(
                            'Got it!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
