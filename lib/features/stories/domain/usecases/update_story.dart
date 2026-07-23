import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../entities/story_entity.dart';
import '../repositories/stories_repository.dart';

class UpdateStoryUseCase {
  const UpdateStoryUseCase(this._repository);

  final StoriesRepository _repository;

  Future<Either<Failure, StoryEntity>> call(UpdateStoryParams params) {
    return _repository.updateStory(params);
  }
}
