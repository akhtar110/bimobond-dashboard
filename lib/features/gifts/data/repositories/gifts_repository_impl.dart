import 'dart:typed_data';

import '../../domain/entities/bulk_gift_action_request.dart';
import '../../domain/entities/bulk_gift_action_result.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../../domain/enums/bulk_gift_action_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../datasources/gifts_remote_datasource.dart';
import '../models/admin_bulk_gift_action.dart';
import '../models/admin_bulk_gifts_dto.dart';

class GiftsRepositoryImpl implements GiftsRepository {
  const GiftsRepositoryImpl(this._dataSource);
  final GiftsRemoteDataSource _dataSource;

  @override
  Future<List<GiftEntity>> getAdminGifts() => _dataSource.getAdminGifts();

  @override
  Future<GiftEntity> createGift(CreateGiftData data) async {
    final thumbnailUrl = await _dataSource.uploadGiftImage(
      data.imageBytes,
      data.imageName,
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

    final created = await _dataSource.createGiftWithUrl(
      name: data.name,
      thumbnailUrl: thumbnailUrl,
      animationUrl: animationUrl,
      priceCoins: data.priceCoins,
      size: data.size,
      isActive: data.isActive,
      // Match create UI "defaults to now" when the admin leaves date empty.
      publishedAt: data.publishedAt ?? DateTime.now(),
    );
    if (created.publishedAt != null) return created;
    return created.copyWith(publishedAt: data.publishedAt ?? DateTime.now());
  }

  @override
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data) async {
    String? resolvedThumbnailUrl = data.thumbnailUrl;
    String? resolvedAnimationUrl = data.animationUrl;

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

    final patchedData = UpdateGiftData(
      name: data.name,
      thumbnailUrl: resolvedThumbnailUrl,
      animationUrl: resolvedAnimationUrl,
      priceCoins: data.priceCoins,
      size: data.size,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
      clearPublishedAt: data.clearPublishedAt,
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

      return BulkGiftActionResult(
        action: result.action,
        successCount: result.successCount,
        notFoundCount: result.notFoundCount,
        giftIds: result.giftIds,
        notFoundIds: result.notFoundIds,
        deactivatedCount: result.deactivatedCount,
        deactivatedIds: result.deactivatedIds,
        errorMessage: result.isFullSuccess
            ? null
            : '${result.notFoundIds.length} gift(s) could not be updated',
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
