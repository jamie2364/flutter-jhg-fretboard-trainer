import 'package:flutter/material.dart';
import 'package:flutter_jhg_elements/jhg_elements.dart';

class ExpansionPanelDropdown<T> extends StatefulWidget {
  final String? label;
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;

  const ExpansionPanelDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<ExpansionPanelDropdown<T>> createState() =>
      _ExpansionPanelDropdownState<T>();
}

class _ExpansionPanelDropdownState<T> extends State<ExpansionPanelDropdown<T>> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(12),
      child: ExpansionPanelList(
        elevation: 0,
        animationDuration: Duration(milliseconds: 250),
        children: [
          ExpansionPanel(
            isExpanded: _expanded,
            headerBuilder: (_, __) {
              return ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12)),
                onTap: () => setState(() => _expanded = !_expanded),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.label != null) Text(widget.label!),
                    Text(
                      widget.value.toString(),
                      // style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
            body: Column(
              children: widget.items.map((item) {
                final isSelected = item == widget.value;
                return ListTile(
                  tileColor: isSelected
                      ? JHGColors.primary.withValues(alpha: 0.5)
                      : null,
                  title: Text(
                    item.toString(),
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () async {
                    setState(() => _expanded = false); // auto close
                    await Future.delayed(Duration(milliseconds: 350));
                    widget.onChanged(item);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
