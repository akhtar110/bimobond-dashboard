import '../../post_management/domain/entities/post_media_entity.dart';
import 'entities/create_post_entity.dart';

/// Builds a [CreatePostEntity] that matches `POST /posts` contract from the API docs.
class CreatePostPayloadBuilder {
  const CreatePostPayloadBuilder._();

  static String normalizeUploadUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final uploadsIndex = trimmed.indexOf('/uploads/');
    if (uploadsIndex >= 0) {
      return trimmed.substring(uploadsIndex);
    }

    return trimmed;
  }

  static String parseUploadUrlEntry(dynamic item) {
    if (item is String && item.isNotEmpty) {
      return normalizeUploadUrl(item);
    }
    if (item is Map) {
      for (final key in ['url', 'path', 'location', 'file']) {
        final value = item[key];
        if (value is String && value.isNotEmpty) {
          return normalizeUploadUrl(value);
        }
      }
    }
    throw FormatException('Invalid upload URL in response: $item');
  }

  /// Maps uploaded [localMedia] (in display order) to API-ready entity.
  static CreatePostEntity build(CreatePostEntity form) {
    final uploaded = <({LocalMediaFile file, String url})>[];
    for (final file in form.localMedia) {
      final url = file.uploadedUrl;
      if (url != null && url.isNotEmpty) {
        uploaded.add((file: file, url: normalizeUploadUrl(url)));
      }
    }

    if (uploaded.isEmpty) {
      throw StateError('No uploaded media URLs');
    }

    final videos =
        uploaded.where((e) => e.file.mediaType == 'VIDEO').toList();
    final images =
        uploaded.where((e) => e.file.mediaType == 'IMAGE').toList();

    final mediaItems = <PostMediaEntity>[
      for (var i = 0; i < uploaded.length; i++)
        PostMediaEntity(
          url: uploaded[i].url,
          mediaType: uploaded[i].file.mediaType,
          order: i,
        ),
    ];

    final effectiveType = _resolveType(form, uploaded.length, videos.length);

    final common = CreatePostEntity(
      description: form.description,
      category: form.category,
      status: form.status,
      duration: form.duration,
      videoWidth: form.videoWidth,
      videoHeight: form.videoHeight,
      isAd: form.isAd,
      privacyStatus: form.privacyStatus,
      allowComments: form.allowComments,
      allowDuets: form.allowDuets,
      allowStitch: form.allowStitch,
      isStory: form.isStory,
      isAuctionable: form.isAuctionable,
      auction: form.isAuctionable ? form.auction : null,
      locationId: form.locationId,
      playlistId: form.playlistId,
      soundId: form.soundId,
      originalPostId: form.originalPostId,
      hlsUrl: form.hlsUrl,
      animatedCoverUrl: form.animatedCoverUrl,
      localMedia: form.localMedia,
    );

    if (effectiveType == 'CAROUSEL') {
      return common.copyWith(
        type: 'CAROUSEL',
        media: mediaItems,
        clearVideoFields: true,
      );
    }

    if (effectiveType == 'VIDEO') {
      final videoUrl = videos.first.url;
      final thumbnailUrl =
          images.isNotEmpty ? images.first.url : videoUrl;
      return common.copyWith(
        type: 'VIDEO',
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        media: const [],
      );
    }

    return common.copyWith(
      type: 'IMAGE',
      media: [mediaItems.first],
      clearVideoFields: true,
    );
  }

  static String _resolveType(
    CreatePostEntity form,
    int count,
    int videoCount,
  ) {
    if (count > 1) return 'CAROUSEL';
    if (count == 1) {
      return videoCount == 1 ? 'VIDEO' : 'IMAGE';
    }
    if (form.type == 'CAROUSEL' || form.type == 'IMAGE' || form.type == 'VIDEO') {
      return form.type;
    }
    return form.inferredType;
  }
}
