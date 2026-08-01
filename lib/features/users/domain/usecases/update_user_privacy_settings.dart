import '../entities/message_permission.dart';
import '../entities/update_user_admin_request.dart';
import '../repositories/users_repository.dart';

/// Admin privacy update via `PATCH /users/admin/:id`.
class UpdateUserPrivacySettings {
  const UpdateUserPrivacySettings(this.repository);

  final UsersRepository repository;

  Future<void> call(
    String userId, {
    bool? isPrivate,
    bool? allowComments,
    bool? allowDirectMsgs,
    MessagePermission? messagePermission,
  }) {
    final request = UpdateUserAdminRequest(
      isPrivate: isPrivate,
      allowComments: allowComments,
      allowDirectMsgs: allowDirectMsgs,
      messagePermission: messagePermission?.apiValue,
    );
    if (request.isEmpty) return Future.value();
    return repository.updateAdminUser(userId, data: request.toJson());
  }
}
