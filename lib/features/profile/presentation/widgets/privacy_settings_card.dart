import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/profile_entity.dart';

class PrivacySettingsCard extends StatelessWidget {
  const PrivacySettingsCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final permissionLabel = switch (profile.messagePermission.toUpperCase()) {
      'FOLLOWERS' => l10n.tOr('followers', 'Followers Only'),
      'FRIENDS' => l10n.tOr('friends', 'Friends Only'),
      'NOBODY' => l10n.tOr('nobody', 'Nobody (Disabled)'),
      _ => l10n.tOr('everyone', 'Everyone'),
    };

    return SettingsSection(
      title: l10n.tOr('privacy_and_permissions', 'Privacy & Direct Messaging'),
      child: SettingsSurfaceCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    profile.isPrivate
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tOr('private_account', 'Private Account'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        profile.isPrivate
                            ? l10n.tOr('private_account_desc',
                                'Only approved followers can view posts & profile')
                            : l10n.tOr('public_account_desc',
                                'Anyone can view posts & follow'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: profile.isPrivate
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.isPrivate
                        ? l10n.tOr('private', 'Private')
                        : l10n.tOr('public', 'Public'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: profile.isPrivate
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.mark_chat_read_rounded,
                    size: 18,
                    color: scheme.secondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tOr('message_permission', 'Direct Message Permission'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.tOr('message_permission_desc',
                            'Who can send direct messages'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    permissionLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.mode_comment_rounded,
                    size: 18,
                    color: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tOr('allowComments', 'Allow Post Comments'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.tOr('allow_comments_desc',
                            'Control if viewers can comment on posts'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: profile.allowComments
                        ? scheme.tertiaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.allowComments
                        ? l10n.tOr('enabled', 'Enabled')
                        : l10n.tOr('disabled', 'Disabled'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: profile.allowComments
                          ? scheme.onTertiaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
