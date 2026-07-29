import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/rbac_state.dart';
import '../utils/rbac_responsive.dart';

/// Compact page chrome — title + actions, no subtitle or border card.
class RbacPageFrame extends StatelessWidget {
  const RbacPageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.onBack,
    this.metrics,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final RbacLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final m = metrics ??
              RbacLayoutMetrics(getRbacDeviceType(constraints.maxWidth));
          final compact = m.isCompact;
          final stackActions =
              actions.isNotEmpty && constraints.maxWidth < 720;

          final titleStyle =
              (compact
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                    color: scheme.onSurface,
                    height: 1.05,
                  );

          final titleRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBack != null) ...[
                IconButton(
                  onPressed: onBack,
                  tooltip: context.l10n.tOr('back', 'Back'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: Size(compact ? 36 : 40, compact ? 36 : 40),
                  ),
                ),
                SizedBox(width: m.controlGap),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ],
          );

          final header = stackActions
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleRow,
                    if (actions.isNotEmpty) ...[
                      SizedBox(height: m.headerGap),
                      Wrap(
                        spacing: m.controlGap,
                        runSpacing: m.controlGap,
                        alignment: WrapAlignment.end,
                        children: actions,
                      ),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: titleRow),
                    if (actions.isNotEmpty) ...[
                      SizedBox(width: m.controlGap),
                      Wrap(
                        spacing: m.controlGap,
                        runSpacing: m.controlGap,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: actions,
                      ),
                    ],
                  ],
                );

          return Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              0,
              m.pageTopPadding,
              0,
              m.pageBottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
                  child: header,
                ),
                SizedBox(height: m.headerGap),
                Expanded(child: child),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dense toolbar button used across RBAC headers.
class RbacHeaderAction extends StatelessWidget {
  const RbacHeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = true,
    this.compact = false,
    this.tonal = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool compact;
  final bool tonal;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: compact ? 20 : 18);

    if (compact) {
      if (outlined) {
        return IconButton.outlined(
          onPressed: onPressed,
          tooltip: label,
          icon: child,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
        );
      }
      if (tonal) {
        return IconButton.filledTonal(
          onPressed: onPressed,
          tooltip: label,
          icon: child,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
        );
      }
      return IconButton.filled(
        onPressed: onPressed,
        tooltip: label,
        icon: child,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
      );
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: child,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 40),
          visualDensity: VisualDensity.compact,
          shape: shape,
        ),
      );
    }
    if (tonal) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: child,
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 40),
          visualDensity: VisualDensity.compact,
          shape: shape,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: child,
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        visualDensity: VisualDensity.compact,
        shape: shape,
      ),
    );
  }
}

class RbacErrorView extends StatelessWidget {
  const RbacErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          color: scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: Text(context.l10n.tOr('retry', 'Retry')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RbacEmptyView extends StatelessWidget {
  const RbacEmptyView({
    super.key,
    required this.title,
    this.icon = Icons.shield_outlined,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center),
      ],
    ),
  );
}

/// Small tonal badge used for system/status indicators.
class RbacBadge extends StatelessWidget {
  const RbacBadge({super.key, required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = emphasized
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = emphasized
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String rbacFeedbackText(BuildContext context, RbacFeedback feedback) =>
    switch (feedback) {
      RbacFeedback.roleCreated => context.l10n.tOr(
        'rbacRoleCreated',
        'Role created successfully',
      ),
      RbacFeedback.roleUpdated => context.l10n.tOr(
        'rbacRoleUpdated',
        'Role updated successfully',
      ),
      RbacFeedback.roleDeleted => context.l10n.tOr(
        'rbacRoleDeleted',
        'Role deleted successfully',
      ),
      RbacFeedback.userRolesUpdated => context.l10n.tOr(
        'rbacUserRolesUpdated',
        'User roles updated successfully',
      ),
    };

String rbacGenericError(BuildContext context) =>
    context.l10n.tOr('rbacRequestFailed', 'The request could not be completed');

String rbacErrorText(BuildContext context, String message) {
  final normalized = message.trim().toLowerCase();
  if (normalized.contains('rbac management permission required')) {
    return context.l10n.tOr(
      'rbacManagementPermissionRequired',
      'RBAC management permission required.',
    );
  }
  if (normalized.contains('cannot remove the last super admin')) {
    return context.l10n.tOr(
      'rbacCannotRemoveLastSuperAdmin',
      'Cannot remove the last super admin from the platform.',
    );
  }
  if (normalized.contains('cannot remove your own super admin') ||
      normalized.contains('cannot remove own super admin')) {
    return context.l10n.tOr(
      'rbacCannotRemoveOwnSuperAdmin',
      'You cannot remove your own super admin role.',
    );
  }
  if (normalized.contains('roles are invalid or inactive')) {
    return context.l10n.tOr(
      'rbacInvalidOrInactiveRoles',
      'One or more roles are invalid or inactive.',
    );
  }
  if (normalized.contains('user not found')) {
    return context.l10n.tOr('rbacUserNotFound', 'User not found.');
  }
  if (normalized.contains('insufficient permissions') ||
      normalized.contains('do not have permission')) {
    return context.l10n.tOr(
      'rbacInsufficientPermissions',
      'Insufficient permissions',
    );
  }
  if (normalized.contains('session has expired') ||
      normalized.contains('unauthorized')) {
    return context.l10n.tOr(
      'rbacUnauthorized',
      'Your session has expired. Please sign in again.',
    );
  }
  if (normalized.contains('request is invalid') ||
      normalized.contains('validation')) {
    return context.l10n.tOr(
      'rbacInvalidRequest',
      'The request is invalid. Check the submitted values.',
    );
  }
  return message;
}

/// Formats contract dates; the epoch sentinel means "unknown".
String formatRbacDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return '—';
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

void showRbacFeedback(BuildContext context, String message, bool isError) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? scheme.error : scheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
