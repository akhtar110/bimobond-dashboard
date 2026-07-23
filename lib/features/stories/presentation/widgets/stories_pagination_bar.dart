import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';

class StoriesPaginationBar extends StatelessWidget {
  const StoriesPaginationBar({
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
    return AppPaginationBar(
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      pageSize: StoriesBloc.defaultPageLimit,
      itemCount: itemCount,
      borderRadius: BorderRadius.circular(12),
      onPageChanged: (page) =>
          context.read<StoriesBloc>().add(ChangePageEvent(page)),
    );
  }
}
