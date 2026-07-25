import 'package:flutter/material.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/views/screens/home/home_screen.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0F0F0F);
const _kPrimary = Color(0xFFFE5D43);
const _kOnSurface = Color(0xFFE5E2E1);
const _kMuted = Color(0xFF9A9694);

/// Startup / mode-select screen. Mirrors the dictionaries Start screen:
/// a title + subtitle over two selectable cards, with a coral CTA below.
class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key, this.fromSwitcher = false});

  /// True when opened from the in-app top-bar switcher (pop back on select);
  /// false at startup (replace with the home screen).
  final bool fromSwitcher;

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  // Find Note is the default selection.
  bool _identify = false;

  @override
  void initState() {
    super.initState();
    // Preselect the current mode when reopened from the switcher.
    if (Get.isRegistered<HomeController>()) {
      _identify =
          Get.find<HomeController>().currentGameMode.value == 'reverse';
    }
  }

  void _start() {
    final hc = Get.find<HomeController>();
    if (_identify) {
      hc.switchToIdentifyMode();
    } else {
      hc.switchToFindMode();
    }
    if (widget.fromSwitcher) {
      Get.back();
    } else {
      Get.off(() => const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fretboard Trainer',
                      style: GoogleFonts.poppins(
                        color: _kOnSurface,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How would you like to start?',
                      style: GoogleFonts.inter(
                        color: _kMuted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _ModeCard(
                      label: 'Find Note',
                      subtitle:
                          'Find the shown note on the fretboard against the clock.',
                      selected: !_identify,
                      onTap: () => setState(() => _identify = false),
                      onInfo: () => _showGuide(context, identify: false),
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      label: 'Identify',
                      subtitle: 'Name the note at the highlighted fret.',
                      selected: _identify,
                      onTap: () => setState(() => _identify = true),
                      onInfo: () => _showGuide(context, identify: true),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 20),
              child: GestureDetector(
                onTap: _start,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _identify ? 'Identify' : 'Find Note',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showGuide(BuildContext context, {required bool identify}) {
  final heading = identify ? 'Identify' : 'Find Note';
  final steps = identify
      ? const [
          'A position lights up on the fretboard.',
          'Pick the correct note name.',
          'Sharpen your fretboard recall.',
        ]
      : const [
          'A note name is shown.',
          'Tap that note on the fretboard.',
          'Beat the clock and climb the leaderboard.',
        ];
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: const Color(0xFF1C1C1B),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOW ${heading.toUpperCase()} WORKS',
              style: GoogleFonts.inter(
                color: _kPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              heading,
              style: GoogleFonts.poppins(
                color: _kOnSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _kPrimary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.poppins(
                          color: _kPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: GoogleFonts.inter(
                          color: _kOnSurface,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    color: _kOnSurface,
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
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.onInfo,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    _kPrimary.withValues(alpha: 0.18),
                    _kPrimary.withValues(alpha: 0.06),
                  ],
                )
              : null,
          color: selected ? null : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _kPrimary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: selected ? _kPrimary : _kOnSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: _kMuted.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onInfo,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? _kPrimary.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: selected ? _kPrimary : Colors.white54,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
