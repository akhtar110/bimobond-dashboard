import 'package:flutter/material.dart';

import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../stories/data/models/story_model.dart';
import '../../../stories/domain/entities/story_entity.dart';
import '../../../stories/presentation/widgets/story_details_dialog.dart';
import '../../../user_activity/presentation/utils/activity_navigation.dart';
import '../../../users/data/models/user_post_model.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_history_entity.dart';

bool canOpenUserHistoryItem(UserHistoryEntity item) {
  final type = item.normalizedType;
  if (type == UserHistoryTypes.storyView) {
    return userHistoryStoryId(item)?.isNotEmpty == true;
  }
  if (_isPostNavigableType(type)) {
    return userHistoryPostId(item)?.isNotEmpty == true;
  }
  return false;
}

Future<void> openUserHistoryItem(
  BuildContext context,
  UserHistoryEntity item, {
  UserEntity? sourceUser,
}) async {
  final type = item.normalizedType;

  if (type == UserHistoryTypes.storyView) {
    await openUserHistoryStory(context, item);
    return;
  }

  if (_isPostNavigableType(type)) {
    await openUserHistoryPost(
      context,
      item,
      sourceUser: sourceUser,
    );
  }
}

bool _isPostNavigableType(String type) {
  return type == UserHistoryTypes.postView ||
      type == UserHistoryTypes.likePost ||
      type == UserHistoryTypes.comment ||
      type == UserHistoryTypes.createPost ||
      type == UserHistoryTypes.sendGift;
}

String? userHistoryPostId(UserHistoryEntity item) {
  final direct = item.dataString('postId') ?? item.nestedString('post', 'id');
  if (direct != null && direct.isNotEmpty) return direct;

  if (item.dataString('targetType')?.toUpperCase() == 'POST') {
    final targetId = item.dataString('targetId');
    if (targetId != null && targetId.isNotEmpty) return targetId;
  }

  // CREATE_POST payload is typically the post itself under `data`.
  if (item.normalizedType == UserHistoryTypes.createPost) {
    final id = item.dataString('id');
    if (id != null && id.isNotEmpty) return id;
  }

  return null;
}

String? userHistoryStoryId(UserHistoryEntity item) {
  final direct =
      item.dataString('storyId') ?? item.nestedString('story', 'id');
  if (direct != null && direct.isNotEmpty) return direct;

  if (item.dataString('targetType')?.toUpperCase() == 'STORY') {
    final targetId = item.dataString('targetId');
    if (targetId != null && targetId.isNotEmpty) return targetId;
  }

  // Some payloads nest the story fields directly on `data`.
  final hasMediaList = item.data['media'] is List;
  if (hasMediaList || item.dataString('description') != null) {
    final id = item.dataString('id');
    if (id != null && id.isNotEmpty) return id;
  }

  return item.nestedString('story', 'id');
}

ManagedPostEntity managedPostFromUserHistoryItem(UserHistoryEntity item) {
  var postMap = item.dataMap('post');

  // CREATE_POST usually places post fields directly on `data`.
  if (postMap == null &&
      item.normalizedType == UserHistoryTypes.createPost &&
      (item.dataString('id')?.isNotEmpty ?? false)) {
    postMap = Map<String, dynamic>.from(item.data);
  }

  if (postMap != null) {
    final json = Map<String, dynamic>.from(postMap);
    final postId = userHistoryPostId(item);
    if ((json['id'] == null || json['id'].toString().isEmpty) &&
        postId != null &&
        postId.isNotEmpty) {
      json['id'] = postId;
    }
    try {
      return managedPostFromUserPost(UserPostModel.fromJson(json));
    } catch (_) {
      // Fall through to seed with available fields.
    }
  }

  final postId = userHistoryPostId(item) ?? '';
  final seed = managedPostSeed(postId);
  final description = item.nestedString('post', 'description') ??
      item.dataString('description') ??
      item.dataString('postDescription');
  final thumbnail = item.nestedString('post', 'thumbnailUrl') ??
      item.dataString('thumbnailUrl');
  final videoUrl =
      item.nestedString('post', 'videoUrl') ?? item.dataString('videoUrl');

  return seed.copyWith(
    description: description,
    thumbnailUrl: thumbnail,
    videoUrl: videoUrl,
  );
}

