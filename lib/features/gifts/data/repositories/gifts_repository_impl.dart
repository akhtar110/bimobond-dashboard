import 'dart:typed_data';

import '../../domain/entities/bulk_gift_action_request.dart';
import '../../domain/entities/bulk_gift_action_result.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/entities/gift_reorder_item.dart';
import '../../domain/enums/bulk_gift_action_type.dart';
import '../../domain/enums/gift_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../datasources/gifts_remote_datasource.dart';
import '../models/admin_bulk_gift_action.dart';
import '../models/admin_bulk_gifts_dto.dart';
import '../models/gift_model.dart';
import '../utils/gift_solid_color_thumbnail.dart';

class GiftsRepositoryImpl implements GiftsRepository {
  const GiftsRepositoryImpl(this._dataSource);
  final GiftsRemoteDataSource _dataSource;

  @override
  Future<List<GiftEntity>> getAdminGifts() => _dataSource.getAdminGifts();

  @override
  Future<GiftEntity> createGift(CreateGiftData data) async {
    if (data.type == GiftType.audio) {
      final hasAudio = (data.audioUrl != null && data.audioUrl!.isNotEmpty) ||
          (data.audioBytes != null && data.audioBytes!.isNotEmpty);
      if (!hasAudio) {
        throw Exception('audioUrl is required when gift type is AUDIO');
      }
    }

    late final Uint8List imageBytes;
    late final String imageName;
    if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
      imageBytes = data.imageBytes!;
      imageName = data.imageName ?? 'gift.jpg';
    } else if (data.type == GiftType.audio) {
      imageBytes = await buildGiftSolidColorThumbnailPng(data.color);
      imageName = 'gift-color.png';
    } else {
      throw Exception('thumbnail image is required when gift type is IMAGE');
    }

    final thumbnailUrl = await _dataSource.uploadGiftImage(
      imageBytes,
      imageName,
    );

    String? animationUrl = data.animationUrl;
    if ((animationUrl == null || animationUrl.isEmpty) &&
        data.animationBytes != null &&
        data.animationBytes!.isNotEmpty) {
      animationUrl = await _dataSource.uploadGiftImage(
        data.animationBytes!,
        data.animationName ?? 'gift-animation.pag',
      );
    }

    String? audioUrl = data.audioUrl;
    if ((audioUrl == null || audioUrl.isEmpty) &&
        data.audioBytes != null &&
        data.audioBytes!.isNotEmpty) {
      audioUrl = await _dataSource.uploadGiftImage(
        data.audioBytes!,
        data.audioName ?? 'gift-audio.mp3',
      );
    }

    final created = await _dataSource.createGiftWithUrl(
      name: data.name,
      thumbnailUrl: thumbnailUrl,
      animationUrl: animationUrl,
      audioUrl: audioUrl,
      color: data.color,
      type: data.type,
      tag: data.tag,
      priceCoins: data.priceCoins,
      size: data.size,
      sortOrder: data.sortOrder,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
    );

