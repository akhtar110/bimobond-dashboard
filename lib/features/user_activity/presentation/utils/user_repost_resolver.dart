import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/domain/entities/user_entity.dart';
import '../../data/models/user_repost_model.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../../domain/entities/user_repost_entity.dart';
import '../bloc/user_activity_bloc.dart';

UserRepostEntity? findRepostInList(
  List<UserRepostEntity> reposts,
  UserActivityItemEntity item,
) {
  for (final repost in reposts) {
    if (repost.repostId == item.id) return repost;
  }

  final postId = item.detailString('postId');
  if (postId == null || postId.isEmpty) return null;

  for (final repost in reposts) {
    if (repost.post.id != postId) continue;
    final repostedAt = repost.repostedAt;
    if (repostedAt == null) return repost;
    if (repostedAt.difference(item.createdAt).inMinutes.abs() <= 2) {
      return repost;
    }
  }

  for (final repost in reposts) {
    if (repost.post.id == postId) return repost;
  }

  return null;
}

/// Resolves a full [UserRepostEntity] for an activity feed item, preferring
/// cached repost list data when available.
Future<UserRepostEntity> resolveRepostForActivityItem(
  BuildContext context,
  UserActivityItemEntity item, {
  UserEntity? sourceUser,
}) async {
  final fallback = UserRepostModel.fromActivityItem(
    item,
    sourceUser: sourceUser,
  );

  final bloc = context.read<UserActivityBloc>();
  var state = bloc.state;

  final cached = findRepostInList(state.reposts, item);
  if (cached != null) return cached;

  if (!state.repostsLoaded) {
    bloc.add(LoadReposts());
    await bloc.stream.firstWhere((s) => !s.repostsLoading);
    state = bloc.state;
    final loaded = findRepostInList(state.reposts, item);
    if (loaded != null) return loaded;
  }

  return fallback;
}
