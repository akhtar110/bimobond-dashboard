import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';

/// Counts popup filters only (excludes search — search stays on the bar).
int postsAppliedFilterCount(PostFilters filters) {
  var count = 0;
  if (filters.type != null && filters.type!.isNotEmpty) count++;
  if (filters.sort != null && filters.sort != PostFilters.defaultSort) count++;
  if (filters.isAuctionable == true) count++;
  if (filters.isAd == true) count++;
  return count;
}

/// Modern filter trigger with optional active-count badge.
/// Hover is handled by [Material]/[InkWell] — no setState.
class PostsFilterButton extends StatelessWidget {
  const PostsFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
    this.height = 40,
  });

  final int activeCount;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasActive = activeCount > 0;
    final label = hasActive
        ? l10n
            .tOr('giftFiltersWithCount', 'Filters ({count})')
            .replaceAll('{count}', '$activeCount')
        : l10n.tOr('filters', 'Filters');

    final bg =
        hasActive ? scheme.primaryContainer : scheme.surfaceContainerLow;
    final fg = hasActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final border = hasActive
        ? scheme.primary
        : scheme.outline.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.18,
          );

    return Tooltip(
      message: l10n.tOr('giftOpenFiltersTooltip', 'Open filters'),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          hoverColor: hasActive
              ? scheme.primary.withValues(alpha: 0.08)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                if (hasActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activeCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
