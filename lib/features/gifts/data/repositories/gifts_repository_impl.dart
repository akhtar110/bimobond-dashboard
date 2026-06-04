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
    );
  }

  @override
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data) =>
      _dataSource.updateGift(giftId, data);

  @override
  Future<void> deleteGift(String giftId) => _dataSource.deleteGift(giftId);
}
