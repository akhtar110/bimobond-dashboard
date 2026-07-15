import 'package:flutter/material.dart';

import '../widgets/user_interests_panel.dart';

/// Standalone page shell (optional admin entry). Primary use is embedded tab.
class UserInterestsPage extends StatelessWidget {
  const UserInterestsPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: UserInterestsPanel(userId: userId),
      ),
    );
  }
}
