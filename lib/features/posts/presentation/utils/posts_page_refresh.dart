import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../stories/presentation/bloc/stories_bloc.dart';
import '../../../stories/presentation/bloc/stories_event.dart';
import '../bloc/posts_bloc.dart';

/// Posts dashboard tab index inside [_DashboardTabStack].
const int postsDashboardTabIndex = 4;

/// Refreshes the posts feed and active stories strip together.
void refreshPostsPageFeed(BuildContext context) {
  context.read<PostsBloc>().add(GetAllPostsEvent());
  context.read<StoriesBloc>().add(const RefreshActiveStoriesEvent());
}

/// Notifies the mounted [PostsPage] to refresh when the dashboard tab is re-selected.
abstract final class PostsPageRefreshScope {
  static VoidCallback? _listener;

  static void register(VoidCallback listener) {
    _listener = listener;
  }

  static void unregister(VoidCallback listener) {
    if (_listener == listener) {
      _listener = null;
    }
  }

  static void notify() {
    _listener?.call();
  }
}
