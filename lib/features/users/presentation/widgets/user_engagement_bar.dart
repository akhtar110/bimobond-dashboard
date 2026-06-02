import 'package:flutter/material.dart';

import '../../domain/entities/user_entity.dart';

class UserEngagementBar extends StatelessWidget {
  const UserEngagementBar({super.key, required this.user});

  final UserEntity user;

  static double percentFor(UserEntity user) {
    final raw = (user.postCount / (user.followerCount + 1)) * 100;
    return raw.clamp(0, 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percent = percentFor(user);
    final primary = theme.colorScheme.primary;

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);
    final fillGradient = LinearGradient(
      colors: [
        primary.withValues(alpha: 0.85),
        primary,
      ],
    );

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: trackColor),
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: percent / 100,
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: fillGradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '${percent.round()}%',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
