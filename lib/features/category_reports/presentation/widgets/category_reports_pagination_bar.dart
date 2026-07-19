import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reports/presentation/utils/reports_responsive.dart';
import '../../../reports/presentation/widgets/reports_pagination_bar.dart';
import '../bloc/category_reports_bloc.dart';

class CategoryReportsPaginationBar extends StatelessWidget {
  const CategoryReportsPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.itemCount,
  });

  final int currentPage;
  final int lastPage;
  final int total;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    if (!reportsUseDesktopPagination(MediaQuery.sizeOf(context).width)) {
      return const SizedBox.shrink();
    }

    return ReportsPaginationBar(
      page: currentPage,
      totalPages: lastPage,
      total: total,
      pageSize: 20,
      itemCount: itemCount,
      itemLabel: 'categories',
      onPage: (page) => context
          .read<CategoryReportsBloc>()
          .add(GoToCategoryReportsPageEvent(page)),
    );
  }
}
