import 'package:flutter/material.dart';

import '../../domain/entities/user_entity.dart';

class UserEngagementBar extends StatelessWidget {
  const UserEngagementBar({
    super.key,
    required this.user,
    this.compact = false,
  });

  final UserEntity user;
  final bool compact;

  static String formatCount(int? n) {
    if (n == null || n < 0) return '0';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);

    if (compact) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _metric(Icons.people_outline, formatCount(user.followerCount), style),
            const SizedBox(width: 8),
            _metric(Icons.grid_view_rounded, formatCount(user.postCount), style),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _metric(Icons.people_outline, formatCount(user.followerCount), style),
          const SizedBox(width: 8),
          _metric(Icons.person_add_outlined, formatCount(user.followingCount), style),
          const SizedBox(width: 8),
          _metric(Icons.grid_view_rounded, formatCount(user.postCount), style),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: style.color),
        const SizedBox(width: 3),
        Text(value, style: style),
      ],
    );
  }
}
