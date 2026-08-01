import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/location_data_cache.dart';
import '../../domain/entities/managed_post_location_entity.dart';
import '../models/managed_post_model.dart';

abstract class ManagedPostLocationRemoteDataSource {
  Future<ManagedPostLocationEntity?> fetchById(String locationId);

  /// Fetches location embedded in post detail (`GET /posts/:id?detail=1`).
  Future<ManagedPostLocationEntity?> fetchFromPostDetail(String postId);
}

class ManagedPostLocationRemoteDataSourceImpl
    implements ManagedPostLocationRemoteDataSource {
  ManagedPostLocationRemoteDataSourceImpl(
    this._dio, {
    LocationDataCache? cache,
  }) : _cache = cache ?? LocationDataCache.instance;

  final Dio _dio;
  final LocationDataCache _cache;

  @override
  Future<ManagedPostLocationEntity?> fetchById(String locationId) async {
    final id = locationId.trim();
    if (id.isEmpty) return null;

    if (_cache.hasLocationByIdEntry(id)) {
      return _cache.getLocationById(id);
    }

    const paths = ['/locations/', '/locations/admin/'];
    for (final prefix in paths) {
      try {
        final response = await _dio.get('$prefix$id');
        final payload = response.data;
        if (payload is Map<String, dynamic>) {
          final nested = payload['data'];
          final map = nested is Map<String, dynamic> ? nested : payload;
          final location = ManagedPostLocationEntity.fromJson(map);
          if (location != null) {
            _cache.putLocationById(id, location);
            return location;
          }
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) continue;
        if (kDebugMode) {
          debugPrint('[Location] fetch failed ($prefix$id): $e');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Location] fetch failed ($prefix$id): $e');
        }
      }
    }
    _cache.putLocationById(id, null);
    return null;
  }

  @override
  Future<ManagedPostLocationEntity?> fetchFromPostDetail(String postId) async {
    final id = postId.trim();
    if (id.isEmpty) return null;

    if (_cache.hasLocationByPostIdEntry(id)) {
      return _cache.getLocationByPostId(id);
    }

    try {
      final response = await _dio.get(
        '/posts/$id',
        queryParameters: const {'detail': 1},
      );
      final model = _parsePostPayload(response.data);
      if (model.location?.hasDisplayData == true) {
        _cache.putLocationByPostId(id, model.location);
        return model.location;
      }

      final locationId = model.locationId?.trim();
      if (locationId != null && locationId.isNotEmpty) {
        final location = await fetchById(locationId);
        _cache.putLocationByPostId(id, location);
        return location;
      }

      // Public detail succeeded but carries no location — do not retry admin path.
      _cache.putLocationByPostId(id, null);
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _cache.putLocationByPostId(id, null);
        return null;
      }
      if (kDebugMode) {
        debugPrint('[Location] post detail fetch failed (/posts/$id): $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Location] post detail fetch failed (/posts/$id): $e');
      }
    }
    _cache.putLocationByPostId(id, null);
    return null;
  }

  ManagedPostModel _parsePostPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['post'] is Map<String, dynamic>
          ? data['post'] as Map<String, dynamic>
          : data;
      return ManagedPostModel.fromJson(payload);
    }
    throw Exception('Invalid post response format');
  }
}
