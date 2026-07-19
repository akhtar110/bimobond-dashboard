import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../bloc/users_bloc.dart';

/// Users-screen adapter around the shared [AppPaginationBar].
class UsersPaginationBar extends StatelessWidget {
  const UsersPaginationBar({
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
      pageSize: UsersBloc.pageLimit,
      itemCount: itemCount,
      showTopBorder: true,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      onPageChanged: (page) =>
          context.read<UsersBloc>().add(GoToUsersPageEvent(page)),
    );
  }
}
