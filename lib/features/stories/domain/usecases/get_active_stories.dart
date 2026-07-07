import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../entities/active_story_entity.dart';
import '../repositories/stories_repository.dart';

class GetActiveStories {
  const GetActiveStories(this._repository);

  final StoriesRepository _repository;

  Future<Either<Failure, List<ActiveStoryEntity>>> call() {
    return _repository.getActiveStories();
  }
}
