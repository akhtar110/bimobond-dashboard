import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/permission_manager.dart';

/// Full-section "Access Denied" card used across the dashboard.
class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({
    super.key,
    this.title,
    this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final pad = width < 480 ? 16.0 : 28.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width < 480 ? width - 24 : 480,
        ),
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(16),
          color: scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(pad, pad + 4, pad, pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 36,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title ??
                      l10n.tOr('accessDeniedTitle', 'Access Denied'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  message ??
                      l10n.tOr(
                        'accessDeniedFeatureMessage',
                        'You do not have permission to access this feature. Contact an administrator if you believe this is a mistake.',
                      ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      retryLabel ??
                          l10n.tOr('rbacRecheckAccess', 'Re-check access'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ensures [RbacBloc] is available, waits for `/rbac/me`, then shows
/// [AccessDeniedView] when [canAccess] is false.
class FeatureAccessBoundary extends StatelessWidget {
  const FeatureAccessBoundary({
    super.key,
    required this.child,
    required this.canAccess,
    this.deniedMessage,
    this.loadPermissions = true,
    this.requireAuthContext = true,
  });

  final Widget child;

  /// Called after auth context is available when [requireAuthContext] is true;
  /// otherwise evaluated immediately (role-based fallbacks may apply).
  final bool Function(BuildContext context) canAccess;

  /// Optional body copy under the Access Denied title.
  final String? deniedMessage;

  /// When true, triggers [LoadCurrentPermissions] if context is missing.
  final bool loadPermissions;

  /// When false, [canAccess] may grant access before `/rbac/me` finishes
  /// (e.g. legacy admin/moderator role checks).
  final bool requireAuthContext;

  @override
  Widget build(BuildContext context) {
    RbacBloc? existing;
    try {
      existing = context.read<RbacBloc>();
    } on ProviderNotFoundException {
      existing = null;
    }

    final bloc = existing ?? di.sl<RbacBloc>();
    final needsProvider = existing == null;

    final content = _FeatureAccessBoundaryBody(
      canAccess: canAccess,
      deniedMessage: deniedMessage,
      loadPermissions: loadPermissions,
      requireAuthContext: requireAuthContext,
      child: child,
    );

    if (!needsProvider) return content;
    return BlocProvider<RbacBloc>.value(value: bloc, child: content);
  }
}

class _FeatureAccessBoundaryBody extends StatefulWidget {
  const _FeatureAccessBoundaryBody({
    required this.child,
    required this.canAccess,
    required this.loadPermissions,
    required this.requireAuthContext,
    this.deniedMessage,
  });

  final Widget child;
  final bool Function(BuildContext context) canAccess;
  final String? deniedMessage;
  final bool loadPermissions;
  final bool requireAuthContext;

  @override
  State<_FeatureAccessBoundaryBody> createState() =>
      _FeatureAccessBoundaryBodyState();
}

class _FeatureAccessBoundaryBodyState
    extends State<_FeatureAccessBoundaryBody> {
  @override
  void initState() {
    super.initState();
    if (!widget.loadPermissions) return;
    final bloc = context.read<RbacBloc>();
    if (bloc.state.authContext == null) {
      bloc.add(const LoadCurrentPermissions());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (previous, current) =>
          previous.authContext != current.authContext ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.authContext == null) {
          if (!widget.requireAuthContext && widget.canAccess(context)) {
            return widget.child;
          }
          if (state.status == RbacStatus.failure) {
            return AccessDeniedView(
              title: l10n.tOr(
                'rbacAccessCheckFailed',
                'Unable to verify your access',
              ),
              message: l10n.tOr(
                'rbacAccessCheckFailedBody',
                'Your permissions could not be loaded. Check your connection and try again.',
              ),
              onRetry: () => context.read<RbacBloc>().add(
                    const LoadCurrentPermissions(force: true),
                  ),
              retryLabel: l10n.tOr('retry', 'Retry'),
            );
          }
          // Role-only denial is definitive; fine-grained tabs keep loading.
          if (!widget.requireAuthContext && !widget.canAccess(context)) {
            return AccessDeniedView(
              message: widget.deniedMessage,
              onRetry: () => context.read<RbacBloc>().add(
                    const LoadCurrentPermissions(force: true),
                  ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.tOr('rbacCheckingAccess', 'Checking your access…'),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (widget.canAccess(context)) return widget.child;

        return AccessDeniedView(
          message: widget.deniedMessage,
          onRetry: () => context.read<RbacBloc>().add(
                const LoadCurrentPermissions(force: true),
              ),
        );
      },
    );
  }
}

/// Gates a dashboard tab: shows [AccessDeniedView] when the signed-in user
/// cannot open [tabIndex] (same rules as the sidebar).
class DashboardTabAccessBoundary extends StatelessWidget {
  const DashboardTabAccessBoundary({
    super.key,
    required this.tabIndex,
    required this.child,
  });

  final int tabIndex;
  final Widget child;

  static bool _tabUsesFineGrainedRbac(int tabIndex) =>
      tabIndex == 6 || // stories
      tabIndex == 13 || // sounds
      tabIndex == 16 || // camera studio
      tabIndex == 18; // roles

  @override
  Widget build(BuildContext context) {
    final needsRbac = _tabUsesFineGrainedRbac(tabIndex);
    return FeatureAccessBoundary(
      requireAuthContext: needsRbac && !PermissionManager.isLegacyAdmin(context),
      canAccess: (ctx) => PermissionManager.canAccessDashboardTab(ctx, tabIndex),
      child: child,
    );
  }
}

/// Convenience gate that shows [AccessDeniedView] instead of hiding UI.
class AccessDeniedPermissionGate extends StatelessWidget {
  const AccessDeniedPermissionGate({
    super.key,
    required this.child,
    this.permission,
    this.anyOf = const [],
    this.allOf = const [],
    this.allowLegacyAdmin = true,
    this.deniedMessage,
  }) : assert(
          permission != null || anyOf.length > 0 || allOf.length > 0,
          'Specify a permission, anyOf, or allOf.',
        );

  final Widget child;
  final String? permission;
  final List<String> anyOf;
  final List<String> allOf;
  final bool allowLegacyAdmin;
  final String? deniedMessage;

  @override
  Widget build(BuildContext context) {
    return FeatureAccessBoundary(
      deniedMessage: deniedMessage,
      canAccess: (ctx) {
        if (allowLegacyAdmin && PermissionManager.isLegacyAdmin(ctx)) {
          return true;
        }
        if (permission != null &&
            !PermissionManager.hasPermission(ctx, permission!)) {
          return false;
        }
        if (anyOf.isNotEmpty && !PermissionManager.hasAny(ctx, anyOf)) {
          return false;
        }
        if (allOf.isNotEmpty && !PermissionManager.hasAll(ctx, allOf)) {
          return false;
        }
        return true;
      },
      child: child,
    );
  }
}
