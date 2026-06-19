import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fretboard/controllers/heatmap_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/app_colors.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  late HeatmapController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HeatmapController>();
    controller.loadStats();
  }

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
    final width = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: JHGColors.secondryBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── TOP BAR ──────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70, size: 18),
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
                  GestureDetector(
                    onTap: _confirmReset,
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restart_alt_rounded,
                          color: Colors.white54, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ─── STATS STRIP ──────────────────────────────────────────────
            Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      _statChip(
                        value: controller.totalPracticed.toString(),
                        label: 'Practiced',
                        color: Colors.white38,
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

            // ─── FRETBOARD ────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white24,
                      strokeWidth: 1.5,
                    ),
                  );
                }
                return _HeatmapFretboard(
                  controller: controller,
                  height: height,
                  width: width,
                );
              }),
            ),

            // ─── DETAIL PANEL ─────────────────────────────────────────────
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

            // ─── LEGEND + BOTTOM ──────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 14, 20, bottomInset > 0 ? bottomInset : 20),
              child: Column(
                children: [
                  Text(
                    'TAP ANY FRET TO SEE DETAILS',
                    style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _legendDot(const Color(0xFFE05252), 'Struggling'),
                      _legendDot(const Color(0xFFE8961A), 'Learning'),
                      _legendDot(const Color(0xFF4CB87A), 'Good'),
                      _legendDot(const Color(0xFF2ECC71), 'Mastered'),
                      _legendDot(const Color(0x40FFFFFF), 'No data'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    const boardWidthFactor = 0.50;
    final boardWidth = width * boardWidthFactor;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 45.8),
      child: Column(
        children: [
          // String name chips
          Center(
            child: Container(
              padding: EdgeInsets.only(right: width * 0.11),
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
                constraints: BoxConstraints(maxHeight: height * 1.2),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Cream board
                    Column(
                      children: [
                        SizedBox(height: height * 0.015),
                        Expanded(
                          child: Container(
                            width: width * 0.8,
                            color: AppColors.creamColor,
                          ),
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
                          height: height * 0.015,
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
                        padding: EdgeInsets.only(bottom: height * 0.002),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 11),
                          height: height * 0.077,
                          child: Row(
                            children: [
                              Expanded(child: _inlayDot(height, i == 11)),
                              const Expanded(child: SizedBox.shrink()),
                              Expanded(
                                  child: _inlayDot(
                                      height,
                                      i == 2 ||
                                          i == 4 ||
                                          i == 6 ||
                                          i == 8 ||
                                          i == 14)),
                              const Expanded(child: SizedBox.shrink()),
                              Expanded(child: _inlayDot(height, i == 11)),
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
                        padding: EdgeInsets.only(top: height * 0.076),
                        child: Container(
                          height: height * 0.0038,
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
                          height: height,
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
                        bottom: _fretNumPadding(i, height)),
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
    required this.controller,
  });

  final int index;
  final double height;
  final HeatmapController controller;

  double _topPadding() {
    if (index >= 0 && index <= 5) return height * 0.006;
    return height * 0.038;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final color = controller.getHeatColor(index);
      final stat = controller.stats[index];
      final hasData = stat != null && stat.hasData;
      final note = fretList[index].note ?? '';
      final isSelected = controller.selectedIndex.value == index;
      final circleSize = height * 0.033;

      return GestureDetector(
        onTap: () => controller.selectFret(index),
        child: Padding(
          padding: EdgeInsets.only(bottom: _topPadding()),
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
                  fontSize: note.length > 1 ? height * 0.0085 : height * 0.010,
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
            const leftInset = 12.0;
            const rightInset = 12.0;
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
