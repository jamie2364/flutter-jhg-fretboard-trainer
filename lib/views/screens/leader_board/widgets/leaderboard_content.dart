import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single leaderboard row, decoupled from any app's data model so the exact
/// same podium + list UI can be dropped into every JHG app.
class LbEntry {
  final String name;
  final String score;
  final bool isMe;
  const LbEntry(this.name, this.score, {this.isMe = false});
}

/// Medal palette shared across the suite. Gold / silver / bronze for ranks 1-3.
const Color kGold = Color(0xFFD4AF37); // metallic gold (richer, less yellow)
const Color kSilver = Color(0xFFC4CAD4);
const Color kBronze = Color(0xFFD98A4E);

Color _medalColor(int rank) =>
    rank == 1 ? kGold : (rank == 2 ? kSilver : kBronze);

String _initials(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final parts = t.split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[1].isNotEmpty) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return t.substring(0, t.length >= 2 ? 2 : 1).toUpperCase();
}

/// Modern, minimalist leaderboard: a gold/silver/bronze podium for the top three
/// and a clean ranked list for everyone else. [primary] is the app's accent so
/// the component matches each app while staying visually identical.
class LeaderboardContent extends StatelessWidget {
  const LeaderboardContent({
    super.key,
    required this.entries,
    required this.onRefresh,
    this.primary = const Color(0xFFFE5D43),
    this.scoreLabel = 'SCORE',
    this.refreshLabel = 'Refresh',
  });

  final List<LbEntry> entries;
  final VoidCallback onRefresh;
  final Color primary;
  final String scoreLabel;
  final String refreshLabel;

  static const Color _surface = Color(0xFF161616);
  static const Color _border = Color(0x14FFFFFF);

  @override
  Widget build(BuildContext context) {
    final top = entries.take(3).toList();
    final rest = entries.length > 3 ? entries.sublist(3) : const <LbEntry>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top.isNotEmpty) _Podium(top: top),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 26),
          _RankList(entries: rest, startRank: 4, scoreLabel: scoreLabel),
        ],
        const SizedBox(height: 24),
        _RefreshButton(label: refreshLabel, onTap: onRefresh),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Top-three podium. Rendered 2nd–1st–3rd so the winner sits centre and tallest.
class _Podium extends StatelessWidget {
  const _Podium({required this.top});
  final List<LbEntry> top;

  @override
  Widget build(BuildContext context) {
    LbEntry? at(int i) => i < top.length ? top[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumColumn(entry: at(1), rank: 2)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumColumn(entry: at(0), rank: 1)),
        const SizedBox(width: 10),
        Expanded(child: _PodiumColumn(entry: at(2), rank: 3)),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({required this.entry, required this.rank});
  final LbEntry? entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    // Empty slot (e.g. only two players): keep the column so the winner stays
    // centred, but render nothing.
    if (entry == null) return const SizedBox.shrink();

    final medal = _medalColor(rank);
    final isFirst = rank == 1;
    final double avatar = isFirst ? 64 : 52;
    final double pedestal = isFirst ? 92 : (rank == 2 ? 66 : 50);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Icon(LucideIcons.crown, color: medal, size: 18),
          ),
        // Avatar with a medal-coloured ring and a rank badge.
        SizedBox(
          width: avatar + 10,
          height: avatar + 10,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: avatar,
                height: avatar,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medal.withValues(alpha: 0.14),
                  border: Border.all(color: medal, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(entry!.name),
                  style: GoogleFonts.poppins(
                    color: medal,
                    fontSize: isFirst ? 20 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: medal,
                    border: Border.all(color: const Color(0xFF0F0F0F), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F0F0F),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry!.score,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: medal,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        // Pedestal block, height ranked by position.
        Container(
          height: pedestal,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [medal.withValues(alpha: 0.22), medal.withValues(alpha: 0.04)],
            ),
            border: Border(top: BorderSide(color: medal, width: 2.5)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: GoogleFonts.poppins(
              color: medal.withValues(alpha: 0.5),
              fontSize: isFirst ? 34 : 26,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Clean ranked list for positions 4+.
class _RankList extends StatelessWidget {
  const _RankList({
    required this.entries,
    required this.startRank,
    required this.scoreLabel,
  });
  final List<LbEntry> entries;
  final int startRank;
  final String scoreLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _colHeader('RANK'),
              _colHeader(scoreLabel),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: LeaderboardContent._surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LeaderboardContent._border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, thickness: 1, color: Color(0x0DFFFFFF)),
                _RankRow(entry: entries[i], rank: startRank + i),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget _colHeader(String text) => Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      );
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.rank});
  final LbEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isMe;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: highlight
          ? const BoxDecoration(color: Color(0x12FE5D43))
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$rank',
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.score,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: LeaderboardContent._surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LeaderboardContent._border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.refreshCw,
                  color: Colors.white54, size: 15),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
