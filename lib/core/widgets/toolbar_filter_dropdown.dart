import 'package:flutter/material.dart';

import 'toolbar_filter_style.dart';

/// Compact toolbar dropdown matching admin list filters (e.g. user locations).
class ToolbarFilterDropdown<T> extends StatelessWidget {
  const ToolbarFilterDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.height = ToolbarFilterStyle.controlHeight,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeValue = items.contains(value) ? value : null;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          borderRadius: ToolbarFilterStyle.radius,
          dropdownColor: scheme.surface,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          hint: Text(
            hint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    itemLabel(v),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
