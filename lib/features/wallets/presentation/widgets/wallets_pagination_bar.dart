import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../utils/wallets_responsive.dart';

/// Desktop pagination footer for wallet listing screens.
///
/// Thin wrapper around [AppPaginationBar]. Mobile/tablet keep infinite scroll
/// via existing load-more indicators on each page.
class WalletsPaginationBar extends StatelessWidget {
  const WalletsPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPage,
    this.pageSize,
    this.itemCount,
    this.showTopBorder = false,
  });

  final int page;
  final int totalPages;
  final int total;
  final ValueChanged<int> onPage;
  final int? pageSize;
  final int? itemCount;
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
    final m = walletsMetricsOf(context);
    if (!m.useDesktopPagination) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: m.isMobile ? m.pageHorizontalPadding : 0,
        vertical: m.isMobile ? 4 : 0,
      ),
      child: AppPaginationBar(
        currentPage: page < 1 ? 1 : page,
        lastPage: totalPages < 1 ? 1 : totalPages,
        total: total,
        pageSize: _resolvedPageSize,
        itemCount: itemCount,
        hideWhenSinglePage: false,
        showTopBorder: showTopBorder,
        borderRadius: showTopBorder ? null : BorderRadius.circular(12),
        onPageChanged: onPage,
      ),
    );
  }
}
