import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../search_history/presentation/widgets/search_history_user_panel.dart';
import '../../domain/entities/user_entity.dart';
import 'permission_denied_state.dart';

class UserDetailSearchHistoryTab extends StatelessWidget {
  const UserDetailSearchHistoryTab({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PermissionGate(
      permission: RbacPermissionKeys.searchHistory,
      allowLegacyAdmin: true,
      fallback: PermissionDeniedState(
        message: l10n.tOr(
          'searchHistoryPermissionDenied',
          'You do not have permission to view search history.',
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SearchHistoryUserPanel(
          userId: user.id,
          embedded: true,
        ),
      ),
    );
  }
}
