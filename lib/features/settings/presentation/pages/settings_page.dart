import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../widgets/language_selector_card.dart';
import '../widgets/logout_section.dart';
import '../widgets/profile_card.dart';
import '../widgets/theme_selector_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);

    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FC),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width >= 1200
              ? 32.0
              : width >= 768
                  ? 24.0
                  : 16.0;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  horizontalPadding,
                  28,
                  horizontalPadding,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.t('settings'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('settingsSubtitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const ProfileCard(),
                    const SizedBox(height: 28),
                    const ThemeSelectorCard(),
                    const SizedBox(height: 28),
                    const LanguageSelectorCard(),
                    const SizedBox(height: 28),
                    LogoutSection(onLogout: () {}),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
