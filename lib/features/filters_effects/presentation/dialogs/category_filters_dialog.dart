import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../domain/entities/filters_effects_entities.dart';

void showCategoryFiltersDialog(
  BuildContext context,
  CameraFilterCategoryEntity category,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => CategoryFiltersDialog(category: category),
  );
}

class CategoryFiltersDialog extends StatelessWidget {
  const CategoryFiltersDialog({
    super.key,
    required this.category,
  });

  final CameraFilterCategoryEntity category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filters = category.filters;

    return AlertDialog(
      title: Text(
        l10n.tOr('feCategoryFiltersTitle', 'Filters in category'),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              category.labelKey,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              category.slug,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (filters.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.tOr(
                    'feNoFiltersInCategory',
                    'No filters assigned to this category.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(filter.displayLabel),
                      subtitle: Text(filter.slug),
                      trailing: DashboardStatusChip(
                        label: filter.isActive
                            ? l10n.tOr('feActive', 'Active')
                            : l10n.tOr('feInactive', 'Inactive'),
                        tone: filter.isActive
                            ? DashboardStatusTone.success
                            : DashboardStatusTone.neutral,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
      ],
    );
  }
}
