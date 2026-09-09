import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrimary = Color(0xFFFE5D43);
const _kCard = Color(0xFF141414);
const _kOnSurface = Color(0xFFF1F1F1);
const _kMuted = Color(0xFF8A8A8A);

/// A single "what you'll be doing" row inside the Chord Lab briefing.
class _LabFacet {
  const _LabFacet(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const List<_LabFacet> _kFacets = [
  _LabFacet(Icons.abc_rounded, 'Name it',
      'A shape lights up. Name the chord it spells.'),
  _LabFacet(Icons.auto_fix_high_rounded, 'Complete it',
      'A chord is half built. Add the notes that finish it.'),
  _LabFacet(Icons.filter_center_focus_rounded, 'Remove the extra',
      "One note doesn't belong. Find it and take it out."),
  _LabFacet(Icons.grid_goldenratio_rounded, 'Build it here',
      'You get a name and a spot on the neck. Build it from there.'),
];

/// A frosted briefing that introduces Chord Lab the first time — and every time
/// after, until the player asks not to see it again. Rendered as a blurred
/// modal with a single **Continue** action (no dismiss control) plus a
/// "Don't show this again" opt-out that persists across sessions.
class ChordLabIntroDialog extends StatefulWidget {
  const ChordLabIntroDialog({super.key});

  static const _prefsKey = 'fretboard_chord_lab_intro_dismissed';

  /// Shows the briefing unless the player has previously opted out. Awaits the
  /// player's **Continue** tap; returns immediately if suppressed. Safe to call
  /// as the Chord Lab flow opens.
  static Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) ?? false) return;
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Chord Lab',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => const ChordLabIntroDialog(),
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: Transform.scale(
            scale: 0.94 + 0.06 * curved.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ChordLabIntroDialog> createState() => _ChordLabIntroDialogState();
}

class _ChordLabIntroDialogState extends State<ChordLabIntroDialog> {
  bool _dontShowAgain = false;

  Future<void> _continue() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ChordLabIntroDialog._prefsKey, true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // showGeneralDialog doesn't insert a Material ancestor, so without this the
    // Text widgets render with Flutter's debug yellow underline. A transparent
    // Material fixes it while keeping the frosted look.
    return Material(
      type: MaterialType.transparency,
      child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: _kCard.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _eyebrow(),
                      const SizedBox(height: 16),
                      Text(
                        'Chord Lab',
                        style: GoogleFonts.poppins(
                          color: _kOnSurface,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pick the chords you want to work on and the Lab '
                        'drills them four ways, mixing up the rounds so it '
                        'never gets stale. Great for locking shapes into '
                        'muscle memory.',
                        style: GoogleFonts.inter(
                          color: _kMuted,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (var i = 0; i < _kFacets.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _facetRow(_kFacets[i]),
                      ],
                      const SizedBox(height: 22),
                      _dontShowRow(),
                      const SizedBox(height: 18),
                      _continueButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _eyebrow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.science_rounded, color: _kPrimary, size: 14),
              const SizedBox(width: 7),
              Text(
                'ADVANCED PRACTICE',
                style: GoogleFonts.inter(
                  color: _kPrimary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _facetRow(_LabFacet f) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.22)),
          ),
          child: Icon(f.icon, color: _kPrimary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                f.title,
                style: GoogleFonts.poppins(
                  color: _kOnSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                f.body,
                style: GoogleFonts.inter(
                  color: _kMuted.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dontShowRow() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _dontShowAgain ? _kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _dontShowAgain
                    ? _kPrimary
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: _dontShowAgain
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                : null,
          ),
          const SizedBox(width: 11),
          Text(
            'Don’t show this again',
            style: GoogleFonts.inter(
              color: _kMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButton() {
    return GestureDetector(
      onTap: _continue,
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
          'Continue',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
