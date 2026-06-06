import '../../../post_management/domain/entities/post_media_entity.dart';
import 'create_post_auction_entity.dart';
import 'local_media_file.dart';

export 'create_post_auction_entity.dart';
export 'local_media_file.dart';

/// Domain model for creating a post via `POST /posts`.
class CreatePostEntity {
  const CreatePostEntity({
    this.type = 'VIDEO',
    this.videoUrl,
    this.hlsUrl,
    this.thumbnailUrl,
    this.animatedCoverUrl,
    this.description,
    this.category,
    this.categoryId,
    this.status = 'PUBLISHED',
    this.duration,
    this.videoWidth,
    this.videoHeight,
    this.isAd = false,
    this.privacyStatus = 'PUBLIC',
    this.allowComments = true,
    this.allowDuets = true,
    this.allowStitch = true,
    this.isStory = false,
    this.isAuctionable = false,
    this.auction,
    this.locationId,
    this.playlistId,
    this.soundId,
    this.originalPostId,
    this.media = const [],
    this.localMedia = const [],
  });

  final String type;
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final String? animatedCoverUrl;
  final String? description;
  final String? category;
  /// The backend UUID of the chosen category.  Sent as `categoryId` in
  /// `POST /posts` and used as the filter key in `GET /posts/feed`.
  final String? categoryId;
  final String status;
  final int? duration;
  final int? videoWidth;
  final int? videoHeight;
  final bool isAd;
  final String privacyStatus;
  final bool allowComments;
  final bool allowDuets;
  final bool allowStitch;
  final bool isStory;
  final bool isAuctionable;
  final CreatePostAuctionEntity? auction;
  final String? locationId;
  final String? playlistId;
  final String? soundId;
  final String? originalPostId;
  final List<PostMediaEntity> media;
  final List<LocalMediaFile> localMedia;

  CreatePostEntity copyWith({
    String? type,
    String? videoUrl,
    String? hlsUrl,
    String? thumbnailUrl,
    String? animatedCoverUrl,
    String? description,
    String? category,
    String? categoryId,
    String? status,
    int? duration,
    int? videoWidth,
    int? videoHeight,
    bool? isAd,
    String? privacyStatus,
    bool? allowComments,
    bool? allowDuets,
    bool? allowStitch,
    bool? isStory,
    bool? isAuctionable,
    CreatePostAuctionEntity? auction,
    String? locationId,
    String? playlistId,
    String? soundId,
    String? originalPostId,
    List<PostMediaEntity>? media,
    List<LocalMediaFile>? localMedia,
    bool clearCategory = false,
    bool clearDescription = false,
    bool clearLocationId = false,
    bool clearPlaylistId = false,
    bool clearSoundId = false,
    bool clearOriginalPostId = false,
    bool clearVideoFields = false,
    bool clearMedia = false,
    bool clearAuction = false,
  }) {
    return CreatePostEntity(
      type: type ?? this.type,
      videoUrl: clearVideoFields ? null : (videoUrl ?? this.videoUrl),
      hlsUrl: clearVideoFields ? null : (hlsUrl ?? this.hlsUrl),
      thumbnailUrl: clearVideoFields ? null : (thumbnailUrl ?? this.thumbnailUrl),
      animatedCoverUrl:
          clearVideoFields ? null : (animatedCoverUrl ?? this.animatedCoverUrl),
      description: clearDescription ? null : (description ?? this.description),
      // clearCategory wipes both the display name and the UUID together so
      // the two fields are always in sync.
      category: clearCategory ? null : (category ?? this.category),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      status: status ?? this.status,
      duration: duration ?? this.duration,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      isAd: isAd ?? this.isAd,
      privacyStatus: privacyStatus ?? this.privacyStatus,
      allowComments: allowComments ?? this.allowComments,
      allowDuets: allowDuets ?? this.allowDuets,
      allowStitch: allowStitch ?? this.allowStitch,
      isStory: isStory ?? this.isStory,
      isAuctionable: isAuctionable ?? this.isAuctionable,
      auction: clearAuction ? null : (auction ?? this.auction),
      locationId: clearLocationId ? null : (locationId ?? this.locationId),
      playlistId: clearPlaylistId ? null : (playlistId ?? this.playlistId),
      soundId: clearSoundId ? null : (soundId ?? this.soundId),
      originalPostId:
          clearOriginalPostId ? null : (originalPostId ?? this.originalPostId),
      media: clearMedia ? const [] : (media ?? this.media),
      localMedia: localMedia ?? this.localMedia,
    );
  }

  bool get hasLocalMedia => localMedia.isNotEmpty;

  bool get allMediaUploaded =>
      localMedia.isNotEmpty && localMedia.every((f) => f.isUploaded);

  bool get hasDescription =>
      description != null && description!.trim().isNotEmpty;

  /// True when a category has been explicitly chosen OR when null (= "All /
  /// General feed").  A post without a category is posted to the global feed
  /// and will appear under every category filter, including "All".
  bool get hasCategory => true;

  bool get canSubmit =>
      hasLocalMedia &&
      hasDescription &&
      (!isAuctionable || (auction?.isComplete ?? false));

  /// Inferred API post type from attached media (used when building payload).
  String get inferredType {
    if (localMedia.length > 1) return 'CAROUSEL';
    if (localMedia.length == 1) {
      return localMedia.first.mediaType == 'VIDEO' ? 'VIDEO' : 'IMAGE';
    }
    return type;
  }
}
