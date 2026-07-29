import 'package:flutter/material.dart';

import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/user_entity.dart';
import 'permission_denied_state.dart';
import 'user_location_intelligence_panel.dart';

class UserDetailLocationsTab extends StatelessWidget {
  const UserDetailLocationsTab({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permission: RbacPermissionKeys.userLocations,
      allowLegacyAdmin: true,
      fallback: const PermissionDeniedState(
        message: 'You do not have permission to view user locations.',
      ),
      child: UserLocationIntelligencePanel(
        fixedUser: user,
        embedded: true,
      ),
    );
  }
}
