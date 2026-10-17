import 'dart:async' show unawaited;
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:fretboard/controllers/home_controller.dart';
import 'package:fretboard/models/freth_list.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/features/tour/fretboard_tour.dart';
import 'package:fretboard/views/screens/home/widgets/guitar_board.dart';
import 'package:fretboard/views/widgets/app_nav_bar.dart';
import 'package:fretboard/views/screens/saved/save_session_dialog.dart';
import 'package:fretboard/views/widgets/show_toast.dart';
import 'package:get/get.dart';

import '../../../widgets/count_timer_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PortraitBoard
// Timer is always visible at the top.
// The fretboard fills all remaining space.
// The control panel floats OVER the fretboard as a blurred card (dict style).
// ─────────────────────────────────────────────────────────────────────────────

class PortraitBoard extends StatefulWidget {
  const PortraitBoard({super.key, required this.controller});
  final HomeController controller;

  @override
  State<PortraitBoard> createState() => _PortraitBoardState();
}

class _PortraitBoardState extends State<PortraitBoard> {
  bool _panelCollapsed = false;
  bool _prevGameRunning = false;
  Worker? _panelWorker;

  @override
  void initState() {
    super.initState();
    _panelWorker = ever(widget.controller.isBottomPanelExpanded, (bool exp) {
      if (mounted) setState(() => _panelCollapsed = !exp);
    });
  }

  @override
  void dispose() {
    _panelWorker?.dispose();
    super.dispose();
  }

