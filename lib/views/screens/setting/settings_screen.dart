import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/features/tour/fretboard_tour.dart';
import 'package:fretboard/features/tour/tour_service.dart';
import 'package:fretboard/services/audio_pack_service.dart';
import 'package:fretboard/main.dart';
import 'package:fretboard/services/saved_sessions_service.dart';
import 'package:fretboard/utils/app_strings.dart';
import 'package:fretboard/utils/routes.dart';
import 'package:fretboard/views/screens/saved/saved_sessions_screen.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:get/get.dart';
import 'package:reg_page/reg_page.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late HomeController homeController;
  bool _stringsExpanded = false;

  @override
  void initState() {
    super.initState();
    homeController = Get.find<HomeController>()..onDefaultTimerInitialized();
    // Populate SavedSessionsService.count so the Saved Sessions row can label
    // itself before the user taps it.
    SavedSessionsService.refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    const navBar = AppNavBar(activeTab: AppTab.settings);
    final support = SettingsControler(
      appName: AppStrings.appName,
      iosAppIdentifier: AppStrings.iOSBuildId,
      androidAppIdentifier: AppStrings.androidBuildId,
      appShareText:
          'Use Fretboard Trainer App to unlock your musical potential.\nDownload it here:\n',
      appStoreId: AppStrings.appStoreId,
      viewMoreAppsUrl: 'https://www.jamieharrisonguitar.com/apps',
    );

    return JhgScaffold(
      bottomNavigationBar: navBar,
      body: GetBuilder<HomeController>(
        builder: (controller) {
          return SettingsScreenLayout(
            sections: [
              SettingsScreenSection(
                label: 'SESSIONS',
                child: SettingsCard(
                  child: ValueListenableBuilder<int>(
                    valueListenable: SavedSessionsService.count,
                    builder: (_, count, __) => SettingsActionTile(
                      icon: JhgIcons.save,
                      title: 'Saved Sessions',
                      subtitle: count == 0
                          ? 'Nothing in here yet. Hit Save while you practise.'
                          : count == 1
                              ? 'One session waiting for you'
                              : '$count sessions waiting for you',
                      onTap: () {
                        SavedSessionsService.refreshCount();
                        // Both screens carry the nav bar — a sliding
                        // push would drag the bar across.
                        Get.off(
                          () => const SavedSessionsScreen(),
                          routeName: kSavedRoute,
                          transition: Transition.rightToLeft,
                          duration: const Duration(milliseconds: 260),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SettingsScreenSection(
                label: 'IDENTIFY MODE',
                child: SettingsCard(
                  child: Column(
                    children: [
                      SettingsSwitchTile(
                        icon: LucideIcons.mapPin,
                        title: 'Show position hint',
                        subtitle:
                            'Display string & fret below the answer buttons',
                        value: controller.identifyShowPositionHint,
                        onChanged: (_) {
                          controller.identifyShowPositionHint =
                              !controller.identifyShowPositionHint;
                          controller.update();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        icon: JhgIcons.next,
                        title: 'Auto-advance',
                        subtitle:
                            'Move to next note automatically after a correct answer',
                        value: controller.identifyAutoAdvance,
                        onChanged: (_) {
                          controller.identifyAutoAdvance =
                              !controller.identifyAutoAdvance;
                          controller.update();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        icon: JhgIcons.volume,
                        title: 'Auto-play sound',
                        subtitle:
                            'Sound every note and chord as it comes up. Off by default, so use the Listen button when you want to hear one.',
                        value: controller.identifyPlaySound,
                        onChanged: (_) {
                          controller.identifyPlaySound =
                              !controller.identifyPlaySound;
                          controller.update();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SettingsScreenSection(
                label: 'STRINGS',
                expanded: _stringsExpanded,
                onToggle: () =>
                    setState(() => _stringsExpanded = !_stringsExpanded),
                child: SettingsCard(
                  child: Column(
                    children: [
                      SettingsSwitchTile(
                        title: AppStrings.string6,
                        subtitle: 'Low E string',
                        icon: JhgIcons.note,
                        value: controller.string6,
                        onChanged: (_) {
                          controller.setString6(0);
                          controller.saveStrings();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        title: AppStrings.string5,
                        subtitle: 'A string',
                        icon: JhgIcons.note,
                        value: controller.string5,
                        onChanged: (_) {
                          controller.setString5(1);
                          controller.saveStrings();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        title: AppStrings.string4,
                        subtitle: 'D string',
                        icon: JhgIcons.note,
                        value: controller.string4,
                        onChanged: (_) {
                          controller.setString4(2);
                          controller.saveStrings();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        title: AppStrings.string3,
                        subtitle: 'G string',
                        icon: JhgIcons.note,
                        value: controller.string3,
                        onChanged: (_) {
                          controller.setString3(3);
                          controller.saveStrings();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        title: AppStrings.string2,
                        subtitle: 'B string',
                        icon: JhgIcons.note,
                        value: controller.string2,
                        onChanged: (_) {
                          controller.setString2(4);
                          controller.saveStrings();
                        },
                      ),
                      const SettingsDivider(),
                      SettingsSwitchTile(
                        title: AppStrings.string1,
                        subtitle: 'High e string',
                        icon: JhgIcons.note,
                        value: controller.string1,
                        onChanged: (_) {
                          controller.setString1(5);
                          controller.saveStrings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SettingsScreenSection(
                label: 'TIMER',
                child: SettingsCard(
                  child: Column(
                    children: [
                      SettingsDropdownTile(
                        icon: JhgIcons.duration,
                        title: 'Default Timer',
                        options: controller.defaultTimer,
                        selected: controller.defaultTimerSelectedValue.value,
                        dropdownWidth: 150,
                        onSelect: (value) {
                          controller.selectedDropDownValue.value = value;
                          controller.defaultTimerSelectedValue.value = value;
                          controller.saveTimerSettings();
                          controller.update();
                        },
                      ),
                      if (controller.defaultTimerSelectedValue.value ==
                          controller.defaultTimer[1]) ...[
                        const SettingsDivider(),
                        SettingsValueTile(
                          icon: JhgIcons.duration,
                          title: 'Interval Time',
                          value: _formatDuration(
                              controller.timerIntervalValue.value),
                          onTap: () async {
                            final seconds = await showSettingsDurationPicker(
                              context: context,
                              initialSeconds:
                                  controller.timerIntervalValue.value,
                              title: 'Interval Time',
                              description: 'Set the countdown duration.',
                            );
                            if (seconds != null) {
                              final clamped = seconds == 0 ? 1 : seconds;
                              controller.timerIntervalValue.value = clamped;
                              controller.minutesValue.value = clamped ~/ 60;
                              controller.saveTimerSettings();
                              controller.update();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!kIsWeb)
                const SettingsScreenSection(
                  label: 'AUDIO LIBRARY',
                  child: _AudioLibraryTile(),
                ),
              if (!kIsWeb)
                SettingsScreenSection(
                  label: 'SUPPORT',
                  child: SettingsSupportCard(
                    controller: support,
                    showRemoveAds: isFreePlan,
                  ),
                ),
              const SettingsScreenSection(
                label: 'HELP',
                child: SettingsReplayTourCard(onTap: _replayTour),
              ),
              if (!kIsWeb)
                SettingsScreenSection(
                  label: 'ACCOUNT',
                  child: SettingsLogoutCard(
                    onTap: () async {
                      await LocalDB.clearLocalDB();
                      Nav.offAll(const WelcomeScreen());
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

void _replayTour() async {
  await TourService.resetTour();
  final tour = fretboardTourOrNull;
  if (tour == null) return;
  // All the way back to Home, not one route back. The tour opens on Home's
  // Quick start card, and Settings can be reached from the board — popping once
  // would land on the board with the tour waiting on a screen buried under it.
  Get.until((r) => r.isFirst);
  await Future.delayed(const Duration(milliseconds: 350));
  TourService.scheduleHeatmapIntro();
  tour.start();
}

/// Native settings row for the downloaded note-sample pack: shows whether the
/// library is installed and lets the user re-verify + re-download missing
/// sounds. Same anatomy as the other settings rows; the whole row is the action.
class _AudioLibraryTile extends StatefulWidget {
  const _AudioLibraryTile();

  @override
  State<_AudioLibraryTile> createState() => _AudioLibraryTileState();
}

class _AudioLibraryTileState extends State<_AudioLibraryTile> {
  AudioLibraryStatus? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await AudioPackService.getLibraryStatus();
    if (mounted) setState(() => _status = s);
  }

  Future<void> _repair() async {
    setState(() => _busy = true);
    try {
      await AudioPackService.ensureAudioPack(force: true, context: context);
    } finally {
      if (mounted) {
        await _load();
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.jhg;
    final s = _status;

    final String statusLine;
    if (_busy) {
      statusLine = 'Downloading missing sounds…';
    } else if (s == null) {
      statusLine = 'Checking your library…';
    } else if (s.isComplete) {
      statusLine = 'All note sounds installed · tap to re-check';
    } else {
      statusLine = 'Some sounds missing · tap to repair';
    }

    final Widget trailing;
    if (_busy) {
      trailing = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(t.accent),
        ),
      );
    } else if (s != null && s.isComplete) {
      trailing = Icon(LucideIcons.checkCircle2,
          size: 20, color: t.accent.withValues(alpha: 0.9));
    } else {
      trailing = Icon(LucideIcons.refreshCw, size: 19, color: t.accent);
    }

    return SettingsCard(
      child: InkWell(
        onTap: _busy ? null : _repair,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const SettingsIconChip(icon: LucideIcons.library),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Note Sounds', style: t.typography.tileTitle),
                    const SizedBox(height: 3),
                    Text(
                      statusLine,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
