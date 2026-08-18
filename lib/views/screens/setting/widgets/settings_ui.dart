import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart' show JHGColors, LucideIcons;
import 'package:google_fonts/google_fonts.dart';

/// Local settings design primitives for the Fretboard Trainer app.
///
/// Shared with the Dictionaries app reference implementation so every
/// app's Settings feels like one design method: `#0F0F0F` page, `#1A1A1A`
/// grouped cards with a hairline white border, `#161616` nested panels,
/// circular neutral icon chips, Poppins titles + Inter meta, and the coral
/// accent reserved for active/focus states only.
class SettingsTokens {
  static const Color page = Color(0xFF0F0F0F);
  static const Color card = Color(0xFF1A1A1A);
  static const Color nested = Color(0xFF161616);
  static const Color chip = Color(0xFF2C2C2C);
  static const Color accent = JHGColors.primary;

  static Color get border => Colors.white.withValues(alpha: 0.08);
  static Color get hairline => Colors.white.withValues(alpha: 0.06);

  /// Info-description reveal — brisk but not snappy.
  static const Duration revealDuration = Duration(milliseconds: 200);

  /// Nested-panel / segment transitions — a touch slower so content settles.
  static const Duration panelDuration = Duration(milliseconds: 260);
}

/// Left inset that lines revealed text up with the title (chip 38 + gap 14).
const double _kTitleInset = 52;

/// Small caps label that heads each settings group.
class SettingsSectionLabel extends StatelessWidget {
  final String text;
  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.62),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

/// Rounded grouped container that holds a set of tiles.
class SettingsCard extends StatelessWidget {
  final Widget child;
  const SettingsCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettingsTokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SettingsTokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Inset panel used for the expanded sub-options under a switch or accordion.
class SettingsNestedCard extends StatelessWidget {
  final Widget child;
  const SettingsNestedCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SettingsTokens.nested,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SettingsTokens.hairline),
      ),
      child: child,
    );
  }
}

class SettingsNestedLabel extends StatelessWidget {
  final String text;
  const SettingsNestedLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }
}

/// Circular neutral leading chip. Colour stays neutral by default so coral is
/// kept for genuine focus points; pass [tint] to opt a single tile into accent.
class SettingsIconChip extends StatelessWidget {
  final IconData icon;
  final Color? tint;
  const SettingsIconChip({super.key, required this.icon, this.tint});

  @override
  Widget build(BuildContext context) {
    final c = tint;
    return Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: c == null
            ? Colors.white.withValues(alpha: 0.06)
            : c.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: c ?? Colors.white54, size: 18),
    );
  }
}

/// Horizontal segmented selector. The chosen segment wears a coral pill (a
/// genuine active-selection focus point); the rest stay quiet.
class SettingsSegmentSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const SettingsSegmentSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: SettingsTokens.border),
      ),
      child: Row(
        children: options.map((option) {
          final sel = option == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(option),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: sel ? SettingsTokens.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: sel ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Toggle row — icon chip + title (+info) + Cupertino switch (coral when on).
///
/// The subtitle is hidden by default and revealed under the title, animated,
/// when the info icon is tapped. The switch stays pinned to the title row so
/// nothing shifts vertically as the description opens.
class SettingsSwitchTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SettingsSwitchTile> createState() => _SettingsSwitchTileState();
}

class _SettingsSwitchTileState extends State<SettingsSwitchTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingsIconChip(icon: widget.icon),
              const SizedBox(width: 14),
              Expanded(
                child: _TitleWithInfo(
                  title: widget.title,
                  hasInfo: (widget.subtitle ?? '').isNotEmpty,
                  isOpen: _open,
                  onToggle: () => setState(() => _open = !_open),
                ),
              ),
              const SizedBox(width: 10),
              CupertinoSwitch(
                value: widget.value,
                activeTrackColor: SettingsTokens.accent,
                thumbColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
                onChanged: widget.onChanged,
              ),
            ],
          ),
          _DescriptionReveal(open: _open, text: widget.subtitle),
        ],
      ),
    );
  }
}

/// Tappable row with a trailing chevron (navigation / actions). Same info-icon
/// reveal for the optional subtitle.
class SettingsActionTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsActionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<SettingsActionTile> createState() => _SettingsActionTileState();
}

