import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_entity.dart';

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ],
      ),
    );
    if (tooltip == null) return badge;
    return Tooltip(message: tooltip!, child: badge);
  }
}

class UserPrivacyBadge extends StatelessWidget {
  const UserPrivacyBadge({super.key, required this.user, this.compact = false});

  final UserEntity user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (user.isProfileLocked) {
      return _MiniBadge(
        icon: Icons.lock_person_rounded,
        label: compact ? '' : l10n.tOr('lockedProfileIndicator', 'Locked'),
        foreground: scheme.onErrorContainer,
        background: scheme.errorContainer,
        tooltip: l10n.tOr(
          'profileLockedSectionHidden',
          'Hidden while this profile is locked',
        ),
      );
    }

    return _MiniBadge(
      icon: user.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
      label: compact
          ? ''
          : (user.isPrivate ? l10n.t('private') : l10n.t('public')),
      foreground: user.isPrivate
          ? scheme.onTertiaryContainer
          : scheme.onPrimaryContainer,
      background:
          user.isPrivate ? scheme.tertiaryContainer : scheme.primaryContainer,
      tooltip: user.isPrivate ? l10n.t('private') : l10n.t('public'),
    );
  }
}

class MessagePermissionBadge extends StatelessWidget {
  const MessagePermissionBadge({
    super.key,
    required this.permission,
    this.compact = false,
  });

  final MessagePermission permission;
  final bool compact;

  IconData get _icon => switch (permission) {
        MessagePermission.everyone => Icons.public_rounded,
        MessagePermission.followers => Icons.people_alt_rounded,
        MessagePermission.friends => Icons.handshake_rounded,
        MessagePermission.nobody => Icons.block_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = l10n.tOr(permission.labelKey, permission.name);

    final (bg, fg) = switch (permission) {
      MessagePermission.everyone => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      MessagePermission.followers => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      MessagePermission.friends => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      MessagePermission.nobody => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
    };

    return _MiniBadge(
      icon: _icon,
      label: compact ? '' : label,
      foreground: fg,
      background: bg,
      tooltip: label,
    );
  }
}
