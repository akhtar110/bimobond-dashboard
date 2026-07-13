import 'package:flutter/material.dart';

import '../../domain/entities/user_admin_action_type.dart';

extension UserAdminActionPresentation on UserAdminActionType {
  IconData get icon => switch (this) {
        UserAdminActionType.ban => Icons.block_rounded,
        UserAdminActionType.unban => Icons.lock_open_rounded,
        UserAdminActionType.promote => Icons.arrow_upward_rounded,
        UserAdminActionType.demote => Icons.arrow_downward_rounded,
        UserAdminActionType.delete => Icons.delete_outline_rounded,
      };
}
