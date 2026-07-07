import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../auction_reports/presentation/bloc/auction_report_detail_bloc.dart';
import '../../../auction_reports/presentation/pages/auction_report_detail_page.dart';
import '../../../category_reports/presentation/pages/category_report_detail_page.dart';
import '../../../gift_reports/presentation/pages/gift_report_detail_page.dart';
import '../../../post_reports/presentation/bloc/post_report_detail_bloc.dart';
import '../../../post_reports/presentation/pages/post_report_detail_page.dart';
import '../../../user_reports/presentation/bloc/user_reports_bloc.dart';
import '../../../user_reports/presentation/pages/user_report_detail_page.dart';
import '../reports_inline_detail.dart';

class ReportsInlineDetailPanel extends StatelessWidget {
  const ReportsInlineDetailPanel({
    super.key,
    required this.detail,
    required this.onClose,
    this.userReportsBloc,
  });

  final ReportsInlineDetail detail;
  final VoidCallback onClose;
  final UserReportsBloc? userReportsBloc;

  @override
  Widget build(BuildContext context) {
    return switch (detail) {
      UserReportsInlineDetail(:final userId) => BlocProvider.value(
          value: userReportsBloc ?? di.sl<UserReportsBloc>(),
          child: UserReportDetailPage(
            userId: userId,
            onClose: onClose,
          ),
        ),
      PostReportsInlineDetail(:final postId) => BlocProvider(
          create: (_) => di.sl<PostReportDetailBloc>(),
          child: PostReportDetailPage(
            postId: postId,
            onClose: onClose,
          ),
        ),
      AuctionReportsInlineDetail(:final auctionId) => BlocProvider(
          create: (_) => di.sl<AuctionReportDetailBloc>(),
          child: AuctionReportDetailPage(
            auctionId: auctionId,
            onClose: onClose,
          ),
        ),
      GiftReportsInlineDetail(:final giftId) => GiftReportDetailPage(
          giftId: giftId,
          onClose: onClose,
        ),
      CategoryReportsInlineDetail(:final categoryId) =>
        CategoryReportDetailPage(
          categoryId: categoryId,
          onClose: onClose,
        ),
    };
  }
}
