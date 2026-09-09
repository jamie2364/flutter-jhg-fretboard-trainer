// views/screens/widgets/multi_select_dropdown.dart
//
// A multi-select dropdown that mirrors the dictionaries / drills tonality
// picker (anchored overlay menu, search field, scrollable list) but lets the
// user tick several options instead of one. Collapsed it shows a summary
// ("All (13)" / "3 selected"); tapped it floats a menu with a search box, a
// Select-all / Clear row, and a checkbox list. Reused by the customize-session
// Intervals step (and, later, the Chord Lab key / tonality steps).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kPrimary = Color(0xFFFE5D43);
const _kOnSurface = Color(0xFFF1F1F1);
const _kMuted = Color(0xFF8A8A8A);
const _kMenuBg = Color(0xFF1E1E1E);

class MultiSelectOption {
  const MultiSelectOption(this.value, this.label, {this.subtitle});
  final String value;
  final String label;
  final String? subtitle;
}

class MultiSelectDropdown extends StatefulWidget {
  const MultiSelectDropdown({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.allLabel,
    this.noun = 'selected',
    this.searchHint = 'Search…',
  });

  final List<MultiSelectOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Shown collapsed when every option is ticked, e.g. "All intervals".
  final String allLabel;

  /// Word used in the "N <noun>" summary, e.g. "selected".
  final String noun;
  final String searchHint;

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _open = false;
  double _triggerWidth = 0;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleMenu() => _open ? _close() : _openMenu();

  void _openMenu() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    _triggerWidth = box?.size.width ?? 0;
    setState(() {
      _open = true;
      _query = '';
      _searchCtrl.clear();
    });
    _portal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open) _searchFocus.requestFocus();
    });
  }

  void _close() {
    if (!_open) return;
    _searchFocus.unfocus();
    setState(() => _open = false);
    _portal.hide();
  }

  void _toggleValue(String value) {
    final next = {...widget.selected};
    if (next.contains(value)) {
      if (next.length == 1) return; // keep at least one ticked
      next.remove(value);
    } else {
      next.add(value);
    }
    widget.onChanged(next);
  }

  void _selectAll() =>
      widget.onChanged({for (final o in widget.options) o.value});

  void _clear() {
    // Clearing to nothing is invalid; leave just the first option ticked.
    if (widget.options.isEmpty) return;
    widget.onChanged({widget.options.first.value});
  }

  List<MultiSelectOption> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where((o) => o.label.toLowerCase().contains(q))
        .toList();
  }

  String get _summary {
    final n = widget.selected.length;
    if (n >= widget.options.length) return widget.allLabel;
    return '$n ${widget.noun}';
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 12),
              child: SizedBox(width: _triggerWidth, child: _buildMenu()),
            ),
          ],
        ),
        child: KeyedSubtree(key: _triggerKey, child: _buildTrigger()),
      ),
    );
  }

  Widget _buildTrigger() {
    return GestureDetector(
      onTap: _toggleMenu,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _open
                ? _kPrimary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
            width: _open ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _summary,
                style: GoogleFonts.poppins(
                  color: _kOnSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              _open
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final filtered = _filtered;
    return Material(
      color: Colors.transparent,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _kMenuBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 34,
              spreadRadius: -6,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Colors.white38, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.inter(
                            color: _kOnSurface, fontSize: 14),
                        cursorColor: _kPrimary,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: widget.searchHint,
                          hintStyle: GoogleFonts.inter(
                              color: Colors.white30, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Select all / Clear.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _miniAction('Select all', _selectAll),
                  const SizedBox(width: 8),
                  _miniAction('Clear', _clear),
                  const Spacer(),
                  Text(
                    _summary,
                    style: GoogleFonts.inter(
                        color: _kMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            // Scrollable checkbox list.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('No matches',
                            style: GoogleFonts.inter(
                                color: Colors.white38, fontSize: 13)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final o = filtered[i];
                          final on = widget.selected.contains(o.value);
                          return InkWell(
                            onTap: () => _toggleValue(o.value),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  _checkbox(on),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      o.label,
                                      style: GoogleFonts.poppins(
                                        color: on ? _kOnSurface : Colors.white70,
                                        fontSize: 15,
                                        fontWeight: on
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (o.subtitle != null)
                                    Text(
                                      o.subtitle!,
                                      style: GoogleFonts.inter(
                                          color: Colors.white38, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniAction(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
                color: _kOnSurface, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );

  Widget _checkbox(bool on) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: on ? _kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: on ? _kPrimary : Colors.white.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: on
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
            : null,
      );
}
