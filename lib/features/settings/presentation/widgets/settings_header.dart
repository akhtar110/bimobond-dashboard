import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../bloc/admin_settings_bloc.dart';
import 'create_setting_dialog.dart';

/// Confirms and runs `POST /settings/admin/seed`.
Future<void> confirmAndSeedAdminSettings(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        l10n.tOr('seedSettingsTitle', 'Seed settings?'),
      ),
      content: Text(
        l10n.tOr(
          'seedSettingsMessage',
          'This upserts missing default settings (economy, notifications, uploads) without overwriting existing values. Continue?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.tOr('cancel', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.tOr('seedSettings', 'Seed defaults')),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<AdminSettingsBloc>().add(const SeedAdminSettingsEvent());
  }
}

/// Admin settings page header with refresh, seed, and create actions.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canWrite = PermissionManager.canWriteSettings(context);

    return BlocBuilder<AdminSettingsBloc, AdminSettingsState>(
      buildWhen: (prev, next) =>
          prev.isLoading != next.isLoading ||
          prev.isSeeding != next.isSeeding ||
          prev.isSaving != next.isSaving,
      builder: (context, state) {
        final refreshBtn = _HeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: l10n.tOr('refresh', 'Refresh'),
          isLoading: state.isLoading,
          onPressed: state.isLoading
              ? null
              : () => context
                  .read<AdminSettingsBloc>()
                  .add(const LoadAdminSettingsEvent(refresh: true)),
        );

        final seedBtn = canWrite
            ? (compact
                ? FilledButton.tonal(
                    onPressed: state.isSeeding
                        ? null
                        : () => confirmAndSeedAdminSettings(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 40),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state.isSeeding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.grass_outlined, size: 18),
                  )
                : FilledButton.tonalIcon(
                    onPressed: state.isSeeding
                        ? null
                        : () => confirmAndSeedAdminSettings(context),
                    icon: state.isSeeding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.grass_outlined, size: 18),
                    label: Text(l10n.tOr('seedSettings', 'Seed defaults')),
                  ))
            : null;

        final newBtn = canWrite
            ? (compact
                ? FilledButton(
                    onPressed: state.isSaving
                        ? null
                        : () => showCreateSettingDialog(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 40),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded, size: 18),
                  )
                : FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () => showCreateSettingDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.tOr('newSetting', 'New setting')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ))
            : null;

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seedBtn != null) ...[
              seedBtn,
              const SizedBox(width: 8),
            ],
            if (newBtn != null) ...[
              newBtn,
              const SizedBox(width: 8),
            ],
            refreshBtn,
          ],
        );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('settings'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: scheme.onSurface,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('settingsSubtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inline = constraints.maxWidth >= 720;
                if (inline) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: 16),
                      actions,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    if (canWrite) ...[
                      const SizedBox(height: 10),
                      actions,
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
