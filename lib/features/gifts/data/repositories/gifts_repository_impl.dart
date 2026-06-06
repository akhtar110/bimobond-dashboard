import '../../domain/entities/gift_entity.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../datasources/gifts_remote_datasource.dart';

class GiftsRepositoryImpl implements GiftsRepository {
  const GiftsRepositoryImpl(this._dataSource);
  final GiftsRemoteDataSource _dataSource;

  @override
  Future<List<GiftEntity>> getAdminGifts() => _dataSource.getAdminGifts();

  /// Upload the selected image first, then create the gift with the returned URL.
  @override
  Future<GiftEntity> createGift(CreateGiftData data) async {
    final thumbnailUrl = await _dataSource.uploadGiftImage(
      data.imageBytes,
      data.imageName,
    );
    return _dataSource.createGiftWithUrl(
      name: data.name,
      thumbnailUrl: thumbnailUrl,
      priceUsd: data.priceUsd,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
    );
  }

  /// Update an existing gift.
  /// If [data.imageBytes] is provided the image is uploaded first and the
  /// resulting URL is used as [thumbnailUrl]; any explicit [data.thumbnailUrl]
  /// value is ignored in that case.
  @override
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data) async {
    String? resolvedThumbnailUrl = data.thumbnailUrl;

    if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
      resolvedThumbnailUrl = await _dataSource.uploadGiftImage(
        data.imageBytes!,
        data.imageName ?? 'gift.jpg',
      );
    }

    final patchedData = UpdateGiftData(
      name: data.name,
      thumbnailUrl: resolvedThumbnailUrl,
      animationUrl: data.animationUrl,
      priceUsd: data.priceUsd,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
    );

    return _dataSource.updateGift(giftId, patchedData);
  }

  @override
  Future<void> deleteGift(String giftId) => _dataSource.deleteGift(giftId);
}
