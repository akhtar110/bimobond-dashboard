import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Banner shown when a filter/effect category chip is selected.
class FeSelectedCategoryBanner extends StatelessWidget {
  const FeSelectedCategoryBanner({
    super.key,
    required this.label,
    required this.itemCount,
    required this.isEffectCategory,
    required this.onClear,
  });

  final String label;
  final int itemCount;
  final bool isEffectCategory;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final countLabel = isEffectCategory
        ? l10n.tOr('feCategoryEffectsCount', '{count} effects')
            .replaceAll('{count}', '$itemCount')
        : l10n.tOr('feCategoryFiltersCount', '{count} filters')
            .replaceAll('{count}', '$itemCount');

    return Material(
      color: scheme.secondaryContainer.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              Icons.folder_special_rounded,
              size: 20,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(l10n.tOr('feShowAll', 'Show all')),
            ),
          ],
        ),
      ),
    );
  }
}
