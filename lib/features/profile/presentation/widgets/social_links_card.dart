import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/profile_entity.dart';

class SocialLinksCard extends StatelessWidget {
  const SocialLinksCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasInsta = profile.instagramUrl != null &&
        profile.instagramUrl!.trim().isNotEmpty;
    final hasYt = profile.youtubeUrl != null &&
        profile.youtubeUrl!.trim().isNotEmpty;

    return SettingsSection(
      title: l10n.tOr('socialLinks', 'Social Links'),
      child: SettingsSurfaceCard(
        child: Column(
          children: [
            _LinkRow(
              icon: Icons.camera_alt_rounded,
              brandColor: const Color(0xFFE4405F),
              label: l10n.tOr('instagram', 'Instagram'),
              value: profile.instagramUrl,
            ),
            const SizedBox(height: 14),
            _LinkRow(
              icon: Icons.play_circle_fill_rounded,
              brandColor: const Color(0xFFFF0000),
              label: l10n.tOr('youtube', 'YouTube'),
              value: profile.youtubeUrl,
            ),
            if (!hasInsta && !hasYt)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tOr('noSocialLinks', 'No social links connected yet.'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.brandColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color brandColor;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasValue = value != null && value!.trim().isNotEmpty;
    final display = hasValue ? value!.trim() : '—';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: brandColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: brandColor),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: hasValue ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (hasValue)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: l10n.tOr('copy_link', 'Copy Link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value!));
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
    );
  }
}
