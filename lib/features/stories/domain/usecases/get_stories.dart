import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../entities/story_entity.dart';
import '../repositories/stories_repository.dart';

class GetStoriesUseCase {
  const GetStoriesUseCase(this._repository);

  final StoriesRepository _repository;

  Future<Either<Failure, PaginatedStoriesEntity>> call(StoryQuery query) {
    return _repository.getStories(query);
  }
}
