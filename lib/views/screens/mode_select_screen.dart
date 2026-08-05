import 'package:flutter/material.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:fretboard/utils/chords.dart';
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
  // Picking a mode selects it and moves straight on — no separate CTA.
  void _select(bool identify) {
    final hc = Get.find<HomeController>();
    if (identify) {
      hc.switchToIdentifyMode();
    } else {
      hc.switchToFindMode();
    }
    _go();
  }

  void _selectInterval() {
    Get.to(() => IntervalSetupScreen(fromSwitcher: widget.fromSwitcher));
  }

  void _selectChord() {
    Get.to(() => ChordSetupScreen(fromSwitcher: widget.fromSwitcher));
  }

  void _go() {
    if (widget.fromSwitcher) {
      Get.back();
    } else {
      Get.off(() => const HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
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
                  onTap: () => _select(false),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  label: 'Identify',
                  subtitle: 'Name the note at the highlighted fret.',
                  onTap: () => _select(true),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  label: 'Intervals',
                  subtitle:
                      'Two notes light up — name the interval between them.',
                  onTap: _selectInterval,
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  label: 'Chords',
                  subtitle:
                      'Name a chord from its shape, or build the shape yourself.',
                  onTap: _selectChord,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-step interval setup wizard: pick the game type, then the difficulty,
/// then drop into the training board. Single route (matches the app's wizard
/// pattern) so there's no deep navigation stack to unwind.
class IntervalSetupScreen extends StatefulWidget {
  const IntervalSetupScreen({super.key, this.fromSwitcher = false});
  final bool fromSwitcher;

  @override
  State<IntervalSetupScreen> createState() => _IntervalSetupScreenState();
}

class _IntervalSetupScreenState extends State<IntervalSetupScreen> {
  int _step = 0; // 0 = type, 1 = difficulty
  IntervalGameType _type = IntervalGameType.name;

  void _pickType(IntervalGameType type) {
    setState(() {
      _type = type;
      _step = 1;
    });
  }

  void _pickDifficulty(IntervalDifficulty difficulty) {
    Get.find<HomeController>()
        .switchToIntervalMode(type: _type, difficulty: difficulty);
    if (widget.fromSwitcher) {
      // Pop the setup screen and the mode-select screen back to the game.
      Get.close(2);
    } else {
      Get.off(() => const HomeScreen());
    }
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isType = _step == 0;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top-left back icon (no Next — selecting a card auto-advances).
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, color: _kOnSurface),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isType ? 'Intervals' : 'Difficulty',
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
                        isType
                            ? 'Which interval game?'
                            : 'How challenging should it be?',
                        style: GoogleFonts.inter(
                          color: _kMuted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (isType) ...[
                        _ModeCard(
                          label: 'Name the Interval',
                          subtitle:
                              'Two notes light up — name the interval between them.',
                          onTap: () => _pickType(IntervalGameType.name),
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          label: 'Build the Interval',
                          subtitle:
                              'A root + an interval name — tap the fret that far away.',
                          onTap: () => _pickType(IntervalGameType.build),
                        ),
                      ] else ...[
                        _ModeCard(
                          label: 'Easy',
                          subtitle: 'Both notes on the same string, going up.',
                          onTap: () => _pickDifficulty(IntervalDifficulty.easy),
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          label: 'Medium',
                          subtitle: 'Same or a neighbouring string, going up.',
                          onTap: () =>
                              _pickDifficulty(IntervalDifficulty.medium),
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          label: 'Hard',
                          subtitle: 'Anywhere on the neck, either direction.',
                          onTap: () => _pickDifficulty(IntervalDifficulty.hard),
                        ),
                      ],
                    ],
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

/// Two-step chord setup wizard: pick the game type, then the difficulty, then
/// drop into the training board. Mirrors IntervalSetupScreen exactly.
class ChordSetupScreen extends StatefulWidget {
  const ChordSetupScreen({super.key, this.fromSwitcher = false});
  final bool fromSwitcher;

  @override
  State<ChordSetupScreen> createState() => _ChordSetupScreenState();
}

class _ChordSetupScreenState extends State<ChordSetupScreen> {
  int _step = 0; // 0 = type, 1 = difficulty
  ChordGameType _type = ChordGameType.name;

  void _pickType(ChordGameType type) {
    setState(() {
      _type = type;
      _step = 1;
    });
  }

  void _pickDifficulty(ChordDifficulty difficulty) {
    Get.find<HomeController>()
        .switchToChordMode(type: _type, difficulty: difficulty);
    if (widget.fromSwitcher) {
      // Pop the setup screen and the mode-select screen back to the game.
      Get.close(2);
    } else {
      Get.off(() => const HomeScreen());
    }
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isType = _step == 0;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_rounded, color: _kOnSurface),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isType ? 'Chords' : 'Difficulty',
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
                        isType
                            ? 'Which chord game?'
                            : 'How challenging should it be?',
                        style: GoogleFonts.inter(
                          color: _kMuted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (isType) ...[
                        _ModeCard(
                          label: 'Name the Chord',
                          subtitle:
                              'A chord lights up on the neck — pick its name.',
                          onTap: () => _pickType(ChordGameType.name),
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          label: 'Build the Chord',
                          subtitle:
                              'A chord name is shown — tap the frets to place it.',
                          onTap: () => _pickType(ChordGameType.build),
                        ),
                      ] else ...[
                        _ModeCard(
                          label: 'Easy',
                          subtitle:
                              'Open major & minor chords, low on the neck.',
                          onTap: () => _pickDifficulty(ChordDifficulty.easy),
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          label: 'Medium',
                          subtitle:
                              'Adds 7ths, sixths, sus, add9, dim & aug shapes.',
                          onTap: () => _pickDifficulty(ChordDifficulty.medium),
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          label: 'Hard',
                          subtitle:
                              'The full vocabulary, anywhere up the neck.',
                          onTap: () => _pickDifficulty(ChordDifficulty.hard),
                        ),
                      ],
                    ],
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

class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _flash = false;

  Future<void> _handleTap() async {
    if (_flash) return;
    setState(() => _flash = true);
    await Future.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _flash = false);
  }

  @override
  Widget build(BuildContext context) {
    final flash = _flash;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: flash ? null : const Color(0xFF1A1A1A),
          gradient: flash
              ? LinearGradient(
                  colors: [
                    _kPrimary.withValues(alpha: 0.18),
                    _kPrimary.withValues(alpha: 0.06),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: flash
                ? _kPrimary.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: flash ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      color: flash ? _kPrimary : _kOnSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
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
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: flash
                    ? _kPrimary.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: flash ? _kPrimary : Colors.white54,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
