import 'package:flutter/material.dart';

import '../utils/promotions_responsive.dart';

class PromotionsPaginationBar extends StatelessWidget {
  const PromotionsPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
    this.metrics,
    this.showTopBorder = false,
  });

  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPage;
  final PromotionsLayoutMetrics? metrics;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    if (!promotionsMetricsOf(context).useDesktopPagination) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final m = metrics ??
        promotionsMetricsOf(context);
    final compact = m.isMobile;

    final summary = compact
        ? 'Page $page / $totalPages'
        : '$total total · Page $page of $totalPages';

    final visiblePages = <int>{
      for (var i = page - 2; i <= page + 2; i++)
        if (i >= 1 && i <= totalPages) i,
    };

    Widget navIcon({
      required IconData icon,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: enabled
                    ? scheme.outlineVariant
                    : scheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: enabled
                  ? scheme.primary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }

    Widget pageButton(int p) {
      final isActive = p == page;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPage(p),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.8),
                      ],
                    )
                  : null,
              color: isActive ? null : scheme.surface,
              border: Border.all(
                color: isActive ? Colors.transparent : scheme.outlineVariant,
              ),
            ),
            child: Text(
              '$p',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    final pageControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        navIcon(
          icon: Icons.chevron_left_rounded,
          enabled: page > 1,
          onTap: () => onPage(page - 1),
        ),
        const SizedBox(width: 4),
        if (m.useDesktopPagination)
          for (final p in visiblePages) ...[
            pageButton(p),
            const SizedBox(width: 4),
          ]
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$page/$totalPages',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        navIcon(
          icon: Icons.chevron_right_rounded,
          enabled: page < totalPages,
          onTap: () => onPage(page + 1),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? m.pageHorizontalPadding : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: showTopBorder
          ? BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            )
          : null,
      child: compact
          ? Column(
              children: [
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
                SizedBox(height: m.toolbarFilterGap),
                pageControls,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                pageControls,
              ],
            ),
    );
  }
}

class PromotionsLoadMoreFooter extends StatelessWidget {
  const PromotionsLoadMoreFooter({
    super.key,
    this.isLoading = false,
    this.hasReachedMax = false,
    this.total,
  });

  final bool isLoading;
  final bool hasReachedMax;
  final int? total;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (hasReachedMax && total != null && total! > 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            '$total total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}