class _SettingsActionTileState extends State<SettingsActionTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsIconChip(icon: widget.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: _TitleWithInfo(
                    title: widget.title,
                    hasInfo: (widget.subtitle ?? '').isNotEmpty,
                    isOpen: _open,
                    onToggle: () => setState(() => _open = !_open),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.chevronRight,
                    color: Colors.white24, size: 18),
              ],
            ),
            _DescriptionReveal(open: _open, text: widget.subtitle),
          ],
        ),
      ),
    );
  }
}

/// Destructive row (e.g. Log Out) — wears the app coral.
class SettingsDestructiveTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SettingsDestructiveTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SettingsIconChip(icon: icon, tint: SettingsTokens.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: SettingsTokens.accent,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill dropdown matching the app's field styling. Built on [MenuAnchor] so the
/// menu opens directly *below* the field.
class SettingsDropdown extends StatefulWidget {
  final List<String> items;
  final String value;
  final void Function(String?) onChanged;

  const SettingsDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState();
}

class _SettingsDropdownState extends State<SettingsDropdown> {
  final MenuController _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 180.0;
        return MenuAnchor(
          controller: _menu,
          alignmentOffset: const Offset(0, 6),
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(SettingsTokens.chip),
            surfaceTintColor:
                const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(8),
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 6)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: SettingsTokens.border),
              ),
            ),
          ),
          menuChildren: [
            for (final item in widget.items)
              MenuItemButton(
                onPressed: () => widget.onChanged(item),
                style: ButtonStyle(
                  backgroundColor:
                      const WidgetStatePropertyAll(Colors.transparent),
                  overlayColor: WidgetStatePropertyAll(
                      Colors.white.withValues(alpha: 0.06)),
                  padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
                child: SizedBox(
                  width: width - 28,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            color: item == widget.value
                                ? SettingsTokens.accent
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: item == widget.value
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (item == widget.value)
                        const Icon(LucideIcons.check,
                            size: 15, color: SettingsTokens.accent),
                    ],
                  ),
                ),
              ),
          ],
          builder: (context, controller, _) {
            return GestureDetector(
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SettingsTokens.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronDown,
                        color: Colors.white54, size: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Leading-chip header with a title + info-reveal, but no switch/chevron — for
/// custom rows. Structured like the tiles so the title stays vertically centred
/// with the chip, and the description reveals beneath the whole row.
class SettingsInfoHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;

  const SettingsInfoHeader({
    super.key,
    required this.icon,
    required this.title,
    this.description,
  });

  @override
  State<SettingsInfoHeader> createState() => _SettingsInfoHeaderState();
}

class _SettingsInfoHeaderState extends State<SettingsInfoHeader> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SettingsIconChip(icon: widget.icon),
            const SizedBox(width: 14),
            Expanded(
              child: _TitleWithInfo(
                title: widget.title,
                hasInfo: (widget.description ?? '').isNotEmpty,
                isOpen: _open,
                onToggle: () => setState(() => _open = !_open),
              ),
            ),
          ],
        ),
        _DescriptionReveal(open: _open, text: widget.description),
      ],
    );
  }
}

/// Title text with an optional trailing info "i" chip. Tapping the chip calls
/// [onToggle]; the chip picks up the coral accent while open to signal it.
class _TitleWithInfo extends StatelessWidget {
  final String title;
  final bool hasInfo;
  final bool isOpen;
  final VoidCallback onToggle;

  const _TitleWithInfo({
    required this.title,
    required this.hasInfo,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (hasInfo) ...[
          const SizedBox(width: 7),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: SettingsTokens.revealDuration,
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: isOpen
                    ? SettingsTokens.accent.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.info,
                size: 11,
                color: isOpen ? SettingsTokens.accent : Colors.white54,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated description that opens beneath a title. Collapsed it has zero
/// height, so revealing it never nudges the row above — only the content below
/// slides down, smoothly, via [AnimatedSize].
class _DescriptionReveal extends StatelessWidget {
  final bool open;
  final String? text;
  const _DescriptionReveal({required this.open, this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: SettingsTokens.revealDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: (open && (text ?? '').isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.only(left: _kTitleInset, top: 8),
              child: Text(
                text!,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
