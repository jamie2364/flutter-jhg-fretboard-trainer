// views/screens/heatmap/stats_breakdown_view.dart
//
// The detail body for one non-note game (Intervals / Chords / Chord Lab). Where
// the Notes module shows a per-fret heatmap, these games are about which
// *interval* or *chord quality* you know — so this view breaks a player's
// history down into:
//   • an overall accuracy ring,
//   • Strongest / Needs-work highlight cards,
//   • a bar-chart graph of every item,
//   • a per-game-type (or per-Chord-Lab-round) split — every mode shown, even
//     the ones you haven't tried yet,
//   • and a full weakest-first list so the thing to practise sits on top.
//
// It reads nothing itself — the parent passes in the already-loaded breakdown.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fretboard/services/practice_stats_service.dart';
import 'package:fretboard/utils/chords.dart';
import 'package:fretboard/utils/intervals.dart';
import 'package:google_fonts/google_fonts.dart';

// Shared accuracy palette (matches the Notes heatmap legend).
const _cStruggle = Color(0xFFE05252);
const _cLearning = Color(0xFFE8961A);
const _cGood = Color(0xFF4CB87A);
const _cMastered = Color(0xFF2ECC71);
// Matches the Settings design system (SettingsTokens): page #0F0F0F,
// card #1A1A1A with a hairline white border.
const _cCard = Color(0xFF1A1A1A);
const _cCoral = Color(0xFFFE5D43);
const _cNoData = Color(0xFF3A3A3A); // untried — neutral, never "failing" red

Color _accColor(double acc) {
  if (acc >= 0.85) return _cMastered;
  if (acc >= 0.70) return _cGood;
  if (acc >= 0.50) return _cLearning;
  return _cStruggle;
}

/// Colour for an entry that may not have been tried yet: grey when untried, so
/// "not practised" never reads as "failing".
Color _entryColor(StatEntry? e) =>
    (e == null || !e.hasData) ? _cNoData : _accColor(e.accuracy);

/// A short judgement word for an accuracy value.
String _accWord(double acc) {
  if (acc >= 0.85) return 'Mastered';
  if (acc >= 0.70) return 'Solid';
  if (acc >= 0.50) return 'Learning';
  return 'Shaky';
}

/// One bar in the chart: a label, its accuracy, and whether it has data.
class _Bar {
  const _Bar(this.label, this.entry);
  final String label;
  final StatEntry? entry;
  double get acc => entry?.accuracy ?? 0;
  bool get hasData => entry?.hasData ?? false;
}

/// Time window for the progress line chart.
enum _Range { d7, d30, all }

/// Which face of the breakdown card is showing.
enum _BView { chart, list }

/// Ordering for the weakest-first list (now user-selectable).
enum _ListSort { weakest, strongest, mostPractised, alpha }

class StatBreakdownView extends StatefulWidget {
  const StatBreakdownView({
    super.key,
    required this.module,
    required this.data,
    this.history = const [],
    this.showIntro = false,
  });

  /// 1 = Intervals, 2 = Chords, 3 = Chord Lab.
  final int module;
  final ModuleBreakdown data;

  /// Daily accuracy history for this module, oldest → newest (for the progress
  /// chart). Empty when nothing has been recorded yet.
  final List<DayStat> history;

  /// Whether to reveal the explanatory blurb (toggled by the top-bar ⓘ button).
  final bool showIntro;

  @override
  State<StatBreakdownView> createState() => _StatBreakdownViewState();
}

class _StatBreakdownViewState extends State<StatBreakdownView> {
  _Range _range = _Range.d7;
  _BView _view = _BView.chart;
  _ListSort _sort = _ListSort.weakest;

  int get module => widget.module;
  ModuleBreakdown get data => widget.data;
  List<DayStat> get history => widget.history;
  bool get showIntro => widget.showIntro;

  bool get _isLab => module == 3;
  bool get _isNotes => module == 0;
  String get _itemNoun =>
      module == 0 ? 'note' : module == 1 ? 'interval' : 'chord';

