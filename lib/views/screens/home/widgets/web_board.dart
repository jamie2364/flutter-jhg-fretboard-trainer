import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart'
    show StringsNameWidget;
import 'package:fretboard/views/screens/home/widgets/web_guitar_board.dart';
import 'package:fretboard/views/screens/leader_board/leaderboard_screen.dart';
import 'package:fretboard/views/screens/setting/settings_screen.dart';
import 'package:fretboard/views/widgets/count_timer_widget.dart';
import 'package:get/get.dart';

class WebBoard extends StatelessWidget {
  const WebBoard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final surfaceWidth = (size.width * 0.32).clamp(430.0, 560.0).toDouble();
    final boardWidth = (size.width * 0.145).clamp(224.0, 252.0).toDouble();
    const dockHeight = 112.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 28, 0, dockHeight + 18),
            child: Column(
              children: [
                ConstrainedBox(
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
                            if (controller.currentGameMode.value !=
                                'leaderboard') {
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardHeight = (constraints.maxHeight - 178)
                          .clamp(420.0, 540.0)
                          .toDouble();
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: surfaceWidth),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WebModePill(controller: controller),
                              const SizedBox(height: 14),
                              IgnorePointer(
                                ignoring: !controller.isStart,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StringsNameWidget(
                                      width: boardWidth,
                                      isPortrait: true,
                                    ),
                                    const SizedBox(height: 4),
                                    WebPortraitGuitarBoard(
                                      boardWidth: boardWidth,
                                      boardHeight: boardHeight,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const CountTimerWidget(),
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
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: surfaceWidth),
            child: SizedBox(
              height: dockHeight,
              child: _WebBottomDock(controller: controller),
            ),
          ),
        ),
      ],
    );
  }
}

class _WebModePill extends StatelessWidget {
  const _WebModePill({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.currentGameMode.value;
      final isLocked = controller.isStart || controller.isPaused;

      return GestureDetector(
        onTap: isLocked ? null : controller.cycleGameMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLocked
                  ? Colors.transparent
                  : JHGColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _modeIcon(mode),
                color: isLocked ? Colors.white38 : JHGColors.primary,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                _modeLabel(mode),
                style: JHGTextStyles.btnLabelStyle.copyWith(
                  color: isLocked ? Colors.white38 : Colors.white,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _WebBottomDock extends StatelessWidget {
  const _WebBottomDock({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF424242),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
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
            Expanded(
              child: Center(
                child: _PrimaryPlayButton(controller: controller),
              ),
            ),
            _DockCircleButton(
              icon: Icons.refresh_rounded,
              onTap: () => controller.resetGame(true),
            ),
          ],
        ),
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
        height: 70,
        width: 70,
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
          size: controller.isStart ? 32 : 42,
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

String _modeLabel(String mode) {
  switch (mode) {
    case 'countdown':
      return 'COUNTDOWN';
    case 'leaderboard':
      return 'LEADERBOARD';
    case 'stopwatch':
    default:
      return 'STOPWATCH';
  }
}
