import '../../domain/entities/create_post_entity.dart';
import '../../domain/services/create_post_payload_validator.dart';
import 'create_auction_dto.dart';
import 'create_post_nested_dtos.dart';
import 'post_media_dto.dart';

class CreatePostDto {
  const CreatePostDto({
    this.type,
    this.videoUrl,
    this.hlsUrl,
    this.thumbnailUrl,
    this.animatedCoverUrl,
    this.description,
    this.category,
    this.categoryId,
    this.status,
    this.duration,
    this.videoWidth,
    this.videoHeight,
    this.isAd,
    this.privacyStatus,
    this.allowComments,
    this.allowDuets,
    this.allowStitch,
    this.isStory,
    this.isAuctionable,
    this.auction,
    this.locationId,
    this.location,
    this.playlistId,
    this.soundId,
    this.newSound,
    this.originalPostId,
    this.media,
  });

  final String? type;
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnailUrl;
  final String? animatedCoverUrl;
  final String? description;
  final String? category;
  /// UUID of the selected category — the primary key the backend uses for
  /// category association and for `GET /posts/feed?categoryId=` filtering.
  final String? categoryId;
  final String? status;
  final int? duration;
  final int? videoWidth;
  final int? videoHeight;
  final bool? isAd;
  final String? privacyStatus;
  final bool? allowComments;
  final bool? allowDuets;
  final bool? allowStitch;
  final bool? isStory;
  final bool? isAuctionable;
  final CreateAuctionDto? auction;
  final String? locationId;
  final CreateLocationDto? location;
  final String? playlistId;
  final String? soundId;
  final CreateNewSoundDto? newSound;
  final String? originalPostId;
  final List<PostMediaDto>? media;

  factory CreatePostDto.fromEntity(CreatePostEntity entity) {
    final auctionEntity = entity.auction;
    return CreatePostDto(
      type: entity.type,
      videoUrl: entity.videoUrl,
      hlsUrl: entity.hlsUrl,
      thumbnailUrl: entity.thumbnailUrl,
      animatedCoverUrl: entity.animatedCoverUrl,
      description: entity.description,
      category: entity.category,
      categoryId: entity.categoryId,
      status: entity.status,
      duration: entity.duration,
      videoWidth: entity.videoWidth,
      videoHeight: entity.videoHeight,
      isAd: entity.isAd,
      privacyStatus: entity.privacyStatus,
      allowComments: entity.allowComments,
      allowDuets: entity.allowDuets,
      allowStitch: entity.allowStitch,
      isStory: entity.isStory,
      isAuctionable: entity.isAuctionable,
      auction: entity.isAuctionable &&
              auctionEntity != null &&
              auctionEntity.isComplete
          ? CreateAuctionDto.fromEntity(auctionEntity)
          : null,
      locationId: CreatePostPayloadValidator.resolvesLocationId(entity)
          ? entity.locationId
          : null,
      location: CreatePostPayloadValidator.resolvesInlineLocation(entity) != null
          ? CreateLocationDto.fromEntity(
              CreatePostPayloadValidator.resolvesInlineLocation(entity)!,
            )
          : null,
      playlistId: entity.playlistId,
      soundId: entity.soundId,
      newSound: (entity.soundId == null || entity.soundId!.trim().isEmpty) &&
              entity.newSound != null &&
              entity.newSound!.isComplete
          ? CreateNewSoundDto.fromEntity(entity.newSound!)
          : null,
      originalPostId: entity.originalPostId,
      media: entity.media.isEmpty
          ? null
          : entity.media
              .map(
                (m) => PostMediaDto(
                  url: m.url,
                  mediaType: m.mediaType,
                  order: m.order,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    void putStr(String key, String? value) {
      if (value == null || value.isEmpty) return;
      map[key] = value;
    }

    void putInt(String key, int? value) {
      if (value == null) return;
      map[key] = value;
    }

    // ── Required / always-present fields ─────────────────────────────────────
    putStr('type', type);
    putStr('privacyStatus', privacyStatus);
    putStr('description', description);
    if (status == 'DRAFT' &&
        (description == null || description!.trim().isEmpty)) {
      map['description'] = '';
    }

    // ── Optional string fields ────────────────────────────────────────────────
    // NOTE: `category` (free-text name) is NOT sent — the backend rejects
    // unknown properties.  Only `categoryId` (UUID) is accepted by POST /posts.
    putStr('categoryId', categoryId);
    putStr('videoUrl', videoUrl);
    putStr('thumbnailUrl', thumbnailUrl);
    putStr('hlsUrl', hlsUrl);
    putStr('animatedCoverUrl', animatedCoverUrl);
    if (location != null) {
      map['location'] = location!.toJson();
    } else {
      putStr('locationId', locationId);
    }
    putStr('playlistId', playlistId);
    if (newSound != null) {
      map['newSound'] = newSound!.toJson();
    } else {
      putStr('soundId', soundId);
    }
    putStr('originalPostId', originalPostId);

    // Only send status when explicitly DRAFT; PUBLISHED is the server default.
    if (status == 'DRAFT') map['status'] = 'DRAFT';

    // ── Video metadata (VIDEO posts only) ────────────────────────────────────
    putInt('duration', duration);
    putInt('videoWidth', videoWidth);
    putInt('videoHeight', videoHeight);

    // ── Booleans: only send when they deviate from server defaults ────────────
    // Server defaults: allowComments=true, allowDuets=true, allowStitch=true
    if (allowComments == false) map['allowComments'] = false;
    if (allowDuets == false) map['allowDuets'] = false;
    if (allowStitch == false) map['allowStitch'] = false;
    // Server defaults: isStory=false, isAd=false
    if (isStory == true) map['isStory'] = true;
    if (isAd == true) map['isAd'] = true;

    // ── Auction ───────────────────────────────────────────────────────────────
    if (isAuctionable == true && auction != null) {
      map['isAuctionable'] = true;
      map['auction'] = auction!.toJson();
    }

    // ── Media array (IMAGE / CAROUSEL posts) ─────────────────────────────────
    if (media != null && media!.isNotEmpty) {
      map['media'] = media!.map((m) => m.toJson()).toList();
    }

    return map;
  }
}