  void _setCollapsed(bool v) {
    setState(() => _panelCollapsed = v);
    widget.controller.isBottomPanelExpanded.value = !v;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (c) {
        final isReverse = c.currentGameMode.value == 'reverse';
        final isInterval = c.currentGameMode.value == 'interval';
        final isChord = c.currentGameMode.value == 'chord';
        final gameRunning = c.isStart || c.isPaused;

        // Auto-collapse when the game starts (more fretboard); auto-expand
        // again when it ends. Applies to every mode.
        if (!_prevGameRunning && gameRunning && !_panelCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_panelCollapsed) _setCollapsed(true);
          });
        }
        if (_prevGameRunning && !gameRunning && _panelCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _panelCollapsed) _setCollapsed(false);
          });
        }
        _prevGameRunning = gameRunning;

        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top row — the modes shifter on the left (Quick start hands
              // mode-picking to the board, so and only so the dictionaries-style
              // "MODES" eyebrow appears; a Customized / Random / resumed session
              // picked its mode deliberately) and Save on the right. Save lives
              // up here rather than inside the control tile so the tile stays a
              // pure play surface.
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (c.quickStartSession)
                      KeyedSubtree(
                        key: fretboardTourKeys.modeSwitcher,
                        child: _BoardModeSwitcher(controller: c),
                      ),
                    const Spacer(),
                    JhgIconChipButton.header(
                      icon: JhgIcons.navHistory,
                      onTap: () => _showSessionHistory(context, c),
                    ),
                    const SizedBox(width: 8),
                    JhgIconChipButton.header(
                      icon: JhgIcons.save,
                      onTap: () => _saveSession(context, c),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Neither a TourReserve nor a TourOpenSpace on this screen, and
              // that is deliberate. The neck runs the full height, so any region
              // offered to the tour is frets and any region reserved pushes the
              // instruction down onto them. Left to plain geometry, a step whose
              // target sits low (or has none) anchors at the very top of the
              // screen, above the nut — the only placement that leaves the neck
              // itself clear.
              // ── Fretboard fills full Expanded height at all times ────────
              // Both the expanded panel and the collapsed tile are Positioned
              // overlays so the GuitarBoard always gets the full space.
              Expanded(
                key: fretboardTourKeys.fretboard,
                child: Stack(
                  children: [
                    // The fixed-pixel GuitarBoard fills the whole area and the
                    // tile floats OVER its lower portion (matches drills /
                    // dictionaries) — the neck runs behind the tile rather than
                    // being clipped above it. Auto-scroll keeps the active notes
                    // centred in the open area above the tile.
                    const Positioned.fill(
                      child: GuitarBoard(isPortrait: true),
                    ),

                    // One bottom overlay that swaps between the expanded
                    // card and the collapsed tile. The swap is instant (no
                    // height morph, no cross-fade) — the same behaviour as the
                    // Ear Training control tile. Only one state is built at a
                    // time, so the tour's play-button GlobalKey is never
                    // duplicated across a transition.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      // Subtle gap above the bottom navigation bar matching the drills layout
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        child: _panelCollapsed
                            ? _CollapsedTile(
                                controller: c,
                                isReverse: isReverse,
                                isInterval: isInterval,
                                isChord: isChord,
                                onExpand: () => _setCollapsed(false),
                              )
                            : _ExpandedPanel(
                                controller: c,
                                isReverse: isReverse,
                                isInterval: isInterval,
                                isChord: isChord,
                                onCollapse: () => _setCollapsed(true),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Nav bar (shared AppNavBar, so height/placement stay
              // identical across the board and every other screen) ──────────
              AppNavBar(
                activeTab: AppTab.train,
                controller: c,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Save ─────────────────────────────────────────────────────────────────────
// Snapshot the session so it can be resumed later. Lives on the top-right of
// the board, not in the control tile.
Future<void> _saveSession(BuildContext context, HomeController c) async {
  if (!c.sessionActive) {
    showCustomToast(
      context: context,
      message: 'Start a round first, then you can save it.',
      isError: true,
    );
    return;
  }
  final result = await showSaveSessionDialog(
    context,
    defaultName: c.defaultSessionName(),
  );
  if (result == null) return; // backed out
  final saved = await c.saveCurrentSession(
    customName: result.name,
    folderId: result.folderId,
  );
  if (!context.mounted) return;
  showCustomToast(
    context: context,
    message: saved
        ? 'Saved. Find it under Saved in the bar below.'
        : 'Could not save that one. Give it another go.',
    isError: !saved,
  );
}

// ─── Session History ───────────────────────────────────────────────────────────
Future<void> _showSessionHistory(BuildContext context, HomeController c) async {
  await showJHGBlurDialog(
    context: context,
    builder: (ctx) => Obx(() {
      final items = c.sessionHistory.reversed.toList();
      final total = items.length;
      final correctCount = items.where((i) => i.isCorrect).length;
      final pct = total == 0 ? 0 : (correctCount * 100 / total).round();

      return JHGFrostedDialog(
        icon: JhgIcons.navHistory,
        title: 'Session History',
        description: total == 0
            ? 'No attempts recorded yet this session.'
            : '$correctCount of $total correct ($pct% accuracy)',
        onClose: () => Navigator.of(ctx).pop(),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(JhgIcons.navHistory,
                          size: 36, color: Colors.white30),
                      const SizedBox(height: 12),
                      Text(
                        'No attempts yet',
                        style: JhgFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your note, chord, and interval answers will appear here as you play.',
                        textAlign: TextAlign.center,
                        style: JhgFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isCorrect = item.isCorrect;
                      final isRevealed = item.isRevealed;

                      final badgeColor = isCorrect
                          ? JHGColors.green
                          : (isRevealed
                              ? const Color(0xFFFE5D43)
                              : const Color(0xFFE53935)); // ds-guard: allow
                      final badgeIcon = isCorrect
                          ? JhgIcons.check
                          : (isRevealed ? JhgIcons.visible : JhgIcons.close);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.20),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: badgeColor, width: 1.2),
                              ),
                              child:
                                  Icon(badgeIcon, size: 14, color: badgeColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.prompt,
                                    style: JhgFonts.inter(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isRevealed
                                        ? 'Revealed: ${item.correctAnswer}'
                                        : (isCorrect
                                            ? 'Answer: ${item.correctAnswer}'
                                            : 'Picked: ${item.userAnswer}  •  Correct: ${item.correctAnswer}'),
                                    style: JhgFonts.inter(
                                      color: isCorrect
                                          ? JHGColors.green
                                          : (isRevealed
                                              ? const Color(0xFFFE5D43)
                                              : const Color(0xFFE53935)), // ds-guard: allow
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                              style: JhgFonts.inter(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => c.sessionHistory.clear(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Clear history',
                        style: JhgFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }),
  );
}

// ─── Expanded floating card ────────────────────────────────────────────────────
// Blurred glass card that overlays the bottom of the fretboard.
// Uses dictionaries' ClipRRect → BackdropFilter → Container pattern.

class _ExpandedPanel extends StatelessWidget {
  const _ExpandedPanel({
    required this.controller,
    required this.isReverse,
    required this.isInterval,
    required this.isChord,
    required this.onCollapse,
  });

  final HomeController controller;
  final bool isReverse;
  final bool isInterval;
  final bool isChord;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isPlaying = c.isStart || c.isPaused;
    final modeLabel = isChord
        ? (c.isChordLab
            ? _chordLabHeader(c)
            : c.isChordBuild
                ? 'BUILD THE CHORD'
                : 'NAME THE CHORD')
        : isInterval
            ? (c.isIntervalBuild
                ? 'BUILD THE INTERVAL'
                : 'NAME THE INTERVAL')
            : isReverse
                ? 'IDENTIFY THE NOTE'
                : 'FIND THE NOTE';

    // Canonical frosted collapse chip (34), the same one the dictionaries /
    // drills open panel uses.
    final collapseBtn = JhgGlassChevron(onTap: onCollapse, expanded: true);

    // Canonical glass tile — default open padding (20), matching the
    // dictionaries / drills open panel.
    return JhgGlassTile.open(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row: label + utility actions + collapse chevron ──
          Row(
            children: [
              Expanded(
                child: Text(
                  modeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Matches the dictionaries / drills open-tile eyebrow.
                  style: const TextStyle(
                    color: Color(0xFFB3B0AE),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (c.isStart) ...[
                JhgIconChipButton.compact(
                  icon: JhgIcons.volume,
                  onTap: () => unawaited(c.playCurrentPromptSound()),
                ),
                const SizedBox(width: 8),
                if (!c.isChordBuild) ...[
                  JhgIconChipButton.compact(
                    icon: JhgIcons.visible,
                    onTap: c.revealAnswer,
                  ),
                  const SizedBox(width: 8),
                ],
                JhgIconChipButton.compact(
                  key: fretboardTourKeys.skipButton,
                  icon: JhgIcons.next,
                  onTap: c.skipQuestion,
                ),
                const SizedBox(width: 8),
              ],
              collapseBtn,
            ],
          ),

          const SizedBox(height: 16),

          // ── Session Status: TIME + SCORE boxes (dict / drills style) ─
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StatRow(controller: c),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Center(child: CountTimerWidget()),
            ),

          // ── Mode-specific content area ──────────────────────────────
          if ((!c.isStart && !c.isPaused) ||
              (!isReverse && c.highlightNode == null)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Press play to start',
                style: JhgFonts.inter(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ] else if (c.isIntervalName) ...[
            _IntervalChoicePanel(controller: c),
            const SizedBox(height: 12),
          ] else if (c.isIntervalBuild) ...[
            _IntervalBuildPrompt(controller: c),
            const SizedBox(height: 12),
          ] else if (c.isChordName) ...[
            _ChordChoicePanel(controller: c),
            const SizedBox(height: 12),
          ] else if (c.isChordBuild) ...[
            _ChordBuildPrompt(controller: c),
            const SizedBox(height: 12),
          ] else if (c.isChordLab) ...[
            _ChordLabPanel(controller: c),
            const SizedBox(height: 12),
          ] else if (isReverse) ...[
            _ReverseChoicePanel(controller: c),
            const SizedBox(height: 12),
          ] else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                decoration: BoxDecoration(
                  color: JHGColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: JHGColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  c.highlightNode ?? '—',
                  style: JhgFonts.poppins(
                    color: JHGColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Primary Control row ─────────────────────────────────────
          _ControlRow(controller: c),
        ],
      ),
    );
  }
}

// ─── Collapsed bar — full-width, below the fretboard (matches drills/dict) ─────

/// Collapsed-tile prompt type.
///
/// [_kTileHero] is for the single thing the round is about (a note name, a
/// chord symbol, an interval). [_kTileLead] is the small word in front of it
/// ("Find", "Play"), and [_kTileAsk] is for a prompt that is a question rather
/// than a token, where the board itself is carrying the content.
const TextStyle _kTileHero = TextStyle(
  color: Color(0xFFFE5D43),
  fontSize: 28,
  fontWeight: FontWeight.w800,
  letterSpacing: -0.5,
  height: 1.05,
);

const TextStyle _kTileLead = TextStyle(
  color: Color(0xFFF1F1F1),
  fontSize: 15,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
  height: 1.1,
);

const TextStyle _kTileAsk = TextStyle(
  color: Color(0xFFF1F1F1),
  fontSize: 19,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.3,
  height: 1.1,
);

/// The hero token on its own. Scales down rather than clipping, so a long
/// interval name ("Perfect Fifth") still fits beside the tile's controls.
class _TileHero extends StatelessWidget {
  const _TileHero(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: _kTileHero),
    );
  }
}

/// A small lead word followed by the hero token, e.g. "Find" + "C#".
///
/// One rich Text rather than a Row, so the two sizes sit on a shared baseline
/// for free, and one FittedBox around the lot so a long token scales the whole
/// line down instead of clipping it.
class _TilePrompt extends StatelessWidget {
  const _TilePrompt({required this.lead, required this.hero});
  final String lead;
  final String hero;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$lead  ', style: _kTileLead),
          TextSpan(text: hero, style: _kTileHero),
        ]),
        maxLines: 1,
      ),
    );
  }
}

class _CollapsedTile extends StatelessWidget {
  const _CollapsedTile({
    required this.controller,
    required this.isReverse,
    required this.isInterval,
    required this.isChord,
    required this.onExpand,
  });

  final HomeController controller;
  final bool isReverse;
  final bool isInterval;
  final bool isChord;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isPlaying = c.isStart || c.isPaused;
    // Game type, not "… MODE" — so the user always sees what they're playing.
    final modeLabel = isChord
        ? (c.isChordLab
            ? _chordLabHeader(c)
            : c.isChordBuild
                ? 'BUILD THE CHORD'
                : 'NAME THE CHORD')
        : isInterval
            ? (c.isIntervalBuild ? 'BUILD THE INTERVAL' : 'NAME THE INTERVAL')
            : isReverse
                ? 'IDENTIFY THE NOTE'
                : 'FIND THE NOTE';
    final showAnswers = isReverse && isPlaying && c.reverseChoices.isNotEmpty;
    final showIntervalAnswers =
        c.isIntervalName && isPlaying && c.intervalChoicesList.isNotEmpty;
    final showChordAnswers =
        c.isChordName && isPlaying && c.chordChoicesList.isNotEmpty;
    final showChordBuildControls = c.isChordBuild && isPlaying;
    final showChordLabAnswers =
        c.isChordLabName && isPlaying && c.chordChoicesList.isNotEmpty;
    // Complete / Build rounds get a Clear control while collapsed; Remove has
    // nothing to clear.
    final showChordLabClear = c.isChordLab &&
        !c.isChordLabName &&
        isPlaying &&
        c.chordLabPrompt?.round != ChordLabRound.remove;
    final showChordLabRemoveHint = c.isChordLab &&
        isPlaying &&
        c.chordLabPrompt?.round == ChordLabRound.remove;
    final locked = c.reverseSelectedNote != null;
    final intervalLocked = c.intervalSelected != null;

    Widget answerButton(String note) {
      final s = _answerStyle(note, c);
      final isWrongPick = c.reverseSelectedNote != null &&
          !c.reverseWasCorrect &&
          note == c.reverseSelectedNote;
      return _ShakeOnWrong(
        wrong: isWrongPick,
        child: GestureDetector(
          onTap: locked ? null : () => c.selectReverseAnswer(note),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: s.border, width: 1.4),
            ),
            child: Center(
              child: Text(
                note,
                style: JhgFonts.poppins(
                  color: s.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final playBtn = JhgTransportButton(
      key: fretboardTourKeys.playButton,
      state: c.isStart ? JhgTransportState.pause : JhgTransportState.play,
      size: 46,
      iconSize: 20,
      onTap: c.isStart
          ? c.pauseGame
          : c.isPaused
              ? c.resumeGame
              : () {
                  c.startTimer();
                  c.startTheGame();
                },
    );

    // Canonical frosted expand affordance (42 · r13) — the same control the
    // dictionaries / drills tiles use, not a hand-rolled 32px square.
    final expandBtn = JhgGlassChevron(onTap: onExpand, expanded: false);

    // In-tile chips (34 · r11 · 18) straight from jhg_elements, so the utility
    // controls read as the suite's canonical chip rather than a local variant.
    final skipBtn = JhgIconChipButton.compact(
      key: fretboardTourKeys.skipButton,
      icon: JhgIcons.next,
      onTap: c.skipQuestion,
    );

    final listenBtn = JhgIconChipButton.compact(
      icon: JhgIcons.volume,
      onTap: () => unawaited(c.playCurrentPromptSound()),
    );

    final revealBtn = JhgIconChipButton.compact(
      icon: JhgIcons.visible,
      onTap: c.revealAnswer,
    );

    Widget buildPromptWidget() {
      if (!isPlaying) {
        return const Text(
          'Tap play to start',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _kTileLead,
        );
      }
      if (isChord && c.isChordLab) {
        return c.isChordLabName
            ? const Text(
                'Which chord?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _kTileAsk,
              )
            : _TileHero(c.chordLabPrompt?.target.symbol ?? '—');
      }
      if (isChord && c.isChordBuild) {
        return _TilePrompt(
          lead: 'Play',
          hero: c.chordPrompt?.symbol ?? '—',
        );
      }
      if (isChord) {
        return const Text(
          'Which chord?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _kTileAsk,
        );
      }
      if (isInterval && c.isIntervalBuild) {
        return _TilePrompt(
          lead: 'Play',
          hero: c.intervalPrompt?.interval.name ?? '—',
        );
      }
      if (isInterval) {
        return const Text(
          'Which interval?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _kTileAsk,
        );
      }
      if (isReverse) {
        return const Text(
          'Which note is this?',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _kTileAsk,
        );
      }
      return _TilePrompt(lead: 'Find', hero: c.highlightNode ?? '—');
    }

    // Canonical glass tile — default padding (12), same as the dictionaries /
    // drills control tile, so the box reads as the shared jhg_elements surface
    // rather than a locally padded variant.
    return JhgGlassTile.closed(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Tier 1: Eyebrow + Utility controls & Expand ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  modeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Matches the dictionaries / drills tile eyebrow.
                  style: const TextStyle(
                    color: Color(0xFFB3B0AE),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (c.isStart) ...[
                listenBtn,
                const SizedBox(width: 8),
                if (!showChordBuildControls) ...[
                  revealBtn,
                  const SizedBox(width: 8),
                ],
                skipBtn,
                const SizedBox(width: 8),
              ],
              expandBtn,
            ],
          ),

          const SizedBox(height: 14),

          // ── Tier 2: Hero Prompt & Transport Play Button ─────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: buildPromptWidget()),
              const SizedBox(width: 14),
              playBtn,
            ],
          ),

          // ── Session stats: TIME + SCORE boxes (dict / drills style) ──
          if (isPlaying) ...[
            const SizedBox(height: 12),
            _StatRow(controller: c),
          ],

          // ── Tier 3: Mode-specific choice options / actions ───────────
          if (showAnswers) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (int i = 0; i < c.reverseChoices.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: answerButton(c.reverseChoices[i])),
                ],
              ],
            ),
          ],

          if (showIntervalAnswers) ...[
            const SizedBox(height: 14),
            _IntervalChoiceGrid(
              controller: c,
              locked: intervalLocked,
            ),
          ],

          if (showChordAnswers) ...[
            const SizedBox(height: 14),
            _ChordChoiceGrid(
              controller: c,
              locked: c.chordSelected != null,
            ),
          ],

          if (showChordBuildControls) ...[
            const SizedBox(height: 14),
            _ChordBuildControls(controller: c),
          ],

          if (showChordLabAnswers) ...[
            const SizedBox(height: 14),
            _ChordChoiceGrid(
              controller: c,
              locked: c.chordSelected != null,
              onPick: c.selectChordLabName,
            ),
          ],

          if (showChordLabClear) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(JhgIcons.help, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _chordLabHint(c.chordLabPrompt!.round),
                    style: JhgFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: c.clearChordLab,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(JhgIcons.backspace,
                            color: Colors.white60, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Clear',
                          style: JhgFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (showChordLabRemoveHint) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(JhgIcons.help,
                      color: JHGColors.primary, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    "Tap the note that doesn't belong",
                    style: JhgFonts.inter(
                      color: Colors.white60,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Answer-button colour helper (shared by tile + expanded panel) ─────────────

_BtnStyle _answerStyle(String note, HomeController c) {
  final selected = c.reverseSelectedNote;
  final neutral = _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.08),
    border: Colors.white.withValues(alpha: 0.12),
    text: Colors.white,
  );
  if (selected == null) return neutral;
  // Correct pick → reveal green and fade the rest as the round ends.
  if (c.reverseWasCorrect) {
    if (note == c.highlightNode) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.20),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.03),
      border: Colors.white.withValues(alpha: 0.05),
      text: Colors.white30,
    );
  }
  // Wrong pick → flash only the tapped button; leave the others tappable so
  // the user can keep guessing (we never reveal the correct answer).
  if (note == selected) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return neutral;
}

// ─── In-board Modes shifter ───────────────────────────────────────────────────
// The dictionaries / drills canvas switcher, matched in shape: a coral "MODES"
// eyebrow over the current mode name in white with a chevron, sitting top-left
// over the neck. Tapping opens a frosted picker; choosing a mode swaps the whole
// game in place (via the controller's switchTo* methods), keeping the last-used
// game type / difficulty for Intervals and Chords.
//
// Only shown for a Quick start session — see PortraitBoard.
class _BoardModeSwitcher extends StatelessWidget {
  const _BoardModeSwitcher({required this.controller});
  final HomeController controller;

  static const _kModes = <(String, String, IconData)>[
    ('Notes', 'Find and name notes on the neck', JhgIcons.note),
    ('Intervals', 'Name and build every interval', Icons.straighten_rounded),
    ('Chords', 'Name and build chord shapes', Icons.grid_goldenratio_rounded),
  ];

  // Chord Lab is a specialised chord flow; it still reads as "Chords" here.
  int get _activeIndex => controller.isIntervalMode
      ? 1
      : controller.isChordMode
          ? 2
          : 0;

  void _select(int i) {
    if (i == _activeIndex) return;
    switch (i) {
      case 0:
        controller.switchToFindMode();
        break;
      case 1:
        controller.switchToIntervalMode();
        break;
      case 2:
        controller.switchToChordMode();
        break;
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    final active = _activeIndex;
    await showJHGBlurDialog(
      context: context,
      builder: (ctx) => JHGFrostedDialog(
        icon: LucideIcons.layoutGrid,
        title: 'Switch mode',
        description: 'Switching starts a fresh round. Whatever you set up '
            'for each mode is kept.',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _kModes.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _ModeOption(
                label: _kModes[i].$1,
                subtitle: _kModes[i].$2,
                icon: _kModes[i].$3,
                isActive: i == active,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _select(i);
                },
              ),
            ],
          ],
        ),
      ),
    );
    // Fires whichever way it went, so the tour's last step ends when the picker
    // does rather than forcing anyone to abandon the mode they chose.
    controller.modeSwitcherRevision.value++;
  }

  @override
  Widget build(BuildContext context) {
    final modeName = _kModes[_activeIndex].$1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openPicker(context),
      // Boxless, matching the dictionaries canvas switcher: a small coral
      // eyebrow above the current mode name, left-aligned, with a coral
      // chevron dot signalling the tap.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'MODES',
            style: TextStyle(
              color: JHGColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                modeName,
                style: const TextStyle(
                  color: Color(0xFFF1F1F1),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: JHGColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.chevronsUpDown,
                  color: JHGColors.primary,
                  size: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One row in the Modes picker — icon chip, name + blurb, and a coral tick on
/// the mode that's already running.
class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? JHGColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive
                ? JHGColors.primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isActive ? JHGColors.primary : Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: JhgFonts.poppins(
                      color: isActive ? JHGColors.primary : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: JhgFonts.inter(
                      color: Colors.white38,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(JhgIcons.check, color: JHGColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Shared control row ───────────────────────────────────────────────────────

class _ControlRow extends StatelessWidget {
  final HomeController controller;
  const _ControlRow({required this.controller});

  IconData _resolveTimerIcon(String mode) {
    switch (mode) {
      case 'countdown':
        return LucideIcons.clock;
      case 'leaderboard':
        return JhgIcons.trophy;
      default:
        return JhgIcons.duration;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final isChoiceMode = c.isChoiceMode;
    final mode = c.currentGameMode.value;
    final disabled = c.isStart || c.isPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Timer-mode cycle
        JhgCircleIconButton(
          icon: _resolveTimerIcon(isChoiceMode ? c.timerMode.value : mode),
          size: 50,
          iconSize: 20,
          enabled: !disabled,
          onTap: c.cycleGameMode,
        ),

        // Play / Pause / Resume
        JhgTransportButton(
          key: fretboardTourKeys.playButton,
          // Tapping while running pauses (Reset is the separate control), so
          // show a pause glyph — a stop icon promised something else.
          state: c.isStart ? JhgTransportState.pause : JhgTransportState.play,
          size: 64,
          iconSize: 28,
          onTap: c.isStart
              ? c.pauseGame
              : c.isPaused
                  ? c.resumeGame
                  : () {
                      c.startTimer();
                      c.startTheGame();
                    },
        ),

        // Reset
        JhgCircleIconButton(
          icon: JhgIcons.reset,
          size: 50,
          iconSize: 20,
          onTap: () => c.resetGame(true),
        ),
      ],
    );
  }
}

// ─── Session stat boxes (TIME / SCORE) ────────────────────────────────────────
// The same label-over-value info box the dictionaries / drills tiles use for
// ROOT / TONALITY, so the fretboard tile reads as the same family. TIME turns
// coral while the clock runs; SCORE turns green / coral with its sign.

/// A single dict-style info box: a small label over a bold value.
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
    this.borderColor,
    this.fillColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Color? labelColor;
  final Color? borderColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor ?? Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: JhgFonts.poppins(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// The TIME + SCORE box pair, shared by the collapsed tile and the open panel
/// so the session readout is identical in both.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final score = c.score;
      final running = c.isStart;
      final time = c.formatTime(c.secondsRemaining.value);
      return Row(
        children: [
          Expanded(
            child: _StatBox(
              label: 'TIME',
              value: time,
              valueColor: running ? JHGColors.primary : Colors.white,
              labelColor: running ? JHGColors.primary : null,
              borderColor: running
                  ? JHGColors.primary.withValues(alpha: 0.30)
                  : null,
              fillColor: running
                  ? JHGColors.primary.withValues(alpha: 0.10)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatBox(
              label: 'SCORE',
              value: '$score',
              valueColor: score > 0
                  ? JHGColors.green
                  : score < 0
                      ? JHGColors.primary
                      : Colors.white,
            ),
          ),
        ],
      );
    });
  }
}

// ─── Reverse mode choice panel ────────────────────────────────────────────────

class _ReverseChoicePanel extends StatelessWidget {
  const _ReverseChoicePanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.reverseChoices.isEmpty) return const SizedBox.shrink();
    final locked = controller.reverseSelectedNote != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.identifyShowPositionHint) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Text(controller.reversePositionHint,
                style: JhgFonts.inter(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: controller.reverseChoices.map((note) {
            final s = _answerStyle(note, controller);
            final isWrongPick = controller.reverseSelectedNote != null &&
                !controller.reverseWasCorrect &&
                note == controller.reverseSelectedNote;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _ShakeOnWrong(
                  wrong: isWrongPick,
                  child: GestureDetector(
                    onTap: locked
                        ? null
                        : () => controller.selectReverseAnswer(note),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 58,
                      decoration: BoxDecoration(
                        color: s.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: s.border, width: 1.5),
                      ),
                      child: Center(
                        child: Text(note,
                            style: JhgFonts.poppins(
                                color: s.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Horizontal shake played once when [wrong] flips true (mirrors the Ear
// Training answer feedback). Paired with the coral colour flash + buzzer SFX.
class _ShakeOnWrong extends StatefulWidget {
  const _ShakeOnWrong({required this.wrong, required this.child});
  final bool wrong;
  final Widget child;

  @override
  State<_ShakeOnWrong> createState() => _ShakeOnWrongState();
}

class _ShakeOnWrongState extends State<_ShakeOnWrong>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    if (widget.wrong) _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _ShakeOnWrong old) {
    super.didUpdateWidget(old);
    if (widget.wrong && !old.wrong) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(sin(4 * pi * _ctrl.value) * 5, 0),
          child: child,
        ),
        child: widget.child,
      );
}

class _BtnStyle {
  const _BtnStyle({required this.bg, required this.border, required this.text});
  final Color bg;
  final Color border;
  final Color text;
}

// ─── Interval mode ───────────────────────────────────────────────────────────

// Expanded-panel version: the 2×2 interval-name grid (score now lives in the
// shared bottom score bar).
class _IntervalChoicePanel extends StatelessWidget {
  const _IntervalChoicePanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.intervalChoicesList.isEmpty) return const SizedBox.shrink();
    return _IntervalChoiceGrid(
        controller: c, locked: c.intervalSelected != null);
  }
}

// 2×2 grid of interval-name choices (names are too long for a single row).
// Shared by the expanded panel and the collapsed tile.
class _IntervalChoiceGrid extends StatelessWidget {
  const _IntervalChoiceGrid({required this.controller, required this.locked});
  final HomeController controller;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final choices = c.intervalChoicesList;
    if (choices.isEmpty) return const SizedBox.shrink();

    Widget button(MusicInterval choice) {
      final s = _intervalStyle(choice, c);
      final isWrongPick = c.intervalSelected != null &&
          !c.intervalWasCorrect &&
          choice.semitones == c.intervalSelected!.semitones;
      return _ShakeOnWrong(
        wrong: isWrongPick,
        child: GestureDetector(
          onTap: locked ? null : () => c.selectIntervalAnswer(choice),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.border, width: 1.4),
            ),
            alignment: Alignment.center,
            child: Text(
              choice.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: JhgFonts.poppins(
                color: s.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    Widget row(int a, int b) => Row(
          children: [
            Expanded(child: button(choices[a])),
            const SizedBox(width: 10),
            if (b < choices.length)
              Expanded(child: button(choices[b]))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, 1),
        const SizedBox(height: 10),
        row(2, 3),
      ],
    );
  }
}

// Build mode: shows the interval to play (relative to the coral root note) plus
// the score, with a plain-language instruction so the task is unambiguous.
class _IntervalBuildPrompt extends StatelessWidget {
  const _IntervalBuildPrompt({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final name = c.intervalPrompt?.interval.name ?? '—';
    final rootNote = c.intervalRootIndex != null
        ? (fretList[c.intervalRootIndex!].note ?? '')
        : '';
    final direction = c.intervalDifficulty == IntervalDifficulty.hard
        ? 'above or below'
        : 'above';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: JHGColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('PLAY A',
                    style: JhgFonts.inter(
                      color: JHGColors.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    )),
                const SizedBox(width: 10),
                Text(name,
                    style: JhgFonts.poppins(
                      color: JHGColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Plain-language instruction referencing the coral note on the neck.
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: JhgFonts.inter(
                color: Colors.white54, fontSize: 12.5, height: 1.35),
            children: [
              const TextSpan(text: 'Tap the note '),
              TextSpan(
                text: name.toLowerCase(),
                style: const TextStyle(
                    color: Color(0xFFF1F1F1), fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' $direction the '),
              const TextSpan(
                text: 'coral',
                style: TextStyle(
                    color: Color(0xFFFE5D43), fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: rootNote.isEmpty ? ' note' : ' note ($rootNote)',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Interval answer-button colours: neutral until locked, then green for the
// correct interval and coral for a wrong pick.
_BtnStyle _intervalStyle(MusicInterval choice, HomeController c) {
  final selected = c.intervalSelected;
  final correct = c.intervalPrompt?.interval;
  final neutral = _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.08),
    border: Colors.white.withValues(alpha: 0.12),
    text: Colors.white,
  );
  if (selected == null || correct == null) return neutral;
  // Correct pick → reveal green and fade the rest as the round ends.
  if (c.intervalWasCorrect) {
    if (choice.semitones == correct.semitones) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.20),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.03),
      border: Colors.white.withValues(alpha: 0.05),
      text: Colors.white30,
    );
  }
  // Wrong pick → flash only the tapped choice; leave the others tappable so
  // the user can keep guessing (we never reveal the correct answer).
  if (choice.semitones == selected.semitones) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return neutral;
}

// ─── Chord mode ──────────────────────────────────────────────────────────────

// Chord-symbol button colours: neutral until an answer is locked, then green
// for the correct symbol and coral for a wrong pick.
_BtnStyle _chordSymbolStyle(String symbol, HomeController c) {
  final selected = c.chordSelected;
  // Chord Lab name rounds keep their target on chordLabPrompt, not chordPrompt.
  final correct = c.chordPrompt?.symbol ?? c.chordLabPrompt?.target.symbol;
  final neutral = _BtnStyle(
    bg: Colors.white.withValues(alpha: 0.08),
    border: Colors.white.withValues(alpha: 0.12),
    text: Colors.white,
  );
  if (selected == null || correct == null) return neutral;
  // Correct pick → reveal green and fade the rest as the round ends.
  if (c.chordWasCorrect) {
    if (symbol == correct) {
      return _BtnStyle(
        bg: JHGColors.green.withValues(alpha: 0.20),
        border: JHGColors.green,
        text: JHGColors.green,
      );
    }
    return _BtnStyle(
      bg: Colors.white.withValues(alpha: 0.03),
      border: Colors.white.withValues(alpha: 0.05),
      text: Colors.white30,
    );
  }
  // Wrong pick → flash only the tapped symbol; leave the others tappable so
  // the user can keep guessing (we never reveal the correct answer).
  if (symbol == selected) {
    return _BtnStyle(
      bg: JHGColors.primary.withValues(alpha: 0.18),
      border: JHGColors.primary,
      text: JHGColors.primary,
    );
  }
  return neutral;
}

// Expanded-panel version: score chip above the 2×2 symbol grid.
class _ChordChoicePanel extends StatelessWidget {
  const _ChordChoicePanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.chordChoicesList.isEmpty) {
      return _chordLoadingHint(c);
    }
    return _ChordChoiceGrid(controller: c, locked: c.chordSelected != null);
  }
}

// ── Chord Lab ────────────────────────────────────────────────────────────────

/// Header eyebrow for the current Chord Lab round.
String _chordLabHeader(HomeController c) {
  final p = c.chordLabPrompt;
  if (p == null) return 'CHORD LAB';
  switch (p.round) {
    case ChordLabRound.name:
      return 'NAME THIS CHORD';
    case ChordLabRound.complete:
      return 'COMPLETE THE CHORD';
    case ChordLabRound.remove:
      return 'REMOVE THE EXTRA NOTE';
    case ChordLabRound.build:
      return 'BUILD THIS CHORD';
  }
}

String _chordLabHint(ChordLabRound round) {
  switch (round) {
    case ChordLabRound.name:
      return 'Pick its name.';
    case ChordLabRound.complete:
      return 'Tap the missing note(s).';
    case ChordLabRound.remove:
      return "Tap the note that doesn't belong.";
    case ChordLabRound.build:
      return 'Build it inside the band.';
  }
}

/// Panel body for a Chord Lab round: score (+ target symbol on board rounds), a
/// one-line task hint, and either the name grid or a Clear control.
class _ChordLabPanel extends StatelessWidget {
  const _ChordLabPanel({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p = c.chordLabPrompt;
    if (p == null) return _chordLoadingHint(c);
    final isName = p.round == ChordLabRound.name;
    final showClear =
        p.round == ChordLabRound.complete || p.round == ChordLabRound.build;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isName) ...[
          Center(child: _labSymbolChip(p.target.symbol)),
          const SizedBox(height: 10),
        ],
        Text(
          _chordLabHint(p.round),
          textAlign: TextAlign.center,
          style: JhgFonts.inter(
              color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        if (isName)
          _ChordChoiceGrid(
            controller: c,
            locked: c.chordSelected != null,
            onPick: c.selectChordLabName,
          )
        else if (showClear)
          _labClearButton(c),
      ],
    );
  }

  Widget _labSymbolChip(String symbol) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: JHGColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JHGColors.primary.withValues(alpha: 0.4)),
        ),
        child: Text(
          symbol,
          style: JhgFonts.poppins(
            color: JHGColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _labClearButton(HomeController c) => GestureDetector(
        onTap: c.clearChordLab,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(JhgIcons.backspace, color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Text('Clear',
                  style: JhgFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// 2×2 grid of chord-symbol choices — shared by the expanded panel and the
// collapsed tile.
class _ChordChoiceGrid extends StatelessWidget {
  const _ChordChoiceGrid({
    required this.controller,
    required this.locked,
    this.onPick,
  });
  final HomeController controller;
  final bool locked;

  /// Defaults to the Name-mode handler; Chord Lab passes selectChordLabName.
  final void Function(String symbol)? onPick;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final choices = c.chordChoicesList;
    if (choices.isEmpty) return const SizedBox.shrink();
    final pick = onPick ?? c.selectChordAnswer;

    Widget button(String symbol) {
      final s = _chordSymbolStyle(symbol, c);
      final isWrongPick = c.chordSelected != null &&
          !c.chordWasCorrect &&
          symbol == c.chordSelected;
      return _ShakeOnWrong(
        wrong: isWrongPick,
        child: GestureDetector(
          onTap: locked ? null : () => pick(symbol),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.border, width: 1.4),
            ),
            alignment: Alignment.center,
            child: Text(
              symbol,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: JhgFonts.poppins(
                color: s.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    Widget row(int a, int b) => Row(
          children: [
            Expanded(child: button(choices[a])),
            const SizedBox(width: 10),
            if (b < choices.length)
              Expanded(child: button(choices[b]))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(0, 1),
        if (choices.length > 2) ...[
          const SizedBox(height: 10),
          row(2, 3),
        ],
      ],
    );
  }
}

// Build mode: the chord symbol to place + score + a plain-language instruction,
// with Clear / Reveal controls underneath.
class _ChordBuildPrompt extends StatelessWidget {
  const _ChordBuildPrompt({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.chordPrompt == null) return _chordLoadingHint(c);
    final shape = c.chordPrompt!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: JHGColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: JHGColors.primary.withValues(alpha: 0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('PLAY',
                    style: JhgFonts.inter(
                      color: JHGColors.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    )),
                const SizedBox(width: 10),
                Text(shape.symbol,
                    style: JhgFonts.poppins(
                      color: JHGColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          shape.qualityName,
          textAlign: TextAlign.center,
          style: JhgFonts.inter(
              color: Colors.white54, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 12),
        _ChordBuildControls(controller: c),
      ],
    );
  }
}

// Notes-placed counter + Clear + Reveal, used in both the expanded panel and
// the collapsed tile.
class _ChordBuildControls extends StatelessWidget {
  const _ChordBuildControls({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final placed = c.chordTapped.length;
    final done = c.chordBuildDone;
    final revealed = c.chordBuildReveal != null;

    Widget pill({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      Color? tint,
    }) {
      final color = tint ?? Colors.white70;
      final isEnabled = onTap != null;
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled
                ? (tint != null
                    ? tint.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.07))
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled
                  ? (tint != null
                      ? tint.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.14))
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isEnabled ? color : Colors.white24),
              const SizedBox(width: 6),
              Text(
                label,
                style: JhgFonts.inter(
                  color: isEnabled ? color : Colors.white24,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // After a reveal the shape is shown with note names on the neck; the Reveal
    // control turns into a solid coral "Next" so the user moves on when ready
    // (the round no longer skips itself).
    if (revealed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          pill(
            icon: JhgIcons.reset,
            label: 'Other voicing',
            tint: Colors.white,
            onTap: c.revealChordBuild,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: c.nextBuildChord,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: JHGColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: JHGColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: JhgFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(JhgIcons.chevronRight,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            '$placed placed',
            style: JhgFonts.inter(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        pill(
          icon: JhgIcons.backspace,
          label: 'Clear',
          onTap: (placed == 0 || done) ? null : c.clearChordBuild,
        ),
        const SizedBox(width: 8),
        pill(
          icon: JhgIcons.visible,
          label: 'Reveal',
          tint: JHGColors.primary,
          onTap: done ? null : c.revealChordBuild,
        ),
      ],
    );
  }
}

// Placeholder copy for the chord panel: distinguishes the (rare) parse wait
// from the idle "not started yet" state so an idle board never looks stuck.
Widget _chordLoadingHint(HomeController c) {
  final String hint;
  if (c.chordCatalogLoading) {
    hint = 'Loading chords…';
  } else if (!c.isStart) {
    hint = 'Press play to start';
  } else {
    hint = 'Getting the next chord…';
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      hint,
      textAlign: TextAlign.center,
      style: JhgFonts.inter(
        color: Colors.white38,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
