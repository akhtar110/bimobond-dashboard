import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/entities/gift_group_entities.dart';
import '../../domain/entities/gift_reorder_item.dart';
import '../../domain/enums/gift_size.dart';
import '../../domain/enums/gift_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../models/admin_bulk_gifts_dto.dart';
import '../models/bulk_admin_gift_action_result.dart';
import '../models/gift_group_models.dart';
import '../models/gift_model.dart';

abstract class GiftsRemoteDataSource {
  Future<List<GiftModel>> getAdminGifts();
  Future<String> uploadGiftImage(Uint8List bytes, String filename);
  Future<GiftModel> createGiftWithUrl({
    required String name,
    required String thumbnailUrl,
    required double priceCoins,
    GiftSize size = GiftSize.medium,
    GiftType type = GiftType.image,
    String? tag,
    String? color,
    int? sortOrder,
    bool isActive = true,
    DateTime? publishedAt,
    String? animationUrl,
    String? audioUrl,
  });
  Future<GiftModel> updateGift(String giftId, UpdateGiftData data);
  Future<void> deleteGift(String giftId);
  Future<BulkAdminGiftActionResult> executeAdminBulkAction(AdminBulkGiftsDto dto);
  Future<List<GiftModel>> reorderGifts(List<GiftReorderItem> items);

  Future<List<GiftGroupEntity>> getGiftGroups();
  Future<GiftGroupEntity> createGiftGroup(CreateGiftGroupData data);
  Future<List<GiftGroupEntity>> reorderGiftGroups(
    List<GiftGroupReorderItem> items,
  );
  Future<GiftGroupEntity> updateGiftGroup(
    String groupId,
    UpdateGiftGroupData data,
  );
  Future<void> deleteGiftGroup(String groupId);
  Future<GiftGroupEntity> replaceGroupGifts(
    String groupId,
    List<GiftGroupMembershipItem> gifts,
  );
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
    // Keep relative paths for gift group `iconUrl` (API max 500). Callers
    // resolve for display via [resolveMediaUrl].
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
    required double priceCoins,
    GiftSize size = GiftSize.medium,
    GiftType type = GiftType.image,
    String? tag,
    String? color,
    int? sortOrder,
    bool isActive = true,
    DateTime? publishedAt,
    String? animationUrl,
    String? audioUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'priceCoins': priceCoins,
      'size': size.apiValue,
      'type': type.apiValue,
      'isActive': isActive,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (color != null && color.isNotEmpty) 'color': color,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (publishedAt != null)
        'publishedAt': publishedAt.toUtc().toIso8601String(),
      if (animationUrl != null && animationUrl.isNotEmpty)
        'animationUrl': animationUrl,
      if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
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
    if (data.priceCoins != null) body['priceCoins'] = data.priceCoins;
    if (data.size != null) body['size'] = data.size!.apiValue;
    if (data.type != null) body['type'] = data.type!.apiValue;
    if (data.sortOrder != null) body['sortOrder'] = data.sortOrder;
    if (data.isActive != null) body['isActive'] = data.isActive;
    if (data.clearPublishedAt) {
      body['publishedAt'] = null;
    } else if (data.publishedAt != null) {
      body['publishedAt'] = data.publishedAt!.toUtc().toIso8601String();
    }
    if (data.clearTag) {
      body['tag'] = null;
    } else if (data.tag != null) {
      body['tag'] = data.tag;
    }
    if (data.clearColor) {
      body['color'] = null;
    } else if (data.color != null) {
      body['color'] = data.color;
    }
    if (data.clearAnimationUrl) {
      body['animationUrl'] = null;
    } else if (data.animationUrl != null) {
      body['animationUrl'] = data.animationUrl;
    }
    if (data.clearAudioUrl) {
      body['audioUrl'] = null;
    } else if (data.audioUrl != null) {
      body['audioUrl'] = data.audioUrl;
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

  @override
  Future<BulkAdminGiftActionResult> executeAdminBulkAction(
    AdminBulkGiftsDto dto,
  ) async {
    final response = await _dio.post(
      '/gifts/admin/bulk',
      data: dto.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );
    return _parseBulkResponse(dto, response.data);
  }

  @override
  Future<List<GiftModel>> reorderGifts(List<GiftReorderItem> items) async {
    final response = await _dio.patch(
      '/gifts/admin/reorder',
      data: {'items': items.map((e) => e.toJson()).toList()},
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = response.data;
    final list =
        data is List ? data : (data['gifts'] ?? data['data'] ?? []) as List;
    return list
        .map((e) => GiftModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  BulkAdminGiftActionResult _parseBulkResponse(
    AdminBulkGiftsDto dto,
    dynamic data,
  ) {
    if (data is! Map<String, dynamic>) {
      return BulkAdminGiftActionResult(action: dto.action.apiValue);
    }

    final nested = data['data'] ?? data;
    if (nested is! Map<String, dynamic>) {
      return BulkAdminGiftActionResult(action: dto.action.apiValue);
    }

    return BulkAdminGiftActionResult(
      action: nested['action']?.toString() ?? dto.action.apiValue,
      successCount: _asInt(nested['successCount']),
      notFoundCount: _asInt(nested['notFoundCount']),
      giftIds: _readStringList(nested['giftIds']),
      notFoundIds: _readStringList(nested['notFoundIds']),
      deactivatedCount: _asInt(nested['deactivatedCount']),
      deactivatedIds: _readStringList(nested['deactivatedIds']),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
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

  String _extractErrorMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return error.message ?? error.toString();
  }

  @override
  Future<List<GiftGroupEntity>> getGiftGroups() async {
    final response = await _dio.get('/gifts/admin/groups');
    return parseGiftGroupList(response.data);
  }

  @override
  Future<GiftGroupEntity> createGiftGroup(CreateGiftGroupData data) async {
    final response = await _dio.post('/gifts/admin/groups', data: data.toJson());
    return parseGiftGroup(response.data);
  }

  @override
  Future<List<GiftGroupEntity>> reorderGiftGroups(
    List<GiftGroupReorderItem> items,
  ) async {
    final response = await _dio.patch(
      '/gifts/admin/groups/reorder',
      data: {'items': items.map((item) => item.toJson()).toList()},
    );
    return parseGiftGroupList(response.data);
  }

  @override
  Future<GiftGroupEntity> updateGiftGroup(
    String groupId,
    UpdateGiftGroupData data,
  ) async {
    final response = await _dio.patch(
      '/gifts/admin/groups/$groupId',
      data: data.toJson(),
    );
    return parseGiftGroup(response.data);
  }

  @override
  Future<void> deleteGiftGroup(String groupId) async {
    try {
      await _dio.delete('/gifts/admin/groups/$groupId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<GiftGroupEntity> replaceGroupGifts(
    String groupId,
    List<GiftGroupMembershipItem> gifts,
  ) async {
    final response = await _dio.put(
      '/gifts/admin/groups/$groupId/gifts',
      data: {'gifts': gifts.map((item) => item.toJson()).toList()},
    );
    return parseGiftGroup(response.data);
  }
}
