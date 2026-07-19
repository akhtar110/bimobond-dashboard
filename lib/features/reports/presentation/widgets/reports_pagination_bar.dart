import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../utils/reports_responsive.dart';

/// Desktop pagination footer for reports screens.
///
/// Thin wrapper around [AppPaginationBar] so every reports tab shares the
/// same control strip. Mobile/tablet keep infinite scroll via
/// [ReportsLoadMoreFooter] + scroll listeners in each tab.
class ReportsPaginationBar extends StatelessWidget {
  const ReportsPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.itemLabel,
    required this.onPage,
    this.pageSize,
    this.itemCount,
    this.metrics,
    this.showTopBorder = true,
  });

  final int page;
  final int totalPages;
  final int total;
  final String itemLabel;
  final ValueChanged<int> onPage;

  /// Items per page. When omitted, derived from [total] / [totalPages].
  final int? pageSize;

  /// Items currently shown on this page (improves last-page end index).
  final int? itemCount;

  /// Kept for call-site compatibility; layout is handled by [AppPaginationBar].
  final ReportsLayoutMetrics? metrics;
  final bool showTopBorder;

  int get _resolvedPageSize {
    if (pageSize != null && pageSize! > 0) return pageSize!;
    if (totalPages > 0 && total > 0) {
      return math.max(1, (total / totalPages).ceil());
    }
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    // [itemLabel] is retained for API compatibility with existing call sites.
    assert(itemLabel.isNotEmpty);

    return AppPaginationBar(
      currentPage: page < 1 ? 1 : page,
      lastPage: totalPages < 1 ? 1 : totalPages,
      total: total,
      pageSize: _resolvedPageSize,
      itemCount: itemCount,
      hideWhenSinglePage: true,
      showTopBorder: showTopBorder,
      borderRadius: showTopBorder ? null : BorderRadius.circular(12),
      onPageChanged: onPage,
    );
  }
}

class ReportsLoadMoreFooter extends StatelessWidget {
  const ReportsLoadMoreFooter({
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
