import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/utils/routes.dart';
import 'package:fretboard/views/screens/home/home_screen.dart';
import 'package:fretboard/views/screens/widgets/chord_lab_intro_dialog.dart';
import 'package:fretboard/views/screens/widgets/multi_select_dropdown.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBg = Color(0xFF0F0F0F);
const _kPrimary = Color(0xFFFE5D43);
const _kOnSurface = Color(0xFFE5E2E1);
const _kMuted = Color(0xFF9A9694);

// ── Shared wizard chrome (mirrors the dictionaries / drills setup wizard) ─────
// Header strip with a back/close icon + step progress dots, a "STEP N · …"
// eyebrow heading, and a helper that parks the focus control at the same
// vertical spot on every step.

/// Back/close icon (top-left) + step progress dots (top-right). Dots are hidden
/// for a single-step wizard.
Widget _wizardHeader({
  required int step,
  required int stepCount,
  required VoidCallback onBack,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(
      children: [
        GestureDetector(
          onTap: onBack,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(
              step == 0 ? Icons.close_rounded : Icons.chevron_left_rounded,
              color: _kOnSurface,
              size: 22,
            ),
          ),
        ),
        const Spacer(),
        if (stepCount > 1)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(stepCount, (i) {
              final active = i == step;
              final done = i < step;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(left: 6),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active || done
                      ? _kPrimary
                      : Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    ),
  );
}

/// Step eyebrow ("STEP 1 · GAME") + big title + one-line description.
Widget _wizardHeading(String eyebrow, String title, String subtitle) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: GoogleFonts.inter(
          color: _kPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        title,
        style: GoogleFonts.poppins(
          color: _kOnSurface,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        subtitle,
        style: GoogleFonts.inter(color: _kMuted, fontSize: 14, height: 1.5),
      ),
    ],
  );
}

/// Parks [focus] at the same vertical spot on every step: the heading is
/// bottom-aligned in the upper region so it rests just above the focus control.
Widget _focusCentredStep({
  required Widget heading,
  required Widget focus,
  List<Widget> below = const [],
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: heading,
            ),
          ),
        ),
        focus,
        ...below,
        const Spacer(flex: 4),
      ],
    ),
  );
}

/// Full-width coral CTA used to finish a multi-select step (which can't
/// auto-advance the way a single card tap does).
Widget _wizardPrimaryButton(String label, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// Six string chips (low E → high e) that toggle which strings a practice
/// session uses. Mirrors the Settings string toggles and shares the same
/// controller state. At least one string always stays on.
class _StringsSelector extends StatelessWidget {
  const _StringsSelector({required this.controller});
  final HomeController controller;

  // (string number, chip label). 6 = low E … 1 = high e.
  static const List<(int, String)> _strings = [
    (6, 'E'),
    (5, 'A'),
    (4, 'D'),
    (3, 'G'),
    (2, 'B'),
    (1, 'e'),
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (c) => Row(
        children: [
          for (var i = 0; i < _strings.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _chip(c, _strings[i].$1, _strings[i].$2)),
          ],
        ],
      ),
    );
  }

  Widget _chip(HomeController c, int n, String label) {
    final on = c.isStringOn(n);
    return GestureDetector(
      onTap: () => c.setStringActive(n, !on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 60,
        decoration: BoxDecoration(
          color: on ? _kPrimary.withValues(alpha: 0.16) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: on
                ? _kPrimary.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: on ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: on ? _kPrimary : Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox cards for the Chord Lab round types. Multi-select, keeps at least
/// one selected. Purely local state (owned by the caller).
class _RoundTypesSelector extends StatelessWidget {
  const _RoundTypesSelector({required this.selected, required this.onChanged});
  final Set<ChordLabRound> selected;
  final ValueChanged<Set<ChordLabRound>> onChanged;

  static const List<(ChordLabRound, String, String)> _rows = [
    (ChordLabRound.name, 'Name it', 'A shape lights up. Pick its name.'),
    (ChordLabRound.complete, 'Complete it',
        'Tap the notes that finish the chord.'),
    (ChordLabRound.remove, 'Remove the extra',
        "Tap the note that doesn't belong."),
    (ChordLabRound.build, 'Build it here',
        'Build the chord in a set region of the neck.'),
  ];

  void _toggle(ChordLabRound r) {
    final next = {...selected};
    if (next.contains(r)) {
      if (next.length == 1) return; // keep at least one
      next.remove(r);
    } else {
      next.add(r);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _card(_rows[i].$1, _rows[i].$2, _rows[i].$3),
        ],
      ],
    );
  }

  Widget _card(ChordLabRound r, String label, String subtitle) {
    final on = selected.contains(r);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on
                ? _kPrimary.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: on ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: on ? _kPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: on ? _kPrimary : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: on
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: on ? _kPrimary : _kOnSurface,
                      fontSize: 17,
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
          ],
        ),
      ),
    );
  }
}

