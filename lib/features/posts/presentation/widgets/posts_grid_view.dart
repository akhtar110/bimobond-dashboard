import 'package:flutter/material.dart';

import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_grouped_cache.dart';
import 'grouped_posts_grid.dart';

class PostsGridView extends StatefulWidget {
  const PostsGridView({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onPostTap,
    this.useInfiniteScroll = true,
  });

  final PostsLoaded state;
  final ScrollController scrollController;
  final void Function(ManagedPostEntity) onPostTap;
  final bool useInfiniteScroll;

  @override
  State<PostsGridView> createState() => _PostsGridViewState();
}

class _PostsGridViewState extends State<PostsGridView> {
  final _groupCache = PostsGroupedCache();

  @override
  Widget build(BuildContext context) {
    final groups = _groupCache.resolve(widget.state.posts);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GroupedPostsGrid(
          groups: groups,
          state: widget.state,
          scrollController: widget.scrollController,
          onPostTap: widget.onPostTap,
          useInfiniteScroll: widget.useInfiniteScroll,
          viewportWidth: constraints.maxWidth,
        );
      },
    );
  }
}
