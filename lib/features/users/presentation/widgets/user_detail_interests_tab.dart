import 'package:flutter/material.dart';

import '../../../user_interests/presentation/widgets/user_interests_panel.dart';
import '../../domain/entities/user_entity.dart';

class UserDetailInterestsTab extends StatelessWidget {
  const UserDetailInterestsTab({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: UserInterestsPanel(
        userId: user.id,
        embedded: true,
      ),
    );
  }
}
