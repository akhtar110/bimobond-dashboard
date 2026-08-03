import 'package:flutter/material.dart';

import 'sidebar_user_profile.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({
    super.key,
    required this.collapsed,
    this.onDestinationSelected,
    this.currentIndex,
  });

  final bool collapsed;
  final ValueChanged<int>? onDestinationSelected;
  final int? currentIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 4),
        SidebarUserProfile(
          collapsed: collapsed,
          onDestinationSelected: onDestinationSelected,
          currentIndex: currentIndex,
        ),
      ],
    );
  }
}
