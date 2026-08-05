import 'dart:typed_data';

import '../entities/profile_entity.dart';
import '../entities/update_profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileEntity> getProfile(String userId);

  Future<ProfileEntity> updateMe(UpdateProfileData data, {String? userId});

  /// Uploads avatar bytes and returns an absolute avatar URL.
  Future<String> uploadAvatar(Uint8List bytes, String filename);
}
