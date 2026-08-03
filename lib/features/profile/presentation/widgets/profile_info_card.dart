import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/profile_entity.dart';

class AccountSecurityCard extends StatelessWidget {
  const AccountSecurityCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final createdAtStr = profile.createdAt != null
        ? DateFormat.yMMMd().add_jm().format(profile.createdAt!.toLocal())
        : '—';
    final updatedAtStr = profile.updatedAt != null
        ? DateFormat.yMMMd().add_jm().format(profile.updatedAt!.toLocal())
        : '—';

    return SettingsSection(
      title: l10n.tOr('account_and_security', 'Account & Security'),
      child: SettingsSurfaceCard(
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.fingerprint_rounded,
              label: l10n.tOr('user_id', 'User ID'),
              valueWidget: Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.id,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: l10n.tOr('copy_id', 'Copy ID'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: profile.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.tOr('copied_to_clipboard', 'Copied to clipboard'),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            _InfoRow(
              icon: Icons.shield_rounded,
              label: l10n.tOr('roles', 'Assigned Roles'),
              valueWidget: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: profile.roles.map((role) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            _InfoRow(
              icon: Icons.gavel_rounded,
              label: l10n.tOr('account_status', 'Account Status'),
              valueWidget: profile.isBanned
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tOr('banned', 'Banned'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (profile.banReason != null &&
                            profile.banReason!.isNotEmpty)
                          Text(
                            'Reason: ${profile.banReason}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.error,
                            ),
                          ),
                      ],
                    )
                  : Text(
                      l10n.tOr('active', 'Active (Normal)'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: l10n.tOr('created_at', 'Account Created'),
              value: createdAtStr,
            ),
            _InfoRow(
              icon: Icons.update_rounded,
              label: l10n.tOr('updated_at', 'Last Updated'),
              value: updatedAtStr,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class EngagementMetricsCard extends StatelessWidget {
  const EngagementMetricsCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsSection(
      title: l10n.tOr('activity_and_engagement', 'Activity & Engagement'),
      child: SettingsSurfaceCard(
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.card_giftcard_rounded,
              label: l10n.tOr('sent_gifts', 'Gifts Sent'),
              value: '${profile.sentGiftsCount}',
            ),
            _InfoRow(
              icon: Icons.redeem_rounded,
              label: l10n.tOr('received_gifts', 'Gifts Received'),
              value: '${profile.receivedGiftsCount}',
            ),
            _InfoRow(
              icon: Icons.gavel_rounded,
              label: l10n.tOr('won_auctions', 'Auctions Won'),
              value: '${profile.wonAuctionsCount}',
            ),
            _InfoRow(
              icon: Icons.flag_rounded,
              label: l10n.tOr('reports_received', 'Reports Received'),
              value: '${profile.reportsRecvCount}',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dob = profile.dateOfBirth != null
        ? DateFormat.yMMMd().format(profile.dateOfBirth!)
        : '—';

    return SettingsSection(
      title: l10n.tOr('personalInformation', 'Personal Information'),
      child: SettingsSurfaceCard(
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.badge_rounded,
              label: l10n.tOr('full_name', 'Full name'),
              value: profile.fullName?.trim().isNotEmpty == true
                  ? profile.fullName!
                  : '—',
            ),
            _InfoRow(
              icon: Icons.alternate_email_rounded,
              label: l10n.tOr('username', 'Username'),
              value: '@${profile.username}',
            ),
            _InfoRow(
              icon: Icons.notes_rounded,
              label: l10n.tOr('bio', 'Bio'),
              value: profile.bio?.trim().isNotEmpty == true
                  ? profile.bio!
                  : '—',
            ),
            _InfoRow(
              icon: Icons.cake_rounded,
              label: l10n.tOr('date_of_birth', 'Date of birth'),
              value: dob,
            ),
            _InfoRow(
              icon: Icons.wc_rounded,
              label: l10n.tOr('gender', 'Gender'),
              value: profile.gender?.trim().isNotEmpty == true
                  ? profile.gender!
                  : '—',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class ContactLocationCard extends StatelessWidget {
  const ContactLocationCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsSection(
      title: l10n.tOr('contactAndLocation', 'Contact & Location'),
      child: SettingsSurfaceCard(
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.email_rounded,
              label: l10n.tOr('email', 'Email Address'),
              value: profile.email?.trim().isNotEmpty == true
                  ? profile.email!
                  : '—',
            ),
            _InfoRow(
              icon: Icons.phone_rounded,
              label: l10n.tOr('phone_number', 'Phone number'),
              value: profile.phoneNumber?.trim().isNotEmpty == true
                  ? profile.phoneNumber!
                  : '—',
            ),
            _InfoRow(
              icon: Icons.public_rounded,
              label: l10n.tOr('country', 'Country'),
              value: profile.country?.trim().isNotEmpty == true
                  ? profile.country!
                  : '—',
            ),
            _InfoRow(
              icon: Icons.map_rounded,
              label: l10n.tOr('region', 'Region'),
              value: profile.region?.trim().isNotEmpty == true
                  ? profile.region!
                  : '—',
            ),
            _InfoRow(
              icon: Icons.location_city_rounded,
              label: l10n.tOr('city', 'City'),
              value: profile.city?.trim().isNotEmpty == true
                  ? profile.city!
                  : '—',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.icon,
    this.isLast = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final IconData? icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: scheme.primary.withValues(alpha: 0.8)),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
