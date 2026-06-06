import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/repositories/gifts_repository.dart';
import '../models/gift_model.dart';

abstract class GiftsRemoteDataSource {
  Future<List<GiftModel>> getAdminGifts();

  /// Upload raw image bytes and return the resulting absolute URL.
  Future<String> uploadGiftImage(Uint8List bytes, String filename);

  Future<GiftModel> createGiftWithUrl({
    required String name,
    required String thumbnailUrl,
    required double priceUsd,
    bool isActive = true,
    DateTime? publishedAt,
  });

  Future<GiftModel> updateGift(String giftId, UpdateGiftData data);
  Future<void> deleteGift(String giftId);
}

class GiftsRemoteDataSourceImpl implements GiftsRemoteDataSource {
  const GiftsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  // ── GET gifts ──────────────────────────────────────────────────────────────

  @override
  Future<List<GiftModel>> getAdminGifts() async {
    final response = await _dio.get('/gifts/admin');
    final data = response.data;
    final list =
        data is List ? data : (data['gifts'] ?? data['data'] ?? []) as List;
    return list
        .map((e) => GiftModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Upload image ───────────────────────────────────────────────────────────

  @override
  Future<String> uploadGiftImage(Uint8List bytes, String filename) async {
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'files',
        MultipartFile.fromBytes(bytes, filename: filename),
      ),
    );

    final response = await _dio.post(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final data = response.data;
    String? url;

    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      final urls = data['urls'] ??
          (nested is Map<String, dynamic> ? nested['urls'] : null);
      if (urls is List && urls.isNotEmpty) {
        url = _parseUrl(urls.first);
      }
    } else if (data is List && data.isNotEmpty) {
      url = _parseUrl(data.first);
    }

    if (url == null || url.isEmpty) {
      throw Exception('Image upload failed: no URL returned');
    }
    return url;
  }

  String _parseUrl(dynamic entry) {
    if (entry is String) return entry;
    if (entry is Map<String, dynamic>) {
      return (entry['url'] ?? entry['path'] ?? '').toString();
    }
    return '';
  }

  // ── Create gift ────────────────────────────────────────────────────────────

  @override
  Future<GiftModel> createGiftWithUrl({
    required String name,
    required String thumbnailUrl,
    required double priceUsd,
    bool isActive = true,
    DateTime? publishedAt,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'priceUsd': priceUsd,
      'isActive': isActive,
      // Always send publishedAt; use provided value or default to now.
      'publishedAt':
          (publishedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };

    final response = await _dio.post(
      '/gifts/admin',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _parse(response.data);
  }

  // ── Update gift ────────────────────────────────────────────────────────────

  @override
  Future<GiftModel> updateGift(String giftId, UpdateGiftData data) async {
    final body = <String, dynamic>{};
    if (data.name != null) body['name'] = data.name;
    if (data.thumbnailUrl != null) body['thumbnailUrl'] = data.thumbnailUrl;
    if (data.animationUrl != null) body['animationUrl'] = data.animationUrl;
    if (data.priceUsd != null) body['priceUsd'] = data.priceUsd;
    if (data.isActive != null) body['isActive'] = data.isActive;
    if (data.publishedAt != null) {
      body['publishedAt'] = data.publishedAt!.toUtc().toIso8601String();
    }

    final response = await _dio.patch(
      '/gifts/admin/$giftId',
      data: body,
      options: Options(contentType: Headers.jsonContentType),
    );
    return _parse(response.data);
  }

  // ── Delete gift ────────────────────────────────────────────────────────────

  @override
  Future<void> deleteGift(String giftId) async {
    await _dio.delete('/gifts/admin/$giftId');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
