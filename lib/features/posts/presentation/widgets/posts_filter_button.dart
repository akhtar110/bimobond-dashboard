import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';

/// Counts popup filters (excludes search).
int postsAppliedFilterCount(PostFilters filters) {
  var count = 0;
  if (filters.categoryId != null) count++;
  if (filters.type != null && filters.type!.isNotEmpty) count++;
  if (filters.hasLocationFilter) count++;
  if (filters.sort != null &&
      filters.sort != PostFilters.defaultSort) {
    count++;
  }
  if (filters.isAuctionable == true) count++;
  if (filters.isAd == true) count++;
  if (filters.userId != null) count++;
  if (filters.hasDateTimeFilters) count++;
  return count;
}

/// Minimal filter trigger — icon-first with optional count badge.
class PostsFilterButton extends StatelessWidget {
  const PostsFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
    this.height = 36,
    this.iconOnly = true,
  });

  final int activeCount;
  final VoidCallback onPressed;
  final double height;
  final bool iconOnly;

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

    final bg = hasActive
        ? scheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    final fg = hasActive ? scheme.primary : scheme.onSurfaceVariant;
    final border = hasActive
        ? scheme.primary.withValues(alpha: 0.35)
        : scheme.outline.withValues(alpha: 0.22);

    final child = iconOnly
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.tune_rounded, size: 18, color: fg),
              if (hasActive)
                PositionedDirectional(
                  top: -4,
                  end: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                    child: Text(
                      activeCount > 9 ? '9+' : '$activeCount',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimary,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          );

    return Tooltip(
      message: l10n.tOr('giftOpenFiltersTooltip', 'Open filters'),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          hoverColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: Container(
            height: height,
            width: iconOnly ? height : null,
            padding: iconOnly
                ? null
                : const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
