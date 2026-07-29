import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_entity.dart';
import '../utils/user_location_list_utils.dart';

class UserDetailSectionTitle extends StatelessWidget {
  const UserDetailSectionTitle(this.title, {super.key, this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: color ?? scheme.onSurface,
      ),
    );
  }
}

class UserDetailInfoItem extends StatelessWidget {
  const UserDetailInfoItem(
    this.label,
    this.value,
    this.icon, {
    super.key,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserDetailPersonalInfo extends StatelessWidget {
  const UserDetailPersonalInfo({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('accountInformation'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          UserDetailInfoItem(
            l10n.t('emailAddress'),
            user.email ?? l10n.t('notProvided'),
            Icons.email_outlined,
          ),
          UserDetailInfoItem(
            l10n.t('phoneNumber'),
            user.phoneNumber ?? l10n.t('notProvided'),
            Icons.phone_outlined,
          ),
          UserDetailInfoItem(
            l10n.t('joinedOn'),
            user.createdAt != null
                ? dateFormat.format(user.createdAt!)
                : l10n.t('notAvailable'),
            Icons.calendar_today_outlined,
          ),

          Divider(height: 20, color: scheme.outlineVariant),
          UserDetailSectionTitle(l10n.t('personalDetails')),
          const SizedBox(height: 10),
          UserDetailInfoItem(
            l10n.t('gender'),
            user.gender ?? l10n.t('notSpecified'),
            Icons.person_outline,
          ),
          UserDetailInfoItem(
            l10n.t('birthday'),
            user.dateOfBirth != null
                ? dateFormat.format(user.dateOfBirth!)
                : l10n.t('notSpecified'),
            Icons.cake_outlined,
          ),
          UserDetailInfoItem(
            l10n.t('location'),
            formatUserLocation(context, user),
            Icons.location_on_outlined,
          ),

          Divider(height: 20, color: scheme.outlineVariant),
          UserDetailSectionTitle(l10n.t('socialProfiles')),
          const SizedBox(height: 10),
          UserDetailInfoItem(
            l10n.t('instagram'),
            user.instagramUrl ?? l10n.t('notLinked'),
            Icons.camera_alt_outlined,
          ),
          UserDetailInfoItem(
            l10n.t('youtube'),
            user.youtubeUrl ?? l10n.t('notLinked'),
            Icons.play_circle_outline,
          ),

          Divider(height: 20, color: scheme.outlineVariant),
          UserDetailSectionTitle(l10n.t('privacyAndSettings')),
          const SizedBox(height: 10),
          UserDetailInfoItem(
            l10n.t('accountPrivacy'),
            user.isPrivate ? l10n.t('private') : l10n.t('public'),
            Icons.lock_outline,
          ),
          UserDetailInfoItem(
            l10n.t('allowCommentsLabel'),
            user.allowComments ? l10n.t('yes') : l10n.t('no'),
            Icons.comment_outlined,
          ),
          UserDetailInfoItem(
            l10n.t('directMessages'),
            l10n.tOr(
              user.messagePermission.labelKey,
              user.messagePermission.name,
            ),
            Icons.message_outlined,
          ),
          UserDetailInfoItem(
            l10n.t('language'),
            user.language.toUpperCase(),
            Icons.language_outlined,
          ),
          if (user.isProfileLocked)
            UserDetailInfoItem(
              l10n.tOr('lockedProfileIndicator', 'Locked'),
              l10n.tOr(
                'profileLockedSectionHidden',
                'Hidden while this profile is locked',
              ),
              Icons.lock_person_outlined,
              valueColor: scheme.error,
            ),

          if (user.isBanned) ...[
            Divider(height: 20, color: scheme.outlineVariant),
            UserDetailSectionTitle(
              l10n.t('moderationStatus'),
              color: scheme.error,
            ),
            const SizedBox(height: 10),
            UserDetailInfoItem(
              l10n.t('banStatus'),
              l10n.t('banned'),
              Icons.gavel_rounded,
              valueColor: scheme.error,
            ),
            UserDetailInfoItem(
              l10n.t('banReason'),
              user.banReason ?? l10n.t('noReasonProvided'),
              Icons.info_outline,
            ),
            UserDetailInfoItem(
              l10n.t('bannedUntil'),
              user.bannedUntil != null
                  ? dateFormat.format(user.bannedUntil!)
                  : l10n.t('permanent'),
              Icons.timer_off_outlined,
            ),
          ],
        ],
      ),
    );
  }
}
