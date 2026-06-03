import 'package:dio/dio.dart';

import '../../domain/create_post_payload_builder.dart';
import '../../domain/entities/local_media_file.dart';
import '../models/create_post_dto.dart';

abstract class CreatePostRemoteDataSource {
  Future<List<String>> uploadMediaFiles(List<LocalMediaFile> files);

  Future<Map<String, dynamic>> createPost(CreatePostDto dto);
}

class CreatePostRemoteDataSourceImpl implements CreatePostRemoteDataSource {
  CreatePostRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<String>> uploadMediaFiles(List<LocalMediaFile> files) async {
    if (files.isEmpty) return [];

    final multipart = <MultipartFile>[];
    for (final file in files) {
      multipart.add(
        MultipartFile.fromBytes(
          file.bytes,
          filename: file.name,
        ),
      );
    }

    final formData = FormData();
    for (final part in multipart) {
      formData.files.add(MapEntry('files', part));
    }

    // Dio automatically sets 'multipart/form-data; boundary=...' for FormData.
    // Do NOT override contentType manually — that causes a Dio conflict error.
    final response = await _dio.post(
      '/posts/upload',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    final data = response.data;
    print("Data received from uploading the post $data");
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      final urls = data['urls'] ??
          (nested is Map<String, dynamic> ? nested['urls'] : null);
      if (urls is List) {
        return urls
            .map(CreatePostPayloadBuilder.parseUploadUrlEntry)
            .toList(growable: false);
      }
    }
    if (data is List) {
      return data
          .map(CreatePostPayloadBuilder.parseUploadUrlEntry)
          .toList(growable: false);
    }
    throw Exception('Invalid upload response');
  }

  @override
  Future<Map<String, dynamic>> createPost(CreatePostDto dto) async {
    final response = await _dio.post(
      '/posts',
      data: dto.toJson(),
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }
}
