import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/views/screens/home/widgets/web_guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:fretboard/views/widgets/count_timer_widget.dart';
import 'package:get/get.dart';

class WebBoard extends StatelessWidget {
  const WebBoard({super.key, required this.controller});

  final HomeController controller;
  static const double _surfaceWidth = 470.0;
  static const double _dockHeight = 98.0;
  static const double _timerBandHeight = 54.0;
  static const double _webFretboardWidth = 191.0;
  static const double _webFretNumberGutter = 31.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final surfaceWidth =
        (size.width * 0.30).clamp(_surfaceWidth, 520.0).toDouble();
    const boardWidth = _webFretboardWidth;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              32,
              0,
              _dockHeight + _timerBandHeight + 8,
            ),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardHeight = (constraints.maxHeight - 42)
                          .clamp(260.0, 640.0)
                          .toDouble();
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: surfaceWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              SizedBox(
                                width: boardWidth + _webFretNumberGutter,
                                child: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: _WebStringLabels(width: boardWidth),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: !controller.isStart,
                                child: WebPortraitGuitarBoard(
                                  boardWidth: boardWidth,
                                  boardHeight: boardHeight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 38,
          left: 0,
          right: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: surfaceWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TopIconButton(
                    icon: LucideIcons.trophy300,
                    onTap: () {
                      Get.to(
                        () => LeadershipScreen(),
                        transition: Transition.leftToRight,
                      );
                    },
                  ),
                  Obx(
                    () => _TopIconButton(
                      icon: LucideIcons.settings300,
                      disabled:
                          controller.currentGameMode.value == 'leaderboard',
                      onTap: () {
                        if (controller.currentGameMode.value != 'leaderboard') {
                          controller.resetGame(false);
                          Get.to(
                            () => SettingScreen(),
                            transition: Transition.rightToLeft,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: _dockHeight + 8,
          child: Center(
            child: SizedBox(
              height: _timerBandHeight,
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: CountTimerWidget(),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: surfaceWidth),
            child: SizedBox(
              height: _dockHeight,
              child: _WebBottomDock(controller: controller),
            ),
          ),
        ),
      ],
    );
  }
}

class _WebStringLabels extends StatelessWidget {
  const _WebStringLabels({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    const chipSize = 22.0;
    final centers = WebPortraitGuitarBoard.stringCenters(width);

    return SizedBox(
      width: width,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(AppStrings.guitarStrings.length, (index) {
          return Positioned(
            left: centers[index] - chipSize / 2,
            top: 7,
            child: Container(
              height: chipSize,
              width: chipSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.24),
                shape: BoxShape.circle,
                border: Border.all(
                  color: JHGColors.primary.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -0.4),
                  child: Text(
                    AppStrings.guitarStrings[index],
                    textAlign: TextAlign.center,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WebBottomDock extends StatelessWidget {
  const _WebBottomDock({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: _PrimaryPlayButton(controller: controller),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => _DockCircleButton(
                      icon: _modeIcon(controller.currentGameMode.value),
                      disabled: controller.isStart || controller.isPaused,
                      onTap: controller.isStart || controller.isPaused
                          ? null
                          : controller.cycleGameMode,
                    ),
                  ),
                  if (controller.isStart) ...[
                    const SizedBox(width: 14),
                    _TargetNoteChip(note: controller.highlightNode ?? '')
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.isStart) ...[
                    _ScoreChip(score: controller.score),
                    const SizedBox(width: 14),
                  ],
                  _DockCircleButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => controller.resetGame(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetNoteChip extends StatelessWidget {
  const _TargetNoteChip({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      constraints: const BoxConstraints(minWidth: 62),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: JHGColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: JHGColors.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        note,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: JHGTextStyles.lrlabelStyle.copyWith(
          color: JHGColors.primary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SCORE',
            style: JHGTextStyles.btnLabelStyle.copyWith(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1.0,
              height: 1,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            score.toString(),
            style: JHGTextStyles.labelStyle.copyWith(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryPlayButton extends StatelessWidget {
  const _PrimaryPlayButton({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: controller.isStart
          ? controller.pauseGame
          : controller.isPaused
              ? controller.resumeGame
              : () {
                  controller.startTimer();
                  controller.startTheGame();
                },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: JHGColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: JHGColors.primary.withValues(alpha: 0.24),
              blurRadius: 20,
            ),
          ],
        ),
        child: Icon(
          controller.isStart ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: controller.isStart ? 30 : 40,
        ),
      ),
    );
  }
}

class _DockCircleButton extends StatelessWidget {
  const _DockCircleButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: disabled ? 0.04 : 0.07),
            ),
          ),
          child: Icon(
            icon,
            color: disabled ? Colors.white24 : Colors.white70,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Icon(
            icon,
            color: disabled ? Colors.white24 : Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }
}

IconData _modeIcon(String mode) {
  switch (mode) {
    case 'countdown':
      return LucideIcons.clock300;
    case 'leaderboard':
      return LucideIcons.trophy300;
    case 'stopwatch':
    default:
      return LucideIcons.timer300;
  }
}
