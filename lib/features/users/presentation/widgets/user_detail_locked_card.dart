import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';

/// Informational card shown when the API returns a locked profile card.
/// Admins normally receive the full profile, but this guards against partial
/// responses and documents why activity tabs are hidden.
class UserDetailLockedCard extends StatelessWidget {
  const UserDetailLockedCard({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_rounded, size: 36, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tOr('lockedProfileTitle', 'This account is private'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tOr(
              'lockedProfileMessage',
              'Follow this user to view posts and social activity.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
