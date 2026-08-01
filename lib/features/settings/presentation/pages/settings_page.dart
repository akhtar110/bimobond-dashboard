import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import '../utils/settings_responsive.dart';
import '../widgets/logout_section.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_platform_tabs.dart';

/// Settings screen with admin module, profile, appearance, and logout.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _handleLogout() => _confirmLogout(context);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<AdminSettingsBloc>()..add(const LoadAdminSettingsEvent()),
      child: BlocListener<AdminSettingsBloc, AdminSettingsState>(
        listenWhen: (prev, next) =>
            next.message != null && next.message != prev.message,
        listener: (context, state) {
          if (state.message == null) return;
          final l10n = context.l10n;
          final scheme = Theme.of(context).colorScheme;
          final text = _resolveAdminMessage(l10n, state.message!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: state.messageIsError ? scheme.error : null,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AdminSettingsBloc>().add(
                const ClearAdminSettingsFeedbackEvent(),
              );
        },
        child: _SettingsBackground(
          child: _SettingsScrollBody(onLogout: _handleLogout),
        ),
      ),
    );
  }

  static String _resolveAdminMessage(AppLocalizations l10n, String message) {
    if (message.startsWith('settingsSeedSuccess:')) {
      final count = message.split(':').last;
      return l10n
          .tOr('settingsSeedSuccess', 'Seeded {count} settings')
          .replaceAll('{count}', count);
    }
    return switch (message) {
      'settingCreated' => l10n.tOr('settingCreated', 'Setting created'),
      'settingUpdated' => l10n.tOr('settingUpdated', 'Setting updated'),
      'settingDeleted' => l10n.tOr('settingDeleted', 'Setting deleted'),
      'brandingUpdated' => l10n.tOr('brandingUpdated', 'Branding updated'),
      'brandingLogoUploaded' =>
          l10n.tOr('brandingLogoUploaded', 'Logo uploaded'),
      'currencyCreated' => l10n.tOr('currencyCreated', 'Currency created'),
      'currencyUpdated' => l10n.tOr('currencyUpdated', 'Currency updated'),
      'currencyDeleted' => l10n.tOr('currencyDeleted', 'Currency deleted'),
      _ => message,
    };
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: scheme.scrim.withValues(alpha: 0.5),
      builder: (_) => _LogoutConfirmDialog(
        danger: scheme.error,
        title: l10n.t('logout'),
        message: l10n.t('logoutConfirmMessage'),
        cancelLabel: l10n.t('cancel'),
        confirmLabel: l10n.t('logout'),
        titleStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyStyle: theme.textTheme.bodyMedium,
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(AuthLogoutRequested());
    }
  }
}

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
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.logout_rounded, color: danger, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: titleStyle)),
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
            foregroundColor: scheme.onError,
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

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      // Fill the dashboard pane so alignment uses the real available size.
      child: SizedBox.expand(child: child),
    );
  }
}

class _SettingsScrollBody extends StatelessWidget {
  const _SettingsScrollBody({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final canReadAdmin = PermissionManager.canReadSettings(context);
    final canManage = PermissionManager.canWriteSettings(context);
    final canManageCurrencies = PermissionManager.canManageCurrencies(context);
    final showAdmin = canReadAdmin || canManageCurrencies;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the dashboard content width (not full window) so breakpoints
        // and centering stay stable when the sidebar is present.
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final contentWidth = availableWidth.clamp(
          0.0,
          SettingsLayoutMetrics.maxContentWidth,
        );
        final metrics =
            SettingsLayoutMetrics(getSettingsDeviceType(contentWidth));
        final sectionGap = metrics.sectionGap;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                metrics.pageHorizontalPadding,
                metrics.pageTopPadding + 8,
                metrics.pageHorizontalPadding,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(
                    child: SettingsHeader(compact: metrics.isCompact),
                  ),
                  if (showAdmin) ...[
                    SizedBox(height: sectionGap + 10),
                    RepaintBoundary(
                      child: SettingsPlatformTabs(
                        canManage: canManage,
                        canReadAdmin: canReadAdmin,
                        canManageCurrencies: canManageCurrencies,
                      ),
                    ),
                  ],
                  SizedBox(height: sectionGap + 10),
                  RepaintBoundary(child: LogoutSection(onLogout: onLogout)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
