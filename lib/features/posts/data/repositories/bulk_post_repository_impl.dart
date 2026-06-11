import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../domain/entities/bulk_post_action_request.dart';
import '../../domain/entities/bulk_post_action_result.dart';
import '../../domain/repositories/bulk_post_repository.dart';
import '../datasources/bulk_posts_remote_datasource.dart';
import '../mappers/bulk_post_mapper.dart';
import '../models/bulk_single_post_result.dart';

class BulkPostRepositoryImpl implements BulkPostRepository {
  BulkPostRepositoryImpl(this._remoteDataSource);

  final BulkPostsRemoteDataSource _remoteDataSource;

  static const _batchSize = 8;

  @override
  Future<BulkPostActionResult> executeBulkAction(
    BulkPostActionRequest request,
  ) async {
    if (request.postIds.isEmpty) {
      return const BulkPostActionResult(
        updatedPosts: [],
        removedPostIds: [],
        failedPostIds: [],
      );
    }

    if (BulkPostMapper.usesAdminBulkApi(request.action)) {
      return _executeViaAdminBulkApi(request);
    }

    return _executeViaIndividualCalls(request);
  }

  Future<BulkPostActionResult> _executeViaAdminBulkApi(
    BulkPostActionRequest request,
  ) async {
    try {
      final dto = BulkPostMapper.toAdminBulkDto(
        postIds: request.postIds,
        action: request.action,
      );
      final result = await _remoteDataSource.executeAdminBulkAction(dto);

      return BulkPostActionResult(
        updatedPosts: const [],
        succeededPostIds: result.affectedPostIds,
        removedPostIds:
            result.isDelete ? result.affectedPostIds : const [],
        failedPostIds: result.failedPostIds,
        errorMessage: result.isFullSuccess
            ? null
            : '${result.failedPostIds.length} post(s) could not be updated',
      );
    } catch (e) {
      return BulkPostActionResult(
        updatedPosts: const [],
        removedPostIds: const [],
        failedPostIds: request.postIds,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<BulkPostActionResult> _executeViaIndividualCalls(
    BulkPostActionRequest request,
  ) async {
    final updatedPosts = <ManagedPostEntity>[];
    final removedPostIds = <String>[];
    final failedPostIds = <String>[];

    for (var i = 0; i < request.postIds.length; i += _batchSize) {
      final batch = request.postIds.skip(i).take(_batchSize).toList();
      final outcomes = await Future.wait(
        batch.map((postId) async {
          try {
            return await _remoteDataSource.applyBulkActionToPost(
              postId: postId,
              action: request.action,
            );
          } catch (_) {
            return null;
          }
        }),
      );

      for (var j = 0; j < batch.length; j++) {
        final outcome = outcomes[j];
        final postId = batch[j];
        switch (outcome) {
          case BulkSinglePostUpdated(:final post):
            updatedPosts.add(post);
          case BulkSinglePostRemoved(:final postId):
            removedPostIds.add(postId);
          case null:
            failedPostIds.add(postId);
        }
      }
    }

    return BulkPostActionResult(
      updatedPosts: updatedPosts,
      succeededPostIds: [
        ...updatedPosts.map((p) => p.id),
        ...removedPostIds,
      ],
      removedPostIds: removedPostIds,
      failedPostIds: failedPostIds,
      errorMessage: failedPostIds.isEmpty
          ? null
          : '${failedPostIds.length} post(s) could not be updated',
    );
  }
}
