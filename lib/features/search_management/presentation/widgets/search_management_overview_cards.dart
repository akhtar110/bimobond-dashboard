import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../domain/entities/search_management_entities.dart';
import '../utils/search_management_responsive.dart';

/// Compact KPI chips — always one horizontal strip on small/medium widths
/// so they do not steal vertical space from the content tabs.
class SearchManagementOverviewCards extends StatelessWidget {
  const SearchManagementOverviewCards({
    super.key,
    required this.overview,
    this.metrics,
  });

  final SearchManagementOverviewEntity overview;
  final SearchManagementLayoutMetrics? metrics;

  static const stripHeight = 38.0;
  static const stripHeightCompact = 34.0;
  static const _defaultMaxTileWidth = 140.0;
  static const _wideMaxTileWidth = 176.0;
  static const _minTileWidth = 96.0;
  static const _compactMinTileWidth = 88.0;
  static const _compactMaxTileWidth = 128.0;

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
        final compact = width < 700;
        final height = compact ? stripHeightCompact : stripHeight;
        final minW = compact ? _compactMinTileWidth : _minTileWidth;
        final maxW = compact ? _compactMaxTileWidth : _defaultMaxTileWidth;

        // One horizontal strip on every breakpoint — avoids multi-row Wrap
        // eating vertical space on phones/tablets.
        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(width: gap),
            itemBuilder: (context, i) {
              final item = items[i];
              return _KpiTile(
                item: item,
                height: height,
                compact: compact,
                minWidth: minW,
                maxWidth: item.maxWidth != null
                    ? (compact
                        ? (item.maxWidth! * 0.85).clamp(minW, 148.0)
                        : item.maxWidth!)
                    : maxW,
              );
            },
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final height = compact
        ? SearchManagementOverviewCards.stripHeightCompact
        : SearchManagementOverviewCards.stripHeight;
    final widths = compact
        ? const [88.0, 84.0, 80.0, 88.0, 92.0, 104.0]
        : const [112.0, 108.0, 100.0, 112.0, 120.0, 132.0];

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widths.length,
        separatorBuilder: (_, _) => const SizedBox(width: PromotionsSpace.sm),
        itemBuilder: (context, i) => Container(
          width: widths[i],
          height: height,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
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
    required this.height,
    this.compact = false,
  });

  final _KpiItem item;
  final double minWidth;
  final double maxWidth;
  final double height;
  final bool compact;

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
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: compact ? 13 : 14,
                color: scheme.primary,
              ),
              SizedBox(width: compact ? 5 : 6),
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
                            fontSize: compact ? 12 : 13,
                          ),
                    ),
                    SizedBox(height: compact ? 0 : 1),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: compact ? 9 : 10,
                            height: 1.05,
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