    // Some API responses omit `type` / `audioUrl`; keep the requested values so
    // catalog filters (All / AUDIO) show the gift immediately after create.
    if (data.type == GiftType.audio &&
        (created.type != GiftType.audio ||
            ((created.audioUrl == null || created.audioUrl!.isEmpty) &&
                audioUrl != null &&
                audioUrl.isNotEmpty))) {
      return GiftModel(
        id: created.id,
        name: created.name,
        thumbnailUrl: created.thumbnailUrl,
        animationUrl: created.animationUrl,
        audioUrl: (created.audioUrl != null && created.audioUrl!.isNotEmpty)
            ? created.audioUrl
            : audioUrl,
        color: created.color ?? data.color,
        type: GiftType.audio,
        tag: created.tag ?? data.tag,
        priceCoins: created.priceCoins,
        size: created.size,
        sortOrder: created.sortOrder,
        isActive: created.isActive,
        publishedAt: created.publishedAt,
      );
    }
    return created;
  }

  @override
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data) async {
    String? resolvedThumbnailUrl = data.thumbnailUrl;
    String? resolvedAnimationUrl = data.animationUrl;
    String? resolvedAudioUrl = data.audioUrl;

    if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
      resolvedThumbnailUrl = await _dataSource.uploadGiftImage(
        data.imageBytes!,
        data.imageName ?? 'gift.jpg',
      );
    }

    if ((resolvedAnimationUrl == null || resolvedAnimationUrl.isEmpty) &&
        data.animationBytes != null &&
        data.animationBytes!.isNotEmpty) {
      resolvedAnimationUrl = await _dataSource.uploadGiftImage(
        data.animationBytes!,
        data.animationName ?? 'gift-animation.pag',
      );
    }

    if ((resolvedAudioUrl == null || resolvedAudioUrl.isEmpty) &&
        data.audioBytes != null &&
        data.audioBytes!.isNotEmpty) {
      resolvedAudioUrl = await _dataSource.uploadGiftImage(
        data.audioBytes!,
        data.audioName ?? 'gift-audio.mp3',
      );
    }

    final effectiveType = data.type;
    if (effectiveType == GiftType.audio) {
      final hasAudio = (resolvedAudioUrl != null &&
              resolvedAudioUrl.isNotEmpty) ||
          !data.clearAudioUrl;
      // When switching to AUDIO without providing audio, backend will reject.
      // Allow if clearAudioUrl is false and we keep existing (omit field).
      if (data.clearAudioUrl) {
        throw Exception('audioUrl is required when gift type is AUDIO');
      }
      if (hasAudio &&
          (resolvedAudioUrl == null || resolvedAudioUrl.isEmpty) &&
          data.audioUrl == null &&
          data.audioBytes == null) {
        // Existing audio kept by omitting audioUrl from PATCH — OK.
      }
    }

    final patchedData = UpdateGiftData(
      name: data.name,
      thumbnailUrl: resolvedThumbnailUrl,
      animationUrl: resolvedAnimationUrl,
      audioUrl: resolvedAudioUrl,
      color: data.color,
      type: data.type,
      tag: data.tag,
      priceCoins: data.priceCoins,
      size: data.size,
      sortOrder: data.sortOrder,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
      clearPublishedAt: data.clearPublishedAt,
      clearTag: data.clearTag,
      clearColor: data.clearColor,
      clearAudioUrl: data.clearAudioUrl,
      clearAnimationUrl: data.clearAnimationUrl,
    );

    return _dataSource.updateGift(giftId, patchedData);
  }

  @override
  Future<String> uploadGiftFile(Uint8List bytes, String filename) =>
      _dataSource.uploadGiftImage(bytes, filename);

  @override
  Future<void> deleteGift(String giftId) => _dataSource.deleteGift(giftId);

  @override
  Future<BulkGiftActionResult> executeBulkAction(
    BulkGiftActionRequest request,
  ) async {
    if (request.giftIds.isEmpty) {
      return const BulkGiftActionResult(
        action: '',
        successCount: 0,
        notFoundCount: 0,
        giftIds: [],
        notFoundIds: [],
      );
    }

    try {
      final dto = AdminBulkGiftsDto(
        giftIds: request.giftIds,
        action: _toAdminAction(request.action),
      );
      final result = await _dataSource.executeAdminBulkAction(dto);

      String? errorMessage;
      if (!result.isFullSuccess) {
        final parts = <String>[];
        if (result.notFoundCount > 0 || result.notFoundIds.isNotEmpty) {
          parts.add(
            '${result.notFoundCount > 0 ? result.notFoundCount : result.notFoundIds.length} gift(s) not found',
          );
        }
        errorMessage = parts.isEmpty
            ? null
            : parts.join('; ');
      }

      return BulkGiftActionResult(
        action: result.action,
        successCount: result.successCount,
        notFoundCount: result.notFoundCount,
        giftIds: result.giftIds,
        notFoundIds: result.notFoundIds,
        deactivatedCount: result.deactivatedCount,
        deactivatedIds: result.deactivatedIds,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return BulkGiftActionResult(
        action: request.action.apiValue,
        successCount: 0,
        notFoundCount: request.giftIds.length,
        giftIds: const [],
        notFoundIds: request.giftIds,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Future<List<GiftEntity>> reorderGifts(List<GiftReorderItem> items) =>
      _dataSource.reorderGifts(items);

  @override
  Future<List<GiftGroupEntity>> getGiftGroups() => _dataSource.getGiftGroups();

  @override
  Future<GiftGroupEntity> createGiftGroup(CreateGiftGroupData data) =>
      _dataSource.createGiftGroup(data);

  @override
  Future<List<GiftGroupEntity>> reorderGiftGroups(
    List<GiftGroupReorderItem> items,
  ) =>
      _dataSource.reorderGiftGroups(items);

  @override
  Future<GiftGroupEntity> updateGiftGroup(
    String groupId,
    UpdateGiftGroupData data,
  ) =>
      _dataSource.updateGiftGroup(groupId, data);

  @override
  Future<void> deleteGiftGroup(String groupId) =>
      _dataSource.deleteGiftGroup(groupId);

  @override
  Future<GiftGroupEntity> replaceGroupGifts(
    String groupId,
    List<GiftGroupMembershipItem> gifts,
  ) =>
      _dataSource.replaceGroupGifts(groupId, gifts);

  AdminBulkGiftAction _toAdminAction(BulkGiftActionType action) =>
      switch (action) {
        BulkGiftActionType.delete => AdminBulkGiftAction.delete,
        BulkGiftActionType.activate => AdminBulkGiftAction.activate,
        BulkGiftActionType.deactivate => AdminBulkGiftAction.deactivate,
      };
}