StoryEntity? storyFromUserHistoryItem(UserHistoryEntity item) {
  final storyMap = item.dataMap('story');
  if (storyMap != null) {
    try {
      final json = Map<String, dynamic>.from(storyMap);
      final storyId = userHistoryStoryId(item);
      if ((json['id'] == null || json['id'].toString().isEmpty) &&
          storyId != null) {
        json['id'] = storyId;
      }
      return StoryModel.fromJson(json);
    } catch (_) {
      // Fall through to seed.
    }
  }

  // Treat root data as story when it looks like one.
  final hasMediaList = item.data['media'] is List;
  if (hasMediaList ||
      (item.dataString('id')?.isNotEmpty == true &&
          item.normalizedType == UserHistoryTypes.storyView)) {
    try {
      return StoryModel.fromJson(Map<String, dynamic>.from(item.data));
    } catch (_) {
      // Fall through to seed.
    }
  }

  final storyId = userHistoryStoryId(item);
  if (storyId == null || storyId.isEmpty) return null;

  final ownerMap = item.dataMap('owner') ??
      item.dataMap('user') ??
      item.dataMap('profile');
  StoryUserEntity? owner;
  if (ownerMap != null) {
    try {
      owner = StoryUserModel.fromJson(ownerMap);
    } catch (_) {
      owner = null;
    }
  }

  final mediaUrl = item.dataString('mediaUrl') ??
      item.dataString('url') ??
      item.dataString('thumbnailUrl') ??
      item.nestedString('media', 'url');
  final media = <StoryMediaEntity>[
    if (mediaUrl != null && mediaUrl.isNotEmpty)
      StoryMediaEntity(
        url: mediaUrl,
        thumbnailUrl: item.dataString('thumbnailUrl'),
        type: item.dataString('mediaType'),
      ),
  ];

  return StoryEntity(
    id: storyId,
    userId: owner?.id ?? item.dataString('userId') ?? '',
    description: item.dataString('description') ?? '',
    status: item.dataString('status') ?? 'PUBLISHED',
    privacyStatus: item.dataString('privacyStatus') ?? 'PUBLIC',
    ttlHours: item.dataNum('ttlHours')?.toInt() ?? 24,
    expiresAt: DateTime.tryParse(item.dataString('expiresAt') ?? '') ??
        item.createdAt.add(const Duration(hours: 24)),
    viewCount: item.dataNum('viewCount')?.toInt() ?? 0,
    isExpired: item.dataString('isExpired') == 'true',
    media: media,
    user: owner,
    createdAt: item.createdAt,
    updatedAt: item.createdAt,
  );
}

ActivityContext _activityContextForItem(UserHistoryEntity item) {
  final type = item.normalizedType;
  switch (type) {
    case UserHistoryTypes.likePost:
      return ActivityContext.like(
        likeId: item.dataString('id') ?? '',
        activityDate: item.createdAt,
      );
    case UserHistoryTypes.comment:
      final commentId = item.dataString('commentId') ?? item.dataString('id') ?? '';
      return ActivityContext.comment(
        commentId: commentId,
        commentText: item.dataString('content') ??
            item.dataString('comment') ??
            '',
        activityDate: item.createdAt,
        commentUserId: item.dataString('userId'),
        commentUsername: item.nestedString('user', 'username'),
      );
    case UserHistoryTypes.createPost:
    case UserHistoryTypes.postView:
    case UserHistoryTypes.sendGift:
      return ActivityContext.post(activityDate: item.createdAt);
    default:
      return ActivityContext.feed(
        activityDate: item.createdAt,
        label: item.type,
      );
  }
}

Future<void> openUserHistoryPost(
  BuildContext context,
  UserHistoryEntity item, {
  UserEntity? sourceUser,
}) async {
  final postId = userHistoryPostId(item);
  if (postId == null || postId.isEmpty) return;

  await openPostInvestigation(
    context,
    postId: postId,
    post: managedPostFromUserHistoryItem(item),
    sourceUser: sourceUser,
    activityContext: _activityContextForItem(item),
  );
}

Future<void> openUserHistoryStory(
  BuildContext context,
  UserHistoryEntity item,
) async {
  final story = storyFromUserHistoryItem(item);
  if (story == null || story.id.isEmpty) return;

  await showStoryDetailsDialog(context, story: story);
}

/// Kept for callers that still reference the old name.
Future<void> openUserHistoryViewedPost(
  BuildContext context,
  UserHistoryEntity item, {
  UserEntity? sourceUser,
}) =>
    openUserHistoryPost(context, item, sourceUser: sourceUser);
