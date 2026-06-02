import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final (bg, fg, label) = switch (true) {
      _ when user.isBanned => (
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          l10n.t('banned').toUpperCase(),
        ),
      _ when user.isVerified => (
          const Color(0xFFCCFBF1),
          const Color(0xFF0F766E),
          l10n.t('verified').toUpperCase(),
        ),
      _ => (
          const Color(0xFFD1FAE5),
          const Color(0xFF047857),
          l10n.t('active').toUpperCase(),
        ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkBg = fg.withValues(alpha: 0.15);
    final darkFg = fg.withValues(alpha: 0.95);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? darkBg : bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: isDark ? 0.35 : 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: isDark ? darkFg : fg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
