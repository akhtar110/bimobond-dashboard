import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reports/presentation/utils/reports_responsive.dart';
import '../../../reports/presentation/widgets/reports_pagination_bar.dart';
import '../bloc/gift_reports_bloc.dart';

class GiftReportsPaginationBar extends StatelessWidget {
  const GiftReportsPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (!reportsUseDesktopPagination(MediaQuery.sizeOf(context).width)) {
      return const SizedBox.shrink();
    }

    return ReportsPaginationBar(
      page: currentPage,
      totalPages: lastPage,
      total: total,
      itemLabel: 'gifts',
      onPage: (page) =>
          context.read<GiftReportsBloc>().add(GoToGiftReportsPageEvent(page)),
    );
  }
}
