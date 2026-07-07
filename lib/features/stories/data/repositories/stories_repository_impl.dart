import 'package:dio/dio.dart';

import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/active_story_entity.dart';
import '../../domain/repositories/stories_repository.dart';
import '../datasources/stories_remote_data_source.dart';

class StoriesRepositoryImpl implements StoriesRepository {
  const StoriesRepositoryImpl(this._remoteDataSource);

  final StoriesRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<ActiveStoryEntity>>> getActiveStories() async {
    try {
      final stories = await _remoteDataSource.getActiveStories();
      return Either.right(stories);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return Either.left(
        ServerFailure(message ?? e.message ?? 'Failed to load active stories'),
      );
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
