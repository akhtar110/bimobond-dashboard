import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/language_selector_card.dart';
import '../widgets/logout_section.dart';
import '../widgets/profile_card.dart';
import '../widgets/settings_platform_tabs.dart';
import '../widgets/theme_selector_card.dart';

/// Settings screen with narrow rebuild scopes for theme and locale changes.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Stable callback reference — avoids rebuilding [LogoutSection] on unrelated frames.
  void _handleLogout() => _confirmLogout(context);

  @override
  Widget build(BuildContext context) {
    // Intentionally no Theme.of / l10n here so this node is not marked dirty
    // when only theme or locale changes.
    return _SettingsBackground(
      child: _SettingsScrollBody(onLogout: _handleLogout),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final danger =
        isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);

    // Resolve strings and styles once before opening the dialog route.
    final dialogContent = (
      title: l10n.t('logout'),
      message: l10n.t('logoutConfirmMessage'),
      cancelLabel: l10n.t('cancel'),
      confirmLabel: l10n.t('logout'),
      titleStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyStyle: theme.textTheme.bodyMedium,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => _LogoutConfirmDialog(
        danger: danger,
        title: dialogContent.title,
        message: dialogContent.message,
        cancelLabel: dialogContent.cancelLabel,
        confirmLabel: dialogContent.confirmLabel,
        titleStyle: dialogContent.titleStyle,
        bodyStyle: dialogContent.bodyStyle,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
  }
}

/// Self-contained dialog — no inherited lookups inside [build].
class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog({
    required this.danger,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.titleStyle,
    required this.bodyStyle,
  });

  final Color danger;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.logout_rounded, color: danger, size: 22),
          const SizedBox(width: 10),
          Text(title, style: titleStyle),
        ],
      ),
      content: Text(message, style: bodyStyle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Only rebuilds when theme/brightness changes (page background).
class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF7F9FC),
      child: child,
    );
  }
}

/// Scroll shell — uses [MediaQuery] for padding (not [LayoutBuilder]).
/// Does not depend on theme or locale, so it skips those rebuilds.
class _SettingsScrollBody extends StatelessWidget {
  const _SettingsScrollBody({required this.onLogout});

  final VoidCallback onLogout;

  static double _horizontalPaddingFor(double width) {
    if (width >= 1200) return 32;
    if (width >= 768) return 24;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding =
        _horizontalPaddingFor(MediaQuery.sizeOf(context).width);

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
              const RepaintBoundary(child: _SettingsHeader()),
              const SizedBox(height: 28),
              const RepaintBoundary(child: ProfileCard()),
              const SizedBox(height: 28),
              const RepaintBoundary(child: _AppearanceSection()),
              const SizedBox(height: 28),
              RepaintBoundary(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final canManage = authState is Authenticated &&
                        canManageSettings(authState.user.roles);
                    return SettingsPlatformTabs(canManage: canManage);
                  },
                ),
              ),
              const SizedBox(height: 28),
              RepaintBoundary(
                child: LogoutSection(onLogout: onLogout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title block — rebuilds on locale and theme only.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF6B7280);

    return Column(
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
      ],
    );
  }
}

/// Groups appearance controls without subscribing to theme/locale itself.
/// Each card manages its own [BlocSelector] / optimistic state internally.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThemeSelectorCard(),
        SizedBox(height: 28),
        LanguageSelectorCard(),
      ],
    );
  }
}
