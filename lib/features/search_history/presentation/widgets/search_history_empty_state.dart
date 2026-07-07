import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';

class SearchHistoryEmptyState extends StatelessWidget {
  const SearchHistoryEmptyState({
    super.key,
    required this.hasFilters,
    this.onClearFilters,
    this.onRetry,
  });

  final bool hasFilters;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final message = hasFilters
        ? l10n.tOr('searchHistoryEmptyFiltered', 'No results match your filters')
        : l10n.tOr('searchHistoryEmpty', 'No search history found');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PromotionsSpace.xl,
          vertical: PromotionsSpace.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: PromotionsSpace.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: PromotionsSpace.sm),
            Text(
              l10n.tOr(
                'searchHistoryEmptyHint',
                'Recent user searches will appear here.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            if (hasFilters && onClearFilters != null) ...[
              const SizedBox(height: PromotionsSpace.lg),
              FilledButton.tonalIcon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: Text(l10n.tOr('searchHistoryClearFilters', 'Clear filters')),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: PromotionsSpace.sm),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.t('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