  String get _intro {
    switch (module) {
      case 0:
        return 'How well you know every note across the neck, the same '
            'Find & Identify rounds, aggregated per note. Your weakest notes '
            'rise to the top, and the neck map shows exactly where they sit.';
      case 1:
        return 'How well you recognise and build each interval, from a minor '
            '2nd up to the octave. Your weakest intervals rise to the top.';
      case 2:
        return 'Your accuracy on each chord quality: majors, minors, 7ths and '
            'beyond. See at a glance which shapes you own and which to drill.';
      default:
        return 'Your Chord Lab results, split by the four drills and by chord '
            'quality, so you can see which exercises and chords need more reps.';
    }
  }

  IconData get _icon {
    switch (module) {
      case 0:
        return Icons.music_note_rounded;
      case 1:
        return Icons.straighten_rounded;
      case 2:
        return Icons.grid_goldenratio_rounded;
      default:
        return Icons.science_rounded;
    }
  }

  String _qualityLabel(String key) {
    if (module == 0) return key; // the note name itself, e.g. "F#"
    if (module == 1) return intervalForShort(key)?.name ?? key;
    return chordQualityLabel(key);
  }

  String _qualitySub(String key) {
    if (module == 0) return ''; // note name is self-explanatory
    if (module == 1) return key; // e.g. "P5"
    final suffix = chordSuffixFor(key);
    return suffix.isEmpty ? 'maj' : suffix;
  }

