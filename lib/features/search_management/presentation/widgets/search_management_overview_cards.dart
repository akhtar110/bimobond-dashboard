import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../domain/entities/search_management_entities.dart';
import '../utils/search_management_responsive.dart';

/// Compact KPI chips — wraps on narrow widths, scrolls horizontally otherwise.
class SearchManagementOverviewCards extends StatelessWidget {
  const SearchManagementOverviewCards({
    super.key,
    required this.overview,
    this.metrics,
  });

  final SearchManagementOverviewEntity overview;
  final SearchManagementLayoutMetrics? metrics;

  static const stripHeight = 38.0;
  static const _defaultMaxTileWidth = 140.0;
  static const _wideMaxTileWidth = 176.0;
  static const _minTileWidth = 96.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final topQuery = overview.topQuery?.trim();
    final trendingValue = (topQuery != null && topQuery.isNotEmpty)
        ? topQuery
        : _format(overview.trendingCount);

    final items = <_KpiItem>[
      _KpiItem(
        label: l10n.tOr('searchMgmtTotalSearches', 'Total searches'),
        value: _format(overview.totalSearches),
        icon: Icons.manage_search_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('searchMgmtTotalUsers', 'Total users'),
        value: _format(overview.totalUsers),
        icon: Icons.people_outline_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('searchMgmtTotalPosts', 'Total posts'),
        value: _format(overview.totalPosts),
        icon: Icons.grid_view_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('searchMgmtTotalSounds', 'Total sounds'),
        value: _format(overview.totalSounds),
        icon: Icons.library_music_outlined,
      ),
      _KpiItem(
        label: l10n.tOr('searchMgmtTotalHashtags', 'Total hashtags'),
        value: _format(overview.totalHashtags),
        icon: Icons.tag_rounded,
      ),
      _KpiItem(
        label: l10n.tOr('searchMgmtTrending', 'Trending'),
        value: trendingValue,
        icon: Icons.trending_up_rounded,
        tooltip: topQuery == null
            ? null
            : '${l10n.tOr('searchMgmtTrending', 'Trending')}: $topQuery',
        maxWidth: _wideMaxTileWidth,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = metrics?.filterGap ?? PromotionsSpace.sm;
        final width = constraints.maxWidth;
        final useWrap = width < 900;

        if (useWrap) {
          // Prefer equal-width tiles in a grid when wrapping.
          final columns = width < 360
              ? 1
              : width < 520
                  ? 2
                  : width < 720
                      ? 3
                      : 3;
          final tileWidth =
              ((width - (gap * (columns - 1))) / columns).clamp(120.0, 220.0);

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: tileWidth,
                  child: _KpiTile(
                    item: item,
                    minWidth: tileWidth,
                    maxWidth: tileWidth,
                  ),
                ),
            ],
          );
        }

        return SizedBox(
          height: stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  _KpiTile(
                    item: items[i],
                    minWidth: _minTileWidth,
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

  String _format(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class SearchManagementOverviewSkeleton extends StatelessWidget {
  const SearchManagementOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const widths = [112.0, 108.0, 100.0, 112.0, 120.0, 132.0];

    return SizedBox(
      height: SearchManagementOverviewCards.stripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < widths.length; i++) ...[
              if (i > 0) const SizedBox(width: PromotionsSpace.sm),
              Container(
                width: widths[i],
                height: SearchManagementOverviewCards.stripHeight,
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

class _KpiItem {
  const _KpiItem({
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

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.item,
    required this.minWidth,
    required this.maxWidth,
  });

  final _KpiItem item;
  final double minWidth;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tooltip = item.tooltip ?? '${item.label}: ${item.value}';

    return Tooltip(
      message: tooltip,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: Container(
          height: SearchManagementOverviewCards.stripHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
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
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 1),
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
