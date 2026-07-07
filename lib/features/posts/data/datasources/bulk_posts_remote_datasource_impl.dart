import 'package:dio/dio.dart';

import '../../../../features/post_management/data/models/managed_post_model.dart';
import '../../domain/enums/bulk_post_action_type.dart';
import '../mappers/bulk_post_mapper.dart';
import '../models/admin_bulk_post_action.dart';
import '../models/admin_bulk_posts_dto.dart';
import '../models/bulk_admin_action_result.dart';
import '../models/bulk_single_post_result.dart';
import 'bulk_posts_remote_datasource.dart';

class BulkPostsRemoteDataSourceImpl implements BulkPostsRemoteDataSource {
  BulkPostsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static const _bulkPath = '/posts/admin/bulk';

  @override
  Future<BulkAdminActionResult> executeAdminBulkAction(
    AdminBulkPostsDto dto,
  ) async {
    final response = await _dio.post(_bulkPath, data: dto.toJson());
    return _parseBulkResponse(dto, response.data);
  }

  BulkAdminActionResult _parseBulkResponse(
    AdminBulkPostsDto dto,
    dynamic data,
  ) {
    final isDelete = dto.action == AdminBulkPostAction.delete;

    if (data is! Map<String, dynamic>) {
      return BulkAdminActionResult(
        affectedPostIds: dto.postIds,
        isDelete: isDelete,
      );
    }

    final nested = data['data'] ?? data;
    if (nested is! Map<String, dynamic>) {
      return BulkAdminActionResult(
        affectedPostIds: dto.postIds,
        isDelete: isDelete,
      );
    }

    final failed = _readStringList(
      nested['failedPostIds'] ?? nested['failedIds'] ?? nested['errors'],
    );
    final succeeded = _readStringList(
      nested['succeededPostIds'] ??
          nested['successPostIds'] ??
          nested['affectedPostIds'] ??
          nested['postIds'],
    );

    final affected = succeeded.isNotEmpty
        ? succeeded
        : dto.postIds.where((id) => !failed.contains(id)).toList();

    return BulkAdminActionResult(
      affectedPostIds: affected,
      failedPostIds: failed,
      isDelete: isDelete,
    );
  }

  List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  @override
  Future<BulkSinglePostResult> applyBulkActionToPost({
    required String postId,
    required BulkPostActionType action,
  }) async {
    if (action == BulkPostActionType.feature ||
        action == BulkPostActionType.unfeature) {
      final response = await _dio.patch(
        '/posts/admin/$postId',
        data: {'isFeatured': action == BulkPostActionType.feature},
      );
      return BulkSinglePostUpdated(
        BulkPostMapper.toEntity(_parsePostResponse(response.data)),
      );
    }

    final updateData = BulkPostMapper.updateDataFor(action);
    final response = await _dio.patch(
      '/posts/admin/$postId',
      data: ManagedPostModel.updatePayload(updateData),
    );
    return BulkSinglePostUpdated(
      BulkPostMapper.toEntity(_parsePostResponse(response.data)),
    );
  }

  ManagedPostModel _parsePostResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['post'] ?? data;
      if (nested is Map<String, dynamic>) {
        return ManagedPostModel.fromJson(nested);
      }
    }
    throw FormatException('Unexpected post response: $data');
  }
}
