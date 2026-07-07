import 'package:flutter/material.dart';

import '../../domain/entities/user_entity.dart';
import '../../../search_history/presentation/widgets/search_history_user_panel.dart';

class UserDetailSearchHistoryTab extends StatelessWidget {
  const UserDetailSearchHistoryTab({
    super.key,
    required this.user,
  });

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SearchHistoryUserPanel(
        userId: user.id,
        embedded: true,
      ),
    );
  }
}
