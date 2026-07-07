import '../../../post_management/data/models/managed_post_model.dart';
import '../../../post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../domain/entities/active_story_author.dart';
import '../../domain/entities/active_story_entity.dart';

class ActiveStoryModel extends ActiveStoryEntity {
  const ActiveStoryModel({
    required super.id,
    required super.mediaUrl,
    required super.thumbnailUrl,
    required super.isVideo,
    required super.title,
    required super.caption,
    required super.createdAt,
    required super.expiresAt,
    required super.author,
    required super.postData,
  });

  factory ActiveStoryModel.fromJson(Map<String, dynamic> json) {
    final post = hydrateManagedPostMedia(
      normalizeManagedPostMediaFields(
        ManagedPostModel.fromJson(json),
      ),
    );
    return ActiveStoryModel.fromPost(post, rawJson: json);
  }

  factory ActiveStoryModel.fromPost(
    ManagedPostEntity post, {
    Map<String, dynamic>? rawJson,
  }) {
    final isVideo = post.containsVideoMedia;
    final mediaUrl = _resolveMediaUrl(post, isVideo);
    final thumbnailUrl = isVideo
        ? (post.previewThumbnailUrl ??
            post.displayThumbnailUrl ??
            '')
        : (post.displayThumbnailUrl ?? mediaUrl);
    final caption = post.description?.trim() ?? '';
    final title = _resolveTitle(post, caption);
    final expiresAt = _readDate(rawJson?['storyExpiresAt']) ??
        _readDate(rawJson?['expiresAt']) ??
        post.createdAt.add(const Duration(hours: 24));

    final author = ActiveStoryAuthor(
      id: post.userId,
      name: post.userFullName?.trim().isNotEmpty == true
          ? post.userFullName!.trim()
          : (post.userName?.trim().isNotEmpty == true
              ? post.userName!.trim()
              : 'Unknown'),
      username: post.userName?.trim() ?? '',
      avatarUrl: post.userProfileImage,
    );

    return ActiveStoryModel(
      id: post.id,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      isVideo: isVideo,
      title: title,
      caption: caption,
      createdAt: post.createdAt,
      expiresAt: expiresAt,
      author: author,
      postData: post,
    );
  }

  ActiveStoryEntity toEntity() => this;

  static String _resolveMediaUrl(ManagedPostEntity post, bool isVideo) {
    if (isVideo) {
      for (final candidate in [
        post.videoUrl,
        post.hlsUrl,
        ...post.playableMediaUrls,
      ]) {
        final value = candidate?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }

    for (final item in post.media) {
      if (!item.isVideo) {
        final url = item.url.trim();
        if (url.isNotEmpty) return url;
      }
    }

    final thumb = post.displayThumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) return thumb;

    return '';
  }

  static String _resolveTitle(ManagedPostEntity post, String caption) {
    if (caption.isNotEmpty) {
      final firstLine = caption.split('\n').first.trim();
      if (firstLine.length <= 48) return firstLine;
      return '${firstLine.substring(0, 45)}...';
    }

    final category = post.category?.trim();
    if (category != null && category.isNotEmpty) return category;

    return 'Story';
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
