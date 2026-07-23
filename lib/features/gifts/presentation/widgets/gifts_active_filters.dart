import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import 'gifts_filter_models.dart';

/// Removable chips summarizing the current draft selection.
class GiftsActiveFilters extends StatelessWidget {
  const GiftsActiveFilters({
    super.key,
    required this.items,
  });

  final List<GiftsActiveFilterItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tOr('giftActiveFilters', 'Active Filters'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                InputChip(
                  key: ValueKey(item.id),
                  label: Text(item.label),
                  onDeleted: item.onRemove,
                  deleteIconColor: scheme.onSecondaryContainer,
                  backgroundColor: scheme.secondaryContainer,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
