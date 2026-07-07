import 'package:dio/dio.dart';

import '../../../sound_management/data/models/sound_models.dart';
import '../../../sound_management/domain/entities/sound_entities.dart';
import '../../domain/entities/create_post_location_entity.dart';

abstract class CreatePostAuxiliaryRemoteDataSource {
  Future<List<SoundEntity>> searchSounds({
    required int page,
    required int limit,
    String? search,
  });

  Future<List<SoundEntity>> getTrendingSounds();

  Future<SoundEntity> uploadSound({
    required List<int> bytes,
    required String filename,
    required String name,
    required int duration,
  });

  Future<List<CreatePostLocationEntity>> searchLocations({
    required String query,
    required int page,
    required int limit,
  });
}

class CreatePostAuxiliaryRemoteDataSourceImpl
    implements CreatePostAuxiliaryRemoteDataSource {
  const CreatePostAuxiliaryRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  Map<String, dynamic> _map(Object? data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    return const {};
  }

  Map<String, dynamic> _unwrapPaginated(Object? data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data.containsKey('meta')) {
        return data;
      }
      final nested = data['data'];
      if (nested is Map<String, dynamic> &&
          nested.containsKey('data') &&
          nested.containsKey('meta')) {
        return nested;
      }
    }
    return const {'data': [], 'meta': {}};
  }

  List<SoundEntity> _parseSoundList(Object? data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(SoundModel.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final paginated = PaginatedSoundsModel.fromJson(_unwrapPaginated(data));
      return paginated.data;
    }
    return const [];
  }

  CreatePostLocationEntity _parseLocation(Map<String, dynamic> json) {
    return CreatePostLocationEntity(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      countryCode: json['countryCode']?.toString(),
      placeId: json['placeId']?.toString(),
    );
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Future<List<SoundEntity>> searchSounds({
    required int page,
    required int limit,
    String? search,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final trimmed = search?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      params['search'] = trimmed;
    }

    final response = await _dio.get('/sounds', queryParameters: params);
    return _parseSoundList(response.data);
  }

  @override
  Future<List<SoundEntity>> getTrendingSounds() async {
    final response = await _dio.get('/sounds/trending');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) return _parseSoundList(nested);
      if (nested is Map<String, dynamic>) {
        return _parseSoundList(nested['data'] ?? nested['sounds']);
      }
    }
    return _parseSoundList(data);
  }

  @override
  Future<SoundEntity> uploadSound({
    required List<int> bytes,
    required String filename,
    required String name,
    required int duration,
  }) async {
    final form = FormData();
    form.files.add(
      MapEntry(
        'audio',
        MultipartFile.fromBytes(bytes, filename: filename),
      ),
    );
    form.fields.addAll([
      MapEntry('name', name),
      MapEntry('duration', '$duration'),
    ]);

    final response = await _dio.post(
      '/sounds/upload',
      data: form,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    return SoundModel.fromJson(_map(response.data));
  }

  @override
  Future<List<CreatePostLocationEntity>> searchLocations({
    required String query,
    required int page,
    required int limit,
  }) async {
    try {
      final response = await _dio.get(
        '/locations/search',
        queryParameters: {
          'q': query.trim(),
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'];
        if (nested is List) {
          return nested
              .whereType<Map<String, dynamic>>()
              .map(_parseLocation)
              .where((l) => l.name.trim().isNotEmpty)
              .toList();
        }
      }
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(_parseLocation)
            .where((l) => l.name.trim().isNotEmpty)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }
}
