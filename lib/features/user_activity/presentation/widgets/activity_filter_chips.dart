import 'package:flutter/material.dart';

class ActivityFilterChips extends StatelessWidget {
  const ActivityFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.isDark,
  });

  final List<({String value, String label})> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: FilterChip(
            label: Text(opt.label),
            selected: isSelected,
            onSelected: (_) => onSelected(opt.value),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
            backgroundColor: scheme.surfaceContainerHigh,
            selectedColor: scheme.primary,
            side: BorderSide(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }).toList(),
    );
  }
}
