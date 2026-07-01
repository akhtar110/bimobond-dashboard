import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../domain/entities/search_history.dart';
import '../utils/search_history_responsive.dart';

/// Compact KPI chips — content-sized width, wrap or scroll when space is tight.
class SearchHistoryOverviewCards extends StatelessWidget {
  const SearchHistoryOverviewCards({
    super.key,
    required this.overview,
    this.metrics,
  });

  final SearchHistoryOverviewEntity overview;
  final SearchHistoryLayoutMetrics? metrics;

  static const _stripHeight = 44.0;
  static const _defaultMaxTileWidth = 136.0;
  static const _wideMaxTileWidth = 192.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topQuery = overview.topQueryLabel ?? '—';
    final topQueryHint = overview.topQueries.isNotEmpty
        ? '${overview.topQueries.first.count} ${l10n.tOr('searchHistorySearches', 'searches')}'
        : null;

    final items = <_SearchHistoryKpiItem>[
      _SearchHistoryKpiItem(
        label: l10n.tOr('searchHistoryTotalSearches', 'Total searches'),
        value: _formatCount(overview.totalEntries),
        icon: Icons.manage_search_rounded,
      ),
      _SearchHistoryKpiItem(
        label: l10n.tOr('searchHistoryLast24h', 'Last 24 hours'),
        value: _formatCount(overview.entriesLast24Hours),
        icon: Icons.schedule_rounded,
      ),
      _SearchHistoryKpiItem(
        label: l10n.tOr('searchHistoryActiveUsers', 'Active users'),
        value: _formatCount(overview.usersWithHistory),
        icon: Icons.people_outline_rounded,
      ),
      _SearchHistoryKpiItem(
        label: l10n.tOr('searchHistoryTopQuery', 'Top query'),
        value: topQuery,
        icon: Icons.trending_up_rounded,
        tooltip: topQueryHint == null ? topQuery : '$topQuery · $topQueryHint',
        maxWidth: _wideMaxTileWidth,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = metrics?.filterGap ?? PromotionsSpace.sm;
        final useWrap = constraints.maxWidth < 720;

        if (useWrap) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                _CompactKpiTile(
                  item: item,
                  maxWidth: item.maxWidth ?? _defaultMaxTileWidth,
                ),
            ],
          );
        }

        return SizedBox(
          height: _stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  _CompactKpiTile(
                    item: items[i],
                    maxWidth: items[i].maxWidth ?? _defaultMaxTileWidth,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class SearchHistoryOverviewSkeleton extends StatelessWidget {
  const SearchHistoryOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const widths = [104.0, 112.0, 108.0, 128.0];

    return SizedBox(
      height: SearchHistoryOverviewCards._stripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < widths.length; i++) ...[
              if (i > 0) const SizedBox(width: PromotionsSpace.sm),
              Container(
                width: widths[i],
                height: SearchHistoryOverviewCards._stripHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchHistoryKpiItem {
  const _SearchHistoryKpiItem({
    required this.label,
    required this.value,
    required this.icon,
    this.tooltip,
    this.maxWidth,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? tooltip;
  final double? maxWidth;
}

class _CompactKpiTile extends StatelessWidget {
  const _CompactKpiTile({
    required this.item,
    required this.maxWidth,
  });

  final _SearchHistoryKpiItem item;
  final double maxWidth;

  static const _minTileWidth = 88.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tooltip = item.tooltip ?? item.label;

    return Tooltip(
      message: tooltip,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: _minTileWidth,
          maxWidth: maxWidth,
        ),
        child: Container(
          height: SearchHistoryOverviewCards._stripHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                    ),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
