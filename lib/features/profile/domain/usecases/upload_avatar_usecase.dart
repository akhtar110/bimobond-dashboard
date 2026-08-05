import 'dart:typed_data';

import '../repositories/profile_repository.dart';

class UploadAvatarUseCase {
  const UploadAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  Future<String> call(Uint8List bytes, String filename) =>
      _repository.uploadAvatar(bytes, filename);
}
