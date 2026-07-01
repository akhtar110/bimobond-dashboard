import 'package:flutter/material.dart';

import '../../domain/enums/posts_view_type.dart';
import '../bloc/posts_bloc.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import 'posts_grid_view.dart';
import 'posts_list_view.dart';

class PostsContent extends StatelessWidget {
  const PostsContent({
    required this.state,
    required this.scrollController,
    required this.onPostTap,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: state.viewType == PostsViewType.grid
          ? PostsGridView(
              key: const ValueKey('posts_grid'),
              state: state,
              scrollController: scrollController,
              onPostTap: onPostTap,
            )
          : PostsListView(
              key: const ValueKey('posts_list'),
              state: state,
              scrollController: scrollController,
              onPostTap: onPostTap,
            ),
    );
  }
}
