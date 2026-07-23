import '../../../../core/error/either.dart';
import '../../../../core/error/failure.dart';
import '../repositories/stories_repository.dart';

class DeleteStoryUseCase {
  const DeleteStoryUseCase(this._repository);

  final StoriesRepository _repository;

  Future<Either<Failure, bool>> call(String id) {
    return _repository.deleteStory(id);
  }
}
