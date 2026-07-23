import 'package:dio/dio.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/repositories/stories_repository.dart';
import '../datasources/stories_remote_data_source.dart';
import '../models/story_model.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  const StoriesRepositoryImpl(this._remoteDataSource);

  final StoriesRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, PaginatedStoriesEntity>> getStories(
    StoryQuery query,
  ) async {
    try {
      final page = await _remoteDataSource.getStories(query);
      return Either.right(page);
    } on DioException catch (e) {
      return Either.left(_failureFromDio(e, 'Failed to load stories'));
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoryEntity>> updateStory(
    UpdateStoryParams params,
  ) async {
    try {
      final body = UpdateStoryRequestModel.fromParams(params);
      final story = await _remoteDataSource.updateStory(params.id, body);
      return Either.right(story);
    } on DioException catch (e) {
      return Either.left(_failureFromDio(e, 'Failed to update story'));
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteStory(String id) async {
    try {
      final success = await _remoteDataSource.deleteStory(id);
      return Either.right(success);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Either.left(const ServerFailure('Story not found'));
      }
      return Either.left(_failureFromDio(e, 'Failed to delete story'));
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  Failure _failureFromDio(DioException e, String fallback) {
    final message = e.response?.data is Map
        ? (e.response!.data as Map)['message']?.toString()
        : null;
    return ServerFailure(message ?? e.message ?? fallback);
  }
}
