import 'package:flutter/material.dart';

import '../../domain/entities/user_entity.dart';
import 'user_location_intelligence_panel.dart';

class UserDetailLocationsTab extends StatelessWidget {
  const UserDetailLocationsTab({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return UserLocationIntelligencePanel(
      fixedUser: user,
      embedded: true,
    );
  }
}
