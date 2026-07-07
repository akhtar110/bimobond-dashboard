import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../entities/active_story_entity.dart';

abstract class StoriesRepository {
  Future<Either<Failure, List<ActiveStoryEntity>>> getActiveStories();
}
