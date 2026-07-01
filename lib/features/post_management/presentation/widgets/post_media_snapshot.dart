import 'package:flutter/foundation.dart';

import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_media_entity.dart';

/// Stable media-only slice used to isolate carousel rebuilds from draft edits.
@immutable
class PostMediaSnapshot {
  const PostMediaSnapshot({
    required this.postId,
    required this.type,
    this.videoUrl,
    this.hlsUrl,
    this.thumbnailUrl,
    this.media = const [],
    this.videoWidth,
    this.videoHeight,
  });

  final String postId;
  final String type;
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final List<PostMediaEntity> media;
  final int? videoWidth;
  final int? videoHeight;

  factory PostMediaSnapshot.fromPost(ManagedPostEntity post) {
    return PostMediaSnapshot(
      postId: post.id,
      type: post.type,
      videoUrl: post.videoUrl,
      hlsUrl: post.hlsUrl,
      thumbnailUrl: post.thumbnailUrl,
      media: post.media,
      videoWidth: post.videoWidth,
      videoHeight: post.videoHeight,
    );
  }

  /// Minimal entity shell for existing carousel/preview widgets.
  ManagedPostEntity toPostShell() {
    return ManagedPostEntity(
      id: postId,
      userId: '',
      type: type,
      videoUrl: videoUrl,
      hlsUrl: hlsUrl,
      thumbnailUrl: thumbnailUrl,
      media: media,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      status: 'PUBLISHED',
      viewCount: 0,
      shareCount: 0,
      downloadCount: 0,
      likeCount: 0,
      commentCount: 0,
      saveCount: 0,
      isAd: false,
      privacyStatus: 'PUBLIC',
      allowComments: true,
      allowDuets: true,
      allowStitch: true,
      isStory: false,
      isAuctionable: false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostMediaSnapshot &&
        other.postId == postId &&
        other.type == type &&
        other.videoUrl == videoUrl &&
        other.hlsUrl == hlsUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.videoWidth == videoWidth &&
        other.videoHeight == videoHeight &&
        listEquals(other.media, media);
  }

  @override
  int get hashCode => Object.hash(
        postId,
        type,
        videoUrl,
        hlsUrl,
        thumbnailUrl,
        videoWidth,
        videoHeight,
        Object.hashAll(media),
      );
}
