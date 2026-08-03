import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/update_profile_data.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileEntity> getProfile(String userId);

  Future<ProfileEntity> updateMe(UpdateProfileData data, {String? userId});

  Future<String> uploadAvatar(Uint8List bytes, String filename);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _requestTimeout = Duration(seconds: 15);

  @override
  Future<ProfileEntity> getProfile(String userId) async {
    try {
      final response = await _dio.get(
        '/users/$userId',
        options: Options(
          sendTimeout: _requestTimeout,
          receiveTimeout: _requestTimeout,
        ),
      );
      return ProfileModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<ProfileEntity> updateMe(UpdateProfileData data, {String? userId}) async {
    try {
      final payload = data.toJson();
      if (payload.isEmpty) {
        if (userId != null && userId.isNotEmpty) {
          return await getProfile(userId);
        }
      }

      Response response;
      if (userId != null && userId.isNotEmpty) {
        try {
          response = await _dio.patch(
            '/users/admin/$userId',
            data: payload,
            options: Options(
              sendTimeout: _requestTimeout,
              receiveTimeout: _requestTimeout,
            ),
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
            response = await _dio.patch(
              '/users/me',
              data: payload,
              options: Options(
                sendTimeout: _requestTimeout,
                receiveTimeout: _requestTimeout,
              ),
            );
          } else {
            rethrow;
          }
        }
      } else {
        response = await _dio.patch(
          '/users/me',
          data: payload,
          options: Options(
            sendTimeout: _requestTimeout,
            receiveTimeout: _requestTimeout,
          ),
        );
      }

      return ProfileModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<String> uploadAvatar(Uint8List bytes, String filename) async {
    try {
      final formData = FormData();
      formData.files.add(
        MapEntry(
          'file',
          MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: _contentTypeFor(filename),
          ),
        ),
      );

      final response = await _dio.post(
        '/users/avatar',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final url = _parseUploadUrl(response.data);
      if (url == null || url.isEmpty) {
        throw Exception('Avatar upload failed: no URL returned');
      }

      final absolute = resolveMediaUrl(url) ?? url;
      return absolute;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw Exception('Unexpected profile response shape');
  }

  String? _parseUploadUrl(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final direct = map['url']?.toString();
      if (direct != null && direct.isNotEmpty) return direct;
      final nested = map['data'];
      if (nested is Map) {
        final nestedUrl = nested['url']?.toString();
        if (nestedUrl != null && nestedUrl.isNotEmpty) return nestedUrl;
      }
    }
    return null;
  }

  DioMediaType _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return DioMediaType('image', 'jpeg');
    }
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
    if (lower.endsWith('.svg')) return DioMediaType('image', 'svg+xml');
    return DioMediaType('image', 'jpeg');
  }

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return Exception('Connection timeout. Please check server availability.');
    }

    final status = e.response?.statusCode;
    final message = _extractMessage(e);

    if (status == 409) {
      return Exception(message ?? 'Username is already taken');
    }
    if (status == 404) {
      return Exception(message ?? 'User not found');
    }
    if (status == 400) {
      return Exception(message ?? 'Validation error in submitted profile data');
    }
    if (status == 403) {
      return Exception(message ?? 'Forbidden: missing permissions to update profile');
    }
    return Exception(message ?? e.message ?? 'Request failed');
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      if (msg is List && msg.isNotEmpty) {
        return msg.map((e) => e.toString()).join(', ');
      }
      final error = data['error']?.toString();
      if (error != null && error.trim().isNotEmpty) return error.trim();
    }
    return null;
  }
}
