import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/profile_entity.dart';

class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final languageLabel = switch (profile.language.toLowerCase()) {
      'ar' => l10n.tOr('arabic', 'Arabic (العربية)'),
      'en' => l10n.tOr('english', 'English'),
      _ => profile.language.toUpperCase(),
    };

    final themeLabel = switch (profile.theme.toLowerCase()) {
      'dark' => l10n.tOr('dark', 'Dark Theme'),
      'light' => l10n.tOr('light', 'Light Theme'),
      _ => l10n.tOr('system', 'System Default'),
    };

    return SettingsSection(
      title: l10n.tOr('appearance_and_preferences', 'Stored Profile Preferences'),
      description: l10n.tOr(
        'profileAppearanceHint',
        'Profile preferences sync across devices. Dashboard interface theme can also be adjusted in Settings.',
      ),
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
                  child: Icon(Icons.language_rounded, size: 18, color: scheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.tOr('language', 'Preferred Language'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    languageLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
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
                  child: Icon(Icons.palette_rounded, size: 18, color: scheme.tertiary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.tOr('theme', 'Preferred Theme'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    themeLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
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
