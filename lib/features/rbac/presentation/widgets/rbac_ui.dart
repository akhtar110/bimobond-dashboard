import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/rbac_state.dart';

class RbacPageFrame extends StatelessWidget {
  const RbacPageFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final titleStyle = isCompact
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.headlineSmall;

    // No Scaffold here — pages live inside the dashboard content area so the
    // side menu stays visible while navigating between RBAC screens.
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, isCompact ? 4 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isCompact) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      tooltip: context.l10n.tOr('back', 'Back'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: titleStyle),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ] else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width < 900 ? width * 0.45 : 620,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (onBack != null) ...[
                          IconButton(
                            onPressed: onBack,
                            tooltip: context.l10n.tOr('back', 'Back'),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: titleStyle),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
            SizedBox(height: isCompact ? 12 : 16),
            Expanded(child: child),
          ],
        ),
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
    ),
  );
}
