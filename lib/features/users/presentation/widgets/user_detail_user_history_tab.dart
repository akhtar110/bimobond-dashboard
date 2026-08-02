import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../user_history/presentation/widgets/user_history_tab.dart';
import '../../domain/entities/user_entity.dart';
import 'permission_denied_state.dart';

class UserDetailUserHistoryTab extends StatelessWidget {
  const UserDetailUserHistoryTab({
    super.key,
    required this.user,
    required this.isDark,
  });

  final UserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PermissionGate(
      permission: RbacPermissionKeys.activityAdminRead,
      allowLegacyAdmin: true,
      fallback: PermissionDeniedState(
        message: l10n.tOr(
          'userHistoryPermissionDenied',
          'You do not have permission to view user history.',
        ),
      ),
      child: UserHistoryTab(
        key: ValueKey('user-history-${user.id}'),
        isDark: isDark,
        sourceUser: user,
      ),
    );
  }
}
