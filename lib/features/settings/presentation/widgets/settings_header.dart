import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../rbac/domain/entities/role_user_entity.dart';
import '../../../rbac/domain/entities/user_auth_context_entity.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../bloc/admin_settings_bloc.dart';
import '../bloc/settings_cubit.dart';
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

/// Admin settings page header with role badge and quick actions.
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
        // Title/role on the start; theme/language + actions always top-end.
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final titleStyle = _titleStyleForWidth(theme, scheme, width);
            final badgeCompact = compact || width < 560;
            final useCompactActions = compact || width < 900;
            final gap = width < 480 ? 6.0 : 12.0;

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
                ? (useCompactActions
                    ? FilledButton.tonal(
                        onPressed: state.isSeeding
                            ? null
                            : () => confirmAndSeedAdminSettings(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: state.isSeeding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.grass_outlined, size: 18),
                        label: Text(l10n.tOr('seedSettings', 'Seed defaults')),
                      ))
                : null;

            final newBtn = canWrite
                ? (useCompactActions
                    ? FilledButton(
                        onPressed: state.isSaving
                            ? null
                            : () => showCreateSettingDialog(context),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(40, 40),
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

            final adminActions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (seedBtn != null) ...[
                  Tooltip(
                    message: l10n.tOr('seedSettings', 'Seed defaults'),
                    child: seedBtn,
                  ),
                  SizedBox(width: useCompactActions ? 6 : 8),
                ],
                if (newBtn != null) ...[
                  Tooltip(
                    message: l10n.tOr('newSetting', 'New setting'),
                    child: newBtn,
                  ),
                  SizedBox(width: useCompactActions ? 6 : 8),
                ],
                refreshBtn,
              ],
            );

            final titleAndRole = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.t('settings'),
                      maxLines: 1,
                      softWrap: false,
                      style: titleStyle,
                    ),
                  ),
                ),
                SizedBox(width: badgeCompact ? 8 : 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: _CurrentUserRoleBadge(compact: badgeCompact),
                  ),
                ),
              ],
            );

            final topEndActions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PreferenceIconToggles(),
                SizedBox(width: gap),
                adminActions,
              ],
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: titleAndRole,
                ),
                SizedBox(width: gap),
                Flexible(
                  flex: 3,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: topEndActions,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

TextStyle _titleStyleForWidth(
  ThemeData theme,
  ColorScheme scheme,
  double width,
) {
  final fontSize = width < 360
      ? 20.0
      : width < 480
          ? 22.0
          : width < 720
              ? 24.0
              : 26.0;

  return (theme.textTheme.headlineSmall ?? const TextStyle()).copyWith(
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: scheme.onSurface,
    height: 1.15,
    fontSize: fontSize,
  );
}

class _CurrentUserRoleBadge extends StatelessWidget {
  const _CurrentUserRoleBadge({this.compact = false});

  final bool compact;

  static bool _matchesAny(SystemRoleKind kind, Iterable<String> values) {
    for (final value in values) {
      if (kind.matchesSlug(value)) return true;
    }
    return false;
  }

  static Iterable<String> _rbacRoleTokens(UserAuthContextEntity? ctx) {
    if (ctx == null) return const [];
    return [
      ...ctx.roleSlugs,
      ...ctx.legacyRoles,
      for (final role in ctx.roles) ...[role.slug, role.name],
    ];
  }

  /// Prefer `/rbac/me` role slugs; fall back to legacy Auth roles.
  static String _labelFor(
    AppLocalizations l10n, {
    required UserAuthContextEntity? rbac,
    required List<UserRole> legacyRoles,
  }) {
    final tokens = _rbacRoleTokens(rbac);

    if (_matchesAny(SystemRoleKind.superAdmin, tokens) ||
        legacyRoles.contains(UserRole.superAdmin)) {
      return l10n.tOr('roleSuperAdmin', 'Super Admin');
    }
    if (_matchesAny(SystemRoleKind.admin, tokens) || legacyRoles.includesAdmin) {
      return l10n.tOr('roleAdmin', 'Administrator');
    }
    if (_matchesAny(SystemRoleKind.moderator, tokens) ||
        legacyRoles.includesModerator) {
      return l10n.tOr('roleModerator', 'Moderator');
    }
    return l10n.tOr('roleAdmin', 'Administrator');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.select<AuthBloc, AuthState>((bloc) => bloc.state);
    final legacyRoles =
        auth is Authenticated ? auth.user.roles : const <UserRole>[];

    UserAuthContextEntity? rbacContext;
    try {
      rbacContext = context.select<RbacBloc, UserAuthContextEntity?>(
        (bloc) => bloc.state.authContext,
      );
    } on ProviderNotFoundException {
      rbacContext = null;
    }

    final label = _labelFor(
      l10n,
      rbac: rbacContext,
      legacyRoles: legacyRoles,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 12 : 14,
            color: scheme.onPrimaryContainer,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: (compact
                    ? theme.textTheme.labelMedium
                    : theme.textTheme.labelLarge)
                ?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceIconToggles extends StatelessWidget {
  const _PreferenceIconToggles();

  static const _english = Locale('en');
  static const _arabic = Locale('ar');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = context.select<SettingsCubit, ThemeMode>(
      (cubit) => cubit.state.themeMode,
    );
    final languageCode = context.select<SettingsCubit, String>(
      (cubit) => cubit.state.locale.languageCode,
    );
    final cubit = context.read<SettingsCubit>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconToggleGroup(
          children: [
            _ToggleIconButton(
              icon: Icons.light_mode_rounded,
              tooltip: l10n.t('lightMode'),
              selected: themeMode == ThemeMode.light,
              onTap: () => cubit.switchTheme(false),
            ),
            _ToggleIconButton(
              icon: Icons.dark_mode_rounded,
              tooltip: l10n.t('darkMode'),
              selected: themeMode == ThemeMode.dark,
              onTap: () => cubit.switchTheme(true),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _IconToggleGroup(
          children: [
            _ToggleIconButton(
              label: 'EN',
              tooltip: l10n.t('english'),
              selected: languageCode == 'en',
              onTap: () => cubit.switchLanguage(_english),
            ),
            _ToggleIconButton(
              label: 'AR',
              tooltip: l10n.t('arabic'),
              selected: languageCode == 'ar',
              onTap: () => cubit.switchLanguage(_arabic),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconToggleGroup extends StatelessWidget {
  const _IconToggleGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ToggleIconButton extends StatelessWidget {
  const _ToggleIconButton({
    this.icon,
    this.label,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  }) : assert(icon != null || label != null);

  final IconData? icon;
  final String? label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            width: 36,
            height: 34,
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    )
                  : Text(
                      label!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: selected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
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
