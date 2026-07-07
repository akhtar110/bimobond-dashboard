import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg, String label) = switch (true) {
      _ when user.isBanned => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          l10n.t('banned').toUpperCase(),
        ),
      _ when user.isVerified => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          l10n.t('verified').toUpperCase(),
        ),
      _ => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          l10n.t('active').toUpperCase(),
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: fg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
