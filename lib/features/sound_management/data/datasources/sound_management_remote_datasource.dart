import 'package:dio/dio.dart';

import '../../domain/entities/sound_entities.dart';
import '../models/sound_models.dart';

abstract class SoundManagementRemoteDataSource {
  Future<SoundOverviewEntity> getOverview();
  Future<PaginatedSoundsEntity> getSounds(SoundsQuery query);
  Future<SoundEntity> createSound(CreateSoundData data);
  Future<SoundEntity> uploadSound(UploadSoundData data);
  Future<SoundEntity> updateSound(String soundId, UpdateSoundData data);
  Future<SoundEntity> activateSound(String soundId);
  Future<SoundEntity> deactivateSound(String soundId);
  Future<void> deleteSound(String soundId);
  Future<BulkSoundActionResultEntity> bulkAction(BulkSoundActionRequest request);
}

class SoundManagementRemoteDataSourceImpl
    implements SoundManagementRemoteDataSource {
  const SoundManagementRemoteDataSourceImpl(this._dio);
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

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }
    return error.message ?? error.toString();
  }

  @override
  Future<SoundOverviewEntity> getOverview() async {
    final response = await _dio.get('/sounds/admin/overview');
    return SoundOverviewModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedSoundsEntity> getSounds(SoundsQuery query) async {
    final response = await _dio.get(
      '/sounds/admin/all',
      queryParameters: query.toQueryParameters(),
    );
    return PaginatedSoundsModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<SoundEntity> createSound(CreateSoundData data) async {
    final response = await _dio.post('/sounds/admin', data: data.toJson());
    return SoundModel.fromJson(_map(response.data));
  }

  @override
  Future<SoundEntity> uploadSound(UploadSoundData data) async {
    final form = FormData();
    form.files.add(
      MapEntry(
        'audio',
        MultipartFile.fromBytes(data.bytes, filename: data.filename),
      ),
    );
    form.fields.addAll([
      MapEntry('name', data.name),
      MapEntry('author', data.author),
      MapEntry('duration', '${data.duration}'),
    ]);
    if (data.coverBytes != null &&
        data.coverBytes!.isNotEmpty &&
        data.coverFilename != null) {
      form.files.add(
        MapEntry(
          'coverUrl',
          MultipartFile.fromBytes(
            data.coverBytes!,
            filename: data.coverFilename!,
          ),
        ),
      );
    }

    final response = await _dio.post(
      '/sounds/admin/upload',
      data: form,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    return SoundModel.fromJson(_map(response.data));
  }

  @override
  Future<SoundEntity> updateSound(
    String soundId,
    UpdateSoundData data,
  ) async {
    final response = await _dio.patch(
      '/sounds/admin/$soundId',
      data: data.toJson(),
    );
    return SoundModel.fromJson(_map(response.data));
  }

  @override
  Future<SoundEntity> activateSound(String soundId) async {
    final response = await _dio.patch('/sounds/admin/$soundId/activate');
    return SoundModel.fromJson(_map(response.data));
  }

  @override
  Future<SoundEntity> deactivateSound(String soundId) async {
    final response = await _dio.patch('/sounds/admin/$soundId/deactivate');
    return SoundModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deleteSound(String soundId) async {
    try {
      await _dio.delete('/sounds/admin/$soundId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<BulkSoundActionResultEntity> bulkAction(
    BulkSoundActionRequest request,
  ) async {
    final response = await _dio.post(
      '/sounds/admin/bulk',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return BulkSoundActionResultModel.fromJson(
        data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data,
      );
    }
    throw Exception('Invalid bulk action response');
  }
}