  @override
  Widget build(BuildContext context) {
    if (!data.hasData) return _EmptyState(module: module, noun: _itemNoun);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        // The blurb is hidden by default; the ⓘ button in the top bar reveals it
        // here, animating the rest of the content down (like Settings).
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              showIntro ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [_introCard(), const SizedBox(height: 16)],
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        _overallCard(),
        const SizedBox(height: 14),
        _progressSection(),
        _highlightRow(),
        const SizedBox(height: 20),
        // Bar chart and weakest-first list now live in one card, switched by a
        // Chart / List toggle so only one shows at a time; the accuracy legend
        // is merged into the same card's footer.
        _breakdownCard(),
        const SizedBox(height: 20),
        _splitSection(),
      ],
    );
  }

  // ── Intro ──────────────────────────────────────────────────────────────────
  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cCoral.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cCoral.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _cCoral.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _cCoral, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _intro,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overall ring ────────────────────────────────────────────────────────────
  Widget _overallCard() {
    final acc = data.accuracy;
    final color = _accColor(acc);
    final practised = _isLab ? data.byRound.length : data.byQuality.length;
    final practisedNoun = _isLab ? 'drills tried' : '${_itemNoun}s practised';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _AccuracyRing(accuracy: acc, color: color, size: 96),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall accuracy',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _accWord(acc),
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 10),
                _miniStat('${data.totalCorrect}',
                    'correct of ${data.totalAttempts} tries'),
                const SizedBox(height: 4),
                _miniStat('$practised', practisedNoun),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$value ',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: label,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Progress over time ──────────────────────────────────────────────────────

  /// All recorded days that had at least one attempt, oldest → newest.
  List<DayStat> get _activeDays =>
      history.where((d) => d.attempts > 0).toList();

  /// The active days that fall inside the currently-selected window.
  List<DayStat> _daysInRange() {
    final days = _activeDays;
    if (_range == _Range.all || days.isEmpty) return days;
    final now = DateTime.now();
    final span = _range == _Range.d7 ? 6 : 29;
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: span));
    return days.where((d) {
      final dt = DateTime.tryParse(d.day);
      return dt == null || !dt.isBefore(cutoff);
    }).toList();
  }

  Widget _progressSection() {
    if (_activeDays.isEmpty) return const SizedBox.shrink();
    final ranged = _daysInRange();
    final enough = ranged.length >= 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        decoration: BoxDecoration(
          color: _cCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _sectionTitle(
                    'Progress over time',
                    'Your accuracy day by day, oldest on the left.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _rangeSelector(),
            const SizedBox(height: 16),
            if (enough) ...[
              _ProgressChart(points: ranged.map((d) => d.accuracy).toList()),
              const SizedBox(height: 12),
              _progressDelta(ranged.first, ranged.last),
            ] else if (ranged.length == 1)
              _singleDayNote(ranged.first)
            else
              _emptyRangeNote(),
          ],
        ),
      ),
    );
  }

  Widget _rangeSelector() {
    return _Segmented<_Range>(
      value: _range,
      options: const [
        (_Range.d7, '7 days'),
        (_Range.d30, '30 days'),
        (_Range.all, 'All'),
      ],
      onChanged: (r) => setState(() => _range = r),
    );
  }

  Widget _emptyRangeNote() {
    final label = _range == _Range.d7 ? 'the last 7 days' : 'the last 30 days';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'No practice logged in $label. Try “All”, or play a round today.',
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
      ),
    );
  }

  Widget _progressDelta(DayStat first, DayStat last) {
    final delta = ((last.accuracy - first.accuracy) * 100).round();
    final improved = delta >= 0;
    final color = improved ? _cMastered : _cStruggle;
    final label = delta == 0
        ? 'Holding steady so far'
        : '${improved ? '+' : ''}$delta% since ${_dayLabel(first.day)}';
    return Row(
      children: [
        Icon(improved ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          'now ${(last.accuracy * 100).round()}%',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _singleDayNote(DayStat only) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _cCoral.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Today: ${(only.accuracy * 100).round()}%',
            style: GoogleFonts.poppins(
              color: _cCoral,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${only.correct} of ${only.attempts} correct so far.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _dayLabel(String ymd) {
    final d = DateTime.tryParse(ymd);
    if (d == null) return 'the start';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  // ── Highlights ──────────────────────────────────────────────────────────────
  Widget _highlightRow() {
    final strongest = data.strongest;
    final weakest = data.weakest;
    final sameItem = strongest != null &&
        weakest != null &&
        strongest.key == weakest.key;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _highlightCard(
              title: 'Strongest', entry: strongest, positive: true),
        ),
        if (!sameItem) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _highlightCard(
                title: 'Needs work', entry: weakest, positive: false),
          ),
        ],
      ],
    );
  }

  Widget _highlightCard({
    required String title,
    required MapEntry<String, StatEntry>? entry,
    required bool positive,
  }) {
    final color = positive ? _cMastered : _cStruggle;
    final acc = entry?.value.accuracy ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                positive
                    ? Icons.emoji_events_rounded
                    : Icons.trending_up_rounded,
                color: color,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry == null ? '—' : _qualityLabel(entry.key),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry == null
                ? 'No data yet'
                : '${(acc * 100).round()}% · ${entry.value.correct}/${entry.value.attempts}',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  // ── Breakdown card (chart ⇄ list, with merged legend) ───────────────────────
  Widget _breakdownCard() {
    final bars = _chartBars();
    final listItems = _sortedListItems();
    if (bars.isEmpty && listItems.isEmpty) return const SizedBox.shrink();

    final chartTitle = _isLab
        ? 'Accuracy by drill'
        : _isNotes
            ? 'Accuracy by note'
            : module == 1
                ? 'Accuracy across all intervals'
                : 'Accuracy by chord quality';
    final chartSub = _isLab
        ? 'Each of the four Chord Lab exercises at a glance.'
        : _isNotes
            ? 'All twelve notes, C through B. Grey ones you have not tried yet.'
            : module == 1
                ? 'Every interval from minor 2nd to the octave.'
                : 'Weakest chord qualities on the left.';
    final listTitle = _isLab
        ? 'Every chord in the Lab'
        : 'Every $_itemNoun';
    final showingChart = _view == _BView.chart;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title on the left; the Chart / List toggle sits top-right on the
          // same row, right next to the heading.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _sectionTitle(
                  showingChart ? chartTitle : listTitle,
                  showingChart ? chartSub : _sortSub(),
                  big: true,
                ),
              ),
              const SizedBox(width: 10),
              _Segmented<_BView>(
                value: _view,
                options: const [
                  (_BView.chart, 'Chart'),
                  (_BView.list, 'List'),
                ],
                onChanged: (v) => setState(() => _view = v),
              ),
            ],
          ),
          // A sort control that appears in List mode.
          if (!showingChart) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: _sortButton()),
          ],
          const SizedBox(height: 16),
          if (showingChart)
            _BarChart(bars: bars)
          else
            ...listItems.map(_qualityRow),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          _legendFooter(),
        ],
      ),
    );
  }

  String _sortSub() {
    switch (_sort) {
      case _ListSort.weakest:
        return 'Weakest first, so your best practice targets are at the top.';
      case _ListSort.strongest:
        return 'Strongest first, so what you already own is at the top.';
      case _ListSort.mostPractised:
        return 'Most practised first.';
      case _ListSort.alpha:
        return 'In alphabetical order.';
    }
  }

  String _sortLabel(_ListSort s) => switch (s) {
        _ListSort.weakest => 'Weakest first',
        _ListSort.strongest => 'Strongest first',
        _ListSort.mostPractised => 'Most practised',
        _ListSort.alpha => 'A–Z',
      };

  Widget _sortButton() {
    return PopupMenuButton<_ListSort>(
      initialValue: _sort,
      onSelected: (s) => setState(() => _sort = s),
      color: const Color(0xFF242424),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final s in _ListSort.values)
          PopupMenuItem(
            value: s,
            height: 40,
            child: Row(
              children: [
                Icon(
                  s == _sort
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: s == _sort ? _cCoral : Colors.white38,
                ),
                const SizedBox(width: 10),
                Text(
                  _sortLabel(s),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 15, color: Colors.white54),
            const SizedBox(width: 5),
            Text(
              _sortLabel(_sort),
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chromatic note order for the Notes chart (all twelve always shown).
  static const List<String> _noteOrder = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  /// Bars for the chart: all 12 notes chromatically, all 12 intervals in pitch
  /// order, the 4 lab drills, or chord qualities weakest-first.
  List<_Bar> _chartBars() {
    if (_isNotes) {
      return [for (final n in _noteOrder) _Bar(n, data.byQuality[n])];
    }
    if (module == 1) {
      // All 12 intervals, unison excluded, in ascending semitone order.
      return [
        for (final iv in kIntervals)
          if (iv.semitones != 0) _Bar(iv.short, data.byQuality[iv.short]),
      ];
    }
    if (_isLab) {
      return _roundOrder
          .map((r) => _Bar(r.$2, data.byRound[r.$1]))
          .toList();
    }
    // Chords: practised qualities, weakest-first (matches the list order).
    return data.qualitiesWeakestFirst
        .map((e) => _Bar(_qualitySub(e.key), e.value))
        .toList();
  }

  // ── Split (all game types / all rounds, even untried) ───────────────────────
  Widget _splitSection() {
    final entries = _isLab ? _allRounds() : _allModes();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
      decoration: BoxDecoration(
        color: _cCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            _isLab ? 'By exercise' : 'By game type',
            _isLab
                ? 'All four Chord Lab drills. Grey ones you have not tried yet.'
                : _isNotes
                    ? 'Spotting a note you see vs. finding one from its name.'
                    : 'Naming a shape you see vs. building one from its name.',
          ),
          const SizedBox(height: 16),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _barRow(label: e.$1, entry: e.$2),
              )),
        ],
      ),
    );
  }

  // Every game type for this module, in a fixed order, even with no data.
  List<(String, StatEntry?)> _allModes() {
    final labels = _isNotes
        ? const [('find', 'Find the note'), ('identify', 'Identify the note')]
        : module == 1
            ? const [
                ('name', 'Name the interval'),
                ('build', 'Build the interval')
              ]
            : const [('name', 'Name the chord'), ('build', 'Build the chord')];
    return [for (final l in labels) (l.$2, data.byMode[l.$1])];
  }

  static const List<(String, String)> _roundOrder = [
    ('name', 'Name it'),
    ('complete', 'Complete it'),
    ('remove', 'Remove the extra'),
    ('build', 'Build it here'),
  ];

  List<(String, StatEntry?)> _allRounds() =>
      [for (final r in _roundOrder) (r.$2, data.byRound[r.$1])];

  Widget _barRow({required String label, required StatEntry? entry}) {
    final acc = entry?.accuracy ?? 0;
    final has = entry?.hasData ?? false;
    final color = _entryColor(entry);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: has ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (has) ...[
              Text(
                '${(acc * 100).round()}%',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry!.correct}/${entry.attempts}',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ] else
              Text(
                'Not tried',
                style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _AccBar(acc: acc, color: color, height: 9),
      ],
    );
  }

  // ── Full item list (user-sortable) ──────────────────────────────────────────
  List<MapEntry<String, StatEntry>> _sortedListItems() {
    // Base list is every practised item, weakest-first; re-sort per selection.
    final list = [...data.qualitiesWeakestFirst];
    switch (_sort) {
      case _ListSort.weakest:
        break; // already weakest-first
      case _ListSort.strongest:
        list.sort((a, b) => b.value.accuracy.compareTo(a.value.accuracy));
        break;
      case _ListSort.mostPractised:
        list.sort((a, b) => b.value.attempts.compareTo(a.value.attempts));
        break;
      case _ListSort.alpha:
        list.sort((a, b) => _qualityLabel(a.key)
            .toLowerCase()
            .compareTo(_qualityLabel(b.key).toLowerCase()));
        break;
    }
    return list;
  }

  Widget _qualityRow(MapEntry<String, StatEntry> e) {
    final acc = e.value.accuracy;
    final color = _entryColor(e.value);
    // No capsule — just a padded row with a hairline separator, so the list
    // doesn't read as tiles-within-a-tile.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _qualityLabel(e.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_qualitySub(e.key).isNotEmpty)
                  Text(
                    _qualitySub(e.key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _AccBar(acc: acc, color: color, height: 9)),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '${(acc * 100).round()}%',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              '${e.value.attempts}×',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bits ────────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, String sub, {bool big = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: big ? 15 : 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 11.5),
        ),
      ],
    );
  }

  Widget _legendFooter() {
    const items = [
      (_cStruggle, 'Shaky', 'under 50%'),
      (_cLearning, 'Learning', '50–69%'),
      (_cGood, 'Solid', '70–84%'),
      (_cMastered, 'Mastered', '85%+'),
      (_cNoData, 'Not tried', 'no data'),
    ];
    // Plain markers on a line — no box around them (avoids a tile-in-a-tile).
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: items
          .map((it) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration:
                        BoxDecoration(color: it.$1, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    it.$2,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    it.$3,
                    style: GoogleFonts.inter(
                        color: Colors.white30, fontSize: 10.5),
                  ),
                ],
              ))
          .toList(),
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────────────────

