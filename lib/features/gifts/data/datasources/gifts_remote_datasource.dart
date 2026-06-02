import 'package:dio/dio.dart';

import '../../domain/repositories/gifts_repository.dart';
import '../models/gift_model.dart';

abstract class GiftsRemoteDataSource {
  Future<List<GiftModel>> getAdminGifts();
  Future<GiftModel> createGift(CreateGiftData data);
  Future<GiftModel> updateGift(String giftId, UpdateGiftData data);
  Future<void> deleteGift(String giftId);
}

class GiftsRemoteDataSourceImpl implements GiftsRemoteDataSource {
  const GiftsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<GiftModel>> getAdminGifts() async {
    final response = await _dio.get('/gifts/admin');
    final data = response.data;
    final list = data is List ? data : (data['gifts'] ?? data['data'] ?? []) as List;
    return list.map((e) => GiftModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<GiftModel> createGift(CreateGiftData data) async {
    final response = await _dio.post('/gifts/admin', data: {
      'name': data.name,
      'thumbnailUrl': data.thumbnailUrl,
      if (data.animationUrl != null) 'animationUrl': data.animationUrl,
      'priceUsd': data.priceUsd,
      'isActive': data.isActive,
    });
    return _parse(response.data);
  }

  @override
  Future<GiftModel> updateGift(String giftId, UpdateGiftData data) async {
    final body = <String, dynamic>{};
    if (data.name != null) body['name'] = data.name;
    if (data.thumbnailUrl != null) body['thumbnailUrl'] = data.thumbnailUrl;
    if (data.animationUrl != null) body['animationUrl'] = data.animationUrl;
    if (data.priceUsd != null) body['priceUsd'] = data.priceUsd;
    if (data.isActive != null) body['isActive'] = data.isActive;
    final response = await _dio.patch('/gifts/admin/$giftId', data: body);
    return _parse(response.data);
  }

  @override
  Future<void> deleteGift(String giftId) async {
    await _dio.delete('/gifts/admin/$giftId');
  }

  GiftModel _parse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['gift'] is Map<String, dynamic>
              ? data['gift'] as Map<String, dynamic>
              : data;
      return GiftModel.fromJson(payload);
    }
    throw Exception('Invalid gift response format');
  }
}
