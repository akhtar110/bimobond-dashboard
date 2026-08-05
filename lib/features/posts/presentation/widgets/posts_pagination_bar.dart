import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../bloc/posts_bloc.dart';

/// Posts-screen adapter around the shared [AppPaginationBar].
class PostsPaginationBar extends StatelessWidget {
  const PostsPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.pageSize = PostsBloc.pageLimit,
    this.itemCount,
  });

  final int currentPage;
  final int lastPage;
  final int total;
  final int pageSize;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    return AppPaginationBar(
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      pageSize: pageSize,
      itemCount: itemCount,
      showBorder: false,
      borderRadius: BorderRadius.circular(12),
      onPageChanged: (page) =>
          context.read<PostsBloc>().add(GoToPostsPageEvent(page)),
    );
  }
}