/// A wrap of key chips (A … G#) for the Chord Lab keys step. Multi-select,
/// keeps at least one selected. Purely local state (owned by the caller).
class _KeysSelector extends StatelessWidget {
  const _KeysSelector({required this.selected, required this.onChanged});
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  void _toggle(String key) {
    final next = {...selected};
    if (next.contains(key)) {
      if (next.length == 1) return; // keep at least one
      next.remove(key);
    } else {
      next.add(key);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final key in kChromaticRoots)
          GestureDetector(
            onTap: () => _toggle(key),
            child: () {
              final on = selected.contains(key);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 54,
                height: 48,
                decoration: BoxDecoration(
                  color: on
                      ? _kPrimary.withValues(alpha: 0.16)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: on
                        ? _kPrimary.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: on ? 1.5 : 1.0,
                  ),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: GoogleFonts.poppins(
                      color: on ? _kPrimary : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }(),
          ),
      ],
    );
  }
}

/// App landing / Home. Two ways in: a one-tap **Random Practice** path (pick a
/// mode, everything else is randomized) and the full **Customized Practice**
/// wizard (mode → game type → difficulty). This is the first screen and the
/// Home-tab destination across the app.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Touch the controller on the landing screen so its onInit warms the chord
    // library in the background while the user is still choosing — by the time
    // they reach Chord mode it's already parsed (no first-play stall).
    Get.find<HomeController>();
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
                  'How would you like to practice?',
                  style: GoogleFonts.inter(
                    color: _kMuted,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                _ModeCard(
                  label: 'Random Practice',
                  subtitle:
                      'Just pick a mode. We choose the rest and start you off.',
                  onTap: () => Get.to(() => const RandomModeScreen()),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  label: 'Customized Practice',
                  subtitle:
                      'Choose the mode, game and difficulty yourself.',
                  onTap: () => Get.to(() => const ModeSelectScreen()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Random-practice mode picker: the user only chooses Notes / Intervals /
/// Chords. The game type (Name/Build, Find/Identify) and difficulty are rolled
/// randomly and the board opens immediately.
class RandomModeScreen extends StatelessWidget {
  const RandomModeScreen({super.key});

  static final Random _rng = Random();

  void _launch() => Get.off(() => const HomeScreen(), routeName: kBoardRoute);

  void _randomNotes() {
    final hc = Get.find<HomeController>();
    hc.resetStrings(); // Random Practice uses the whole neck.
    _rng.nextBool() ? hc.switchToIdentifyMode() : hc.switchToFindMode();
    _launch();
  }

  void _randomInterval() {
    final hc = Get.find<HomeController>();
    // Random Practice is "everything" — clear any interval / string filter left
    // over from a previous customized session.
    hc.resetIntervalFilter();
    hc.resetStrings();
    hc.switchToIntervalMode(
      type: IntervalGameType
          .values[_rng.nextInt(IntervalGameType.values.length)],
      difficulty: IntervalDifficulty
          .values[_rng.nextInt(IntervalDifficulty.values.length)],
    );
    _launch();
  }

  void _randomChord() {
    // Chord Lab is excluded from Random Practice — only Name / Build here.
    const randomTypes = [ChordGameType.name, ChordGameType.build];
    Get.find<HomeController>().switchToChordMode(
      type: randomTypes[_rng.nextInt(randomTypes.length)],
      difficulty: ChordDifficulty
          .values[_rng.nextInt(ChordDifficulty.values.length)],
    );
    _launch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                onPressed: Get.back,
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
                        'Random Practice',
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
                        'Pick a mode and we pick the rest.',
                        style: GoogleFonts.inter(
                          color: _kMuted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ModeCard(
                        label: 'Notes',
                        subtitle:
                            'Learn where every note sits on the fretboard.',
                        onTap: _randomNotes,
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        label: 'Intervals',
                        subtitle:
                            'Practise the gap between two notes.',
                        onTap: _randomInterval,
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        label: 'Chords',
                        subtitle:
                            'Spot and build common guitar chords.',
                        onTap: _randomChord,
                      ),
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
  // Find Note + Identify are two halves of the same skill (note ⇄ position), so
  // they live behind one "Notes" card with a type step, matching the Intervals
  // and Chords wizards.
  void _selectNotes() {
    Get.to(() => NoteSetupScreen(fromSwitcher: widget.fromSwitcher));
  }

  void _selectInterval() {
    Get.to(() => IntervalSetupScreen(fromSwitcher: widget.fromSwitcher));
  }

  void _selectChord() {
    Get.to(() => ChordSetupScreen(fromSwitcher: widget.fromSwitcher));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                onPressed: Get.back,
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
                        'Customized Practice',
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
                        'Which mode would you like to practice?',
                        style: GoogleFonts.inter(
                          color: _kMuted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ModeCard(
                        label: 'Notes',
                        subtitle:
                            'Learn where every note sits on the fretboard.',
                        onTap: _selectNotes,
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        label: 'Intervals',
                        subtitle:
                            'Practise the gap between two notes.',
                        onTap: _selectInterval,
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        label: 'Chords',
                        subtitle:
                            'Spot and build common guitar chords.',
                        onTap: _selectChord,
                      ),
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
  // Local steps: 0 = game, 1 = intervals, 2 = strings, 3 = difficulty.
  // Mode was picked on the previous screen and counts as the wizard's Step 1,
  // so the dots/eyebrows are offset by one (a leading "done" dot for Mode).
  int _step = 0;
  IntervalGameType _type = IntervalGameType.name;
  IntervalDifficulty _difficulty = IntervalDifficulty.medium;

  // Which intervals to practise — every interval selected by default so a user
  // can breeze through. Stored as semitone strings for the dropdown. Unison
  // (0) is omitted: every difficulty requires an ascending gap, so a unison
  // question can never be generated.
  late Set<String> _intervals = {
    for (final iv in _intervalOptions) iv.semitones.toString()
  };

  static final List<MusicInterval> _intervalOptions =
      kIntervals.where((iv) => iv.semitones != 0).toList();

  // Mode + game + intervals + strings + difficulty.
  static const int _totalSteps = 5;

  void _pickType(IntervalGameType type) => setState(() {
        _type = type;
        _step = 1;
      });

  void _pickDifficulty(IntervalDifficulty difficulty) {
    // Difficulty is the last step — selecting a level launches straight away.
    _difficulty = difficulty;
    _launch();
  }

  void _launch() {
    Get.find<HomeController>().switchToIntervalMode(
      type: _type,
      difficulty: _difficulty,
      intervals: _intervals.map(int.parse).toSet(),
    );
    if (widget.fromSwitcher) {
      Get.close(2);
    } else {
      Get.off(() => const HomeScreen(), routeName: kBoardRoute);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // +1 so the first dot (Mode, already chosen) shows as done.
            _wizardHeader(
                step: _step + 1, stepCount: _totalSteps, onBack: _back),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _stepChild(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepChild() {
    switch (_step) {
      case 0:
        return _typeStep();
      case 1:
        return _intervalsStep();
      case 2:
        return _stringsStep();
      default:
        return _difficultyStep();
    }
  }

  Widget _typeStep() => _focusCentredStep(
        heading: _wizardHeading(
            'STEP 2 · GAME', 'Intervals', 'Which interval game?'),
        focus: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeCard(
              label: 'Name the Interval',
              subtitle: 'Two notes light up. Pick the gap between them.',
              onTap: () => _pickType(IntervalGameType.name),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              label: 'Build the Interval',
              subtitle: 'You get a note and a gap. Tap the right fret.',
              onTap: () => _pickType(IntervalGameType.build),
            ),
          ],
        ),
      );

  Widget _intervalsStep() => _focusCentredStep(
        heading: _wizardHeading(
            'STEP 3 · INTERVALS', 'Intervals', 'Which ones to practise?'),
        focus: MultiSelectDropdown(
          options: [
            for (final iv in _intervalOptions)
              MultiSelectOption(iv.semitones.toString(), iv.name,
                  subtitle: iv.short),
          ],
          selected: _intervals,
          onChanged: (s) => setState(() => _intervals = s),
          allLabel: 'All intervals',
          noun: 'intervals',
          searchHint: 'Search intervals…',
        ),
        below: [
          const SizedBox(height: 20),
          _wizardPrimaryButton('Continue', () => setState(() => _step = 2)),
        ],
      );

  Widget _stringsStep() => _focusCentredStep(
        heading: _wizardHeading(
            'STEP 4 · STRINGS', 'Strings', 'Which strings to use?'),
        focus: _StringsSelector(controller: Get.find<HomeController>()),
        below: [
          const SizedBox(height: 20),
          _wizardPrimaryButton('Continue', () => setState(() => _step = 3)),
        ],
      );

  Widget _difficultyStep() => _focusCentredStep(
        heading: _wizardHeading(
            'STEP 5 · DIFFICULTY', 'Difficulty', 'How challenging should it be?'),
        focus: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeCard(
              label: 'Easy',
              subtitle: 'Both notes on the same string, moving up.',
              onTap: () => _pickDifficulty(IntervalDifficulty.easy),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              label: 'Medium',
              subtitle: 'Same or a nearby string, moving up.',
              onTap: () => _pickDifficulty(IntervalDifficulty.medium),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              label: 'Hard',
              subtitle: 'Anywhere on the neck, either direction.',
              onTap: () => _pickDifficulty(IntervalDifficulty.hard),
            ),
          ],
        ),
      );
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
  int _step = 0;
  ChordGameType _type = ChordGameType.name;

  // Chord Lab selections — all keys, tonalities and round types by default.
  Set<String> _keys = {...kChromaticRoots};
  Set<String> _tonalities = {...kChordLabTonalities};
  Set<ChordLabRound> _rounds = {...ChordLabRound.values};

  bool get _isLab => _type == ChordGameType.lab;

  // Name/Build: [game, difficulty]. Chord Lab: [game, keys, tonalities, rounds,
  // difficulty]. Mode was picked on the previous screen (the wizard's Step 1),
  // so dots/eyebrows are offset by one.
  List<String> get _steps => _isLab
      ? const ['game', 'keys', 'tonalities', 'rounds', 'difficulty']
      : const ['game', 'difficulty'];
  String get _stepId => _steps[_step];
  int get _totalDots => _steps.length + 1; // + Mode

  void _pickType(ChordGameType type) {
    setState(() {
      _type = type;
      _step = 1;
    });
    // Chord Lab is the deepest, most feature-rich chord mode — brief the player
    // on what it does the moment they step into it (once the keys step has
    // rendered behind the modal). Shows every time until they opt out.
    if (type == ChordGameType.lab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ChordLabIntroDialog.maybeShow(context);
      });
    }
  }

  void _launch() {
    final hc = Get.find<HomeController>();
    if (_isLab) {
      hc.switchToChordLab(
        keys: _keys,
        tonalities: _tonalities,
        rounds: _rounds,
        difficulty: _difficulty,
      );
    } else {
      hc.switchToChordMode(type: _type, difficulty: _difficulty);
    }
    if (widget.fromSwitcher) {
      Get.close(2);
    } else {
      Get.off(() => const HomeScreen(), routeName: kBoardRoute);
    }
  }

  ChordDifficulty _difficulty = ChordDifficulty.easy;

  void _pickDifficulty(ChordDifficulty difficulty) {
    _difficulty = difficulty;
    _launch();
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // +1 so the first dot (Mode, chosen on the previous screen) is done.
            _wizardHeader(step: _step + 1, stepCount: _totalDots, onBack: _back),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: KeyedSubtree(
                  key: ValueKey('${_type.name}-$_step'),
                  child: _stepChild(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Eyebrow number = local step + 2 (Mode is Step 1).
  String _eyebrow(String tail) => 'STEP ${_step + 2} · $tail';

  Widget _stepChild() {
    switch (_stepId) {
      case 'keys':
        return _keysStep();
      case 'tonalities':
        return _tonalitiesStep();
      case 'rounds':
        return _roundsStep();
      case 'difficulty':
        return _difficultyStep();
      default:
        return _typeStep();
    }
  }

  Widget _typeStep() => _focusCentredStep(
        heading: _wizardHeading(_eyebrow('GAME'), 'Chords', 'Which chord game?'),
        focus: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeCard(
              label: 'Name the Chord',
              subtitle: 'A chord shape lights up. Pick its name.',
              onTap: () => _pickType(ChordGameType.name),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              label: 'Build the Chord',
              subtitle: 'You get a chord name. Tap the frets to shape it.',
              onTap: () => _pickType(ChordGameType.build),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              label: 'Chord Lab',
              subtitle: 'Pick your chords and drill them every way.',
              onTap: () => _pickType(ChordGameType.lab),
            ),
          ],
        ),
      );

  Widget _keysStep() => _focusCentredStep(
        heading: _wizardHeading(_eyebrow('KEYS'), 'Keys', 'Which roots to drill?'),
        focus: _KeysSelector(
          selected: _keys,
          onChanged: (s) => setState(() => _keys = s),
        ),
        below: [
          const SizedBox(height: 24),
          _wizardPrimaryButton('Continue', () => setState(() => _step++)),
        ],
      );

  Widget _tonalitiesStep() => _focusCentredStep(
        heading: _wizardHeading(
            _eyebrow('TONALITIES'), 'Tonalities', 'Which chord types?'),
        focus: MultiSelectDropdown(
          options: [
            for (final t in kChordLabTonalities)
              MultiSelectOption(t, kChordLabTonalityLabels[t] ?? t),
          ],
          selected: _tonalities,
          onChanged: (s) => setState(() => _tonalities = s),
          allLabel: 'All tonalities',
          noun: 'tonalities',
          searchHint: 'Search tonalities…',
        ),
        below: [
          const SizedBox(height: 20),
          _wizardPrimaryButton('Continue', () => setState(() => _step++)),
        ],
      );

  // Four cards is tall, so this step scrolls (heading + cards) with the CTA
  // pinned at the bottom — no overflow on short screens.
  Widget _roundsStep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _wizardHeading(_eyebrow('ROUNDS'), 'Round types',
                        'How do you want to be tested?'),
                    const SizedBox(height: 20),
                    _RoundTypesSelector(
                      selected: _rounds,
                      onChanged: (s) => setState(() => _rounds = s),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _wizardPrimaryButton('Continue', () => setState(() => _step++)),
            const SizedBox(height: 16),
          ],
        ),
      );

  Widget _difficultyStep() {
    // Chord Lab difficulty controls neck position only (tonalities are already
    // chosen); Name/Build difficulty also widens the vocabulary.
    final (easy, medium, hard) = _isLab
        ? (
            'Open and low positions (up to fret 4).',
            'Up the neck to fret 9.',
            'Anywhere up to fret 15.',
          )
        : (
            'Open major and minor chords, low on the neck.',
            'Adds 7ths, sixths, sus and add9 shapes.',
            'Every chord type, all over the neck.',
          );
    return _focusCentredStep(
      heading: _wizardHeading(
          _eyebrow('DIFFICULTY'), 'Difficulty', 'How challenging should it be?'),
      focus: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeCard(
            label: 'Easy',
            subtitle: easy,
            onTap: () => _pickDifficulty(ChordDifficulty.easy),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            label: 'Medium',
            subtitle: medium,
            onTap: () => _pickDifficulty(ChordDifficulty.medium),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            label: 'Hard',
            subtitle: hard,
            onTap: () => _pickDifficulty(ChordDifficulty.hard),
          ),
        ],
      ),
    );
  }
}

/// Two-step note-game wizard: choose Find or Identify, pick the strings to
/// practise, then drop into the board.
class NoteSetupScreen extends StatefulWidget {
  const NoteSetupScreen({super.key, this.fromSwitcher = false});
  final bool fromSwitcher;

  @override
  State<NoteSetupScreen> createState() => _NoteSetupScreenState();
}

class _NoteSetupScreenState extends State<NoteSetupScreen> {
  int _step = 0; // 0 = game, 1 = strings
  bool _identify = false;

  void _pickGame(bool identify) => setState(() {
        _identify = identify;
        _step = 1;
      });

  void _launch() {
    final hc = Get.find<HomeController>();
    _identify ? hc.switchToIdentifyMode() : hc.switchToFindMode();
    if (widget.fromSwitcher) {
      Get.close(2);
    } else {
      Get.off(() => const HomeScreen(), routeName: kBoardRoute);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // +1 so the first dot (Mode, chosen on the previous screen) is done.
            _wizardHeader(step: _step + 1, stepCount: 3, onBack: _back),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 0 ? _gameStep() : _stringsStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameStep() => _focusCentredStep(
        heading: _wizardHeading('STEP 2 · GAME', 'Notes', 'Which note game?'),
        focus: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeCard(
              label: 'Find the Note',
              subtitle: 'See a note name and tap where it is on the neck.',
              onTap: () => _pickGame(false),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              label: 'Identify the Note',
              subtitle: 'A fret lights up. Say which note it is.',
              onTap: () => _pickGame(true),
            ),
          ],
        ),
      );

  Widget _stringsStep() => _focusCentredStep(
        heading: _wizardHeading(
            'STEP 3 · STRINGS', 'Strings', 'Which strings to use?'),
        focus: _StringsSelector(controller: Get.find<HomeController>()),
        below: [
          const SizedBox(height: 20),
          _wizardPrimaryButton('Start practice', _launch),
        ],
      );
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
