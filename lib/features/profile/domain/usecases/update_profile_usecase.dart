import '../entities/profile_entity.dart';
import '../entities/update_profile_data.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<ProfileEntity> call(UpdateProfileData data, {String? userId}) =>
      _repository.updateMe(data, userId: userId);
}
