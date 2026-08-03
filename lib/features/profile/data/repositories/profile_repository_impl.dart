import 'dart:typed_data';

import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/update_profile_data.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<ProfileEntity> getProfile(String userId) => _remote.getProfile(userId);

  @override
  Future<ProfileEntity> updateMe(UpdateProfileData data, {String? userId}) =>
      _remote.updateMe(data, userId: userId);

  @override
  Future<String> uploadAvatar(Uint8List bytes, String filename) =>
      _remote.uploadAvatar(bytes, filename);
}
