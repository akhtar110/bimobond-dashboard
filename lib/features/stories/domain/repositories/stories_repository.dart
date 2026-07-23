import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../entities/story_entity.dart';

abstract class StoriesRepository {
  Future<Either<Failure, PaginatedStoriesEntity>> getStories(StoryQuery query);

  Future<Either<Failure, StoryEntity>> updateStory(UpdateStoryParams params);

  Future<Either<Failure, bool>> deleteStory(String id);
}
