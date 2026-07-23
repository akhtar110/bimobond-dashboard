import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/sound_entities.dart';
import '../../domain/entities/sound_group_entities.dart';
import '../models/sound_group_models.dart';
import '../models/sound_models.dart';

abstract class SoundManagementRemoteDataSource {
  Future<SoundOverviewEntity> getOverview();
  Future<PaginatedSoundsEntity> getSounds(SoundsQuery query);
  Future<SoundEntity> getSoundById(String soundId);
  Future<SoundEntity> createSound(CreateSoundData data);
  Future<SoundEntity> uploadSound(UploadSoundData data);
  Future<String> uploadSoundFile(Uint8List bytes, String filename);
  Future<SoundEntity> updateSound(String soundId, UpdateSoundData data);
  Future<SoundEntity> activateSound(String soundId);
  Future<SoundEntity> deactivateSound(String soundId);
  Future<void> deleteSound(String soundId);
  Future<BulkSoundActionResultEntity> bulkAction(BulkSoundActionRequest request);

  Future<List<SoundGroupEntity>> getSoundGroups();
  Future<SoundGroupEntity> createSoundGroup(CreateSoundGroupData data);
  Future<List<SoundGroupEntity>> reorderSoundGroups(
    List<SoundGroupReorderItem> items,
  );
  Future<SoundGroupEntity> updateSoundGroup(
    String groupId,
    UpdateSoundGroupData data,
  );
  Future<void> deleteSoundGroup(String groupId);
  Future<SoundGroupEntity> replaceGroupSounds(
    String groupId,
    List<SoundGroupMembershipItem> sounds,
  );
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
  Future<SoundEntity> getSoundById(String soundId) async {
    final response = await _dio.get('/sounds/admin/$soundId');
    return SoundModel.fromJson(_map(response.data));
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
  Future<String> uploadSoundFile(Uint8List bytes, String filename) async {
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
        url = _parseUploadUrl(urls.first);
      }
    } else if (data is List && data.isNotEmpty) {
      url = _parseUploadUrl(data.first);
    }

    if (url == null || url.isEmpty) {
      throw Exception('Image upload failed: no URL returned');
    }
    return resolveMediaUrl(url) ?? url;
  }

  String _parseUploadUrl(dynamic entry) {
    if (entry is String) return entry;
    if (entry is Map<String, dynamic>) {
      return (entry['url'] ?? entry['path'] ?? '').toString();
    }
    return '';
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

  @override
  Future<List<SoundGroupEntity>> getSoundGroups() async {
    final response = await _dio.get('/sounds/admin/groups');
    return parseSoundGroupList(response.data);
  }

  @override
  Future<SoundGroupEntity> createSoundGroup(CreateSoundGroupData data) async {
    final response = await _dio.post('/sounds/admin/groups', data: data.toJson());
    return parseSoundGroup(response.data);
  }

  @override
  Future<List<SoundGroupEntity>> reorderSoundGroups(
    List<SoundGroupReorderItem> items,
  ) async {
    final response = await _dio.patch(
      '/sounds/admin/groups/reorder',
      data: {
        'items': items.map((item) => item.toJson()).toList(),
      },
    );
    return parseSoundGroupList(response.data);
  }

  @override
  Future<SoundGroupEntity> updateSoundGroup(
    String groupId,
    UpdateSoundGroupData data,
  ) async {
    final response = await _dio.patch(
      '/sounds/admin/groups/$groupId',
      data: data.toJson(),
    );
    return parseSoundGroup(response.data);
  }

  @override
  Future<void> deleteSoundGroup(String groupId) async {
    try {
      await _dio.delete('/sounds/admin/groups/$groupId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  @override
  Future<SoundGroupEntity> replaceGroupSounds(
    String groupId,
    List<SoundGroupMembershipItem> sounds,
  ) async {
    final response = await _dio.put(
      '/sounds/admin/groups/$groupId/sounds',
      data: {
        'sounds': sounds.map((item) => item.toJson()).toList(),
      },
    );
    return parseSoundGroup(response.data);
  }
}