/// A compact pill segmented control used for the progress-range and the
/// chart/list switch. The selected segment gets a coral-tinted fill.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            GestureDetector(
              onTap: () => onChanged(o.$1),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: o.$1 == value
                      ? _cCoral.withValues(alpha: 0.20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: o.$1 == value
                        ? _cCoral.withValues(alpha: 0.55)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  o.$2,
                  style: GoogleFonts.inter(
                    color: o.$1 == value ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

/// A horizontally-scrollable vertical bar chart with gridlines at 25/50/75/100%.
class _BarChart extends StatelessWidget {
  const _BarChart({required this.bars});
  final List<_Bar> bars;

  static const double _chartH = 148; // plot area (0–100%)
  static const double _labelPad = 20; // headroom above the plot for value labels
  static const double _barW = 30;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final avail = c.maxWidth - 34; // 34 = y-axis gutter
      final contentW = bars.length * _barW + (bars.length - 1) * _gap;
      // If the bars fit, spread them across the width; otherwise scroll.
      final fits = contentW <= avail;
      final chart = _chart(fits ? avail : contentW, spread: fits);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _yAxis(),
          const SizedBox(width: 6),
          Expanded(
            child: fits
                ? chart
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: chart,
                  ),
          ),
        ],
      );
    });
  }

  Widget _yAxis() {
    Widget tick(String t) => Transform.translate(
          offset: const Offset(0, -5), // centre the label on its gridline
          child: Text(t,
              style: GoogleFonts.inter(color: Colors.white24, fontSize: 9)),
        );
    // Offset down by the label headroom so 100/…/0 line up with the plot.
    return Padding(
      padding: const EdgeInsets.only(top: _labelPad),
      child: SizedBox(
        width: 28,
        height: _chartH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            tick('100'),
            tick('75'),
            tick('50'),
            tick('25'),
            tick('0'),
          ],
        ),
      ),
    );
  }

  Widget _chart(double width, {required bool spread}) {
    final align =
        spread ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _chartH + _labelPad,
            width: width,
            child: Stack(
              children: [
                // Gridlines at 0/25/50/75/100% (plot area sits below the label
                // headroom).
                for (final f in const [0.0, 0.25, 0.5, 0.75, 1.0])
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _labelPad + _chartH * (1 - f) - 0.5,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: f == 0 ? 0.16 : 0.06),
                    ),
                  ),
                // Bars.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: align,
                  children: [
                    for (var i = 0; i < bars.length; i++) ...[
                      if (i > 0 && !spread) const SizedBox(width: _gap),
                      _bar(bars[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Labels row, aligned under the bars.
          Row(
            mainAxisAlignment: align,
            children: [
              for (var i = 0; i < bars.length; i++) ...[
                if (i > 0 && !spread) const SizedBox(width: _gap),
                SizedBox(
                  width: _barW,
                  child: Text(
                    bars[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(_Bar b) {
    final color = _entryColor(b.entry);
    final fillH = b.hasData ? (_chartH * b.acc).clamp(3.0, _chartH) : 3.0;
    // Column height = plot + label headroom; end-aligned so bars grow from the
    // 0% line and the value label rides just above the bar without overflowing.
    return SizedBox(
      width: _barW,
      height: _chartH + _labelPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (b.hasData)
            Text(
              '${(b.acc * 100).round()}',
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            width: _barW,
            height: fillH,
            decoration: BoxDecoration(
              color: b.hasData ? color : _cNoData.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress line chart ───────────────────────────────────────────────────────

/// A compact accuracy-over-time line + area chart (values 0..1, oldest → newest).
class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.points});
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: LayoutBuilder(
        builder: (_, c) => CustomPaint(
          size: Size(c.maxWidth, 140),
          painter: _ProgressPainter(points),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.points);
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 14.0, padBottom = 16.0, padLeft = 30.0, padRight = 8.0;
    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;

    // Gridlines + y labels at 0 / 50 / 100%.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = padTop + plotH * (1 - f);
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: '${(f * 100).round()}',
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padLeft - tp.width - 6, y - tp.height / 2));
    }

    if (points.length < 2) return;

    Offset at(int i) {
      final x = padLeft + plotW * (i / (points.length - 1));
      final y = padTop + plotH * (1 - points[i].clamp(0.0, 1.0));
      return Offset(x, y);
    }

    // Area fill under the line.
    final area = Path()..moveTo(at(0).dx, padTop + plotH);
    for (var i = 0; i < points.length; i++) {
      area.lineTo(at(i).dx, at(i).dy);
    }
    area.lineTo(at(points.length - 1).dx, padTop + plotH);
    area.close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _cCoral.withValues(alpha: 0.28),
            _cCoral.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(padLeft, padTop, plotW, plotH)),
    );

    // The line.
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _cCoral
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Points.
    final dot = Paint()..color = _cCoral;
    final dotInner = Paint()..color = const Color(0xFF1A1A1A);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(at(i), 3.2, dot);
      canvas.drawCircle(at(i), 1.3, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) => true;
}

// ── Accuracy bar ──────────────────────────────────────────────────────────────

class _AccBar extends StatelessWidget {
  const _AccBar({required this.acc, required this.color, this.height = 7});
  final double acc;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LayoutBuilder(
        builder: (_, c) => Stack(
          children: [
            Container(
                height: height, color: Colors.white.withValues(alpha: 0.08)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              height: height,
              width: (c.maxWidth * acc).clamp(acc > 0 ? 6.0 : 0.0, c.maxWidth),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Accuracy ring (custom-painted) ────────────────────────────────────────────

class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({
    required this.accuracy,
    required this.color,
    required this.size,
  });
  final double accuracy;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(accuracy: accuracy, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(accuracy * 100).round()}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                '%',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.accuracy, required this.color});
  final double accuracy;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.09;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, bg);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * accuracy.clamp(0.0, 1.0);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.accuracy != accuracy || old.color != color;
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.module, required this.noun});
  final int module;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final title = module == 0
        ? 'No note rounds yet'
        : module == 1
            ? 'No interval rounds yet'
            : module == 2
                ? 'No chord rounds yet'
                : 'No Chord Lab rounds yet';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cCoral.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.insights_rounded, color: _cCoral, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Play a few rounds and this screen fills in, showing which '
              '${noun}s you nail and which need more practice, so you always '
              'know what to work on next.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
