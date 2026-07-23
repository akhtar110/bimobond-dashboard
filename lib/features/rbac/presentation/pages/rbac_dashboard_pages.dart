import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/role_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/permission_manager.dart';
import '../widgets/assign_user_roles_dialog.dart';
import '../widgets/role_users_dialog.dart';
import '../widgets/select_user_for_roles_dialog.dart';
import 'create_edit_role_page.dart';
import 'permission_catalog_page.dart';
import 'role_details_page.dart';
import 'roles_page.dart';

enum _RbacView { roles, createEdit, details, catalog }

/// Hosts the RBAC role screens inside the dashboard content area and keeps
/// the in-tab navigation state (list, form, details, catalog).
class RbacRolesDashboardPage extends StatefulWidget {
  const RbacRolesDashboardPage({super.key});

  @override
  State<RbacRolesDashboardPage> createState() => _RbacRolesDashboardPageState();
}

class _RbacRolesDashboardPageState extends State<RbacRolesDashboardPage> {
  _RbacView _view = _RbacView.roles;
  RoleEntity? _editingRole;
  String? _detailsRoleId;

  void _showRoles() {
    setState(() {
      _view = _RbacView.roles;
      _editingRole = null;
      _detailsRoleId = null;
    });
  }

  void _openCreate() {
    setState(() {
      _view = _RbacView.createEdit;
      _editingRole = null;
    });
  }

  void _openEdit(RoleEntity role) {
    setState(() {
      _view = _RbacView.createEdit;
      _editingRole = role;
    });
  }

  void _openDetails(RoleEntity role) {
    setState(() {
      _view = _RbacView.details;
      _detailsRoleId = role.id;
    });
  }

  Future<void> _openAssignment() async {
    final pick = await SelectUserForRolesDialog.show(context);
    if (pick == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final successText = context.l10n.tOr(
      'rbacUserRolesUpdated',
      'User roles updated successfully',
    );
    final result = await AssignUserRolesDialog.show(
      context,
      userId: pick.userId,
      userLabel: pick.label,
    );
    if (!mounted) return;
    if (result == true) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(successText),
        ),
      );
    }
  }

  void _openCatalog() {
    setState(() => _view = _RbacView.catalog);
  }

  Future<void> _openRoleUsers(RoleEntity role) {
    return showRoleUsersDialog(context, role: role);
  }

  Widget _currentPage() {
    return switch (_view) {
      _RbacView.roles => RolesPage(
        key: const ValueKey('rbac_roles'),
        onCreateRole: _openCreate,
        onViewRole: _openDetails,
        onEditRole: _openEdit,
        onAssignUsers: (_) => _openAssignment(),
        onAssignUserRoles: _openAssignment,
        onPermissionCatalog: _openCatalog,
        onViewRoleUsers: _openRoleUsers,
      ),
      _RbacView.createEdit => CreateEditRolePage(
        key: ValueKey('rbac_form_${_editingRole?.id ?? 'create'}'),
        role: _editingRole,
        onBack: _showRoles,
        onSaved: (_) => _showRoles(),
      ),
      _RbacView.details => RoleDetailsPage(
        key: ValueKey('rbac_details_$_detailsRoleId'),
        roleId: _detailsRoleId!,
        onBack: _showRoles,
        onEdit: _openEdit,
        onAssignUsers: (_) => _openAssignment(),
        onViewUsers: _openRoleUsers,
        onDeleted: _showRoles,
      ),
      _RbacView.catalog => PermissionCatalogPage(
        key: const ValueKey('rbac_catalog'),
        onBack: _showRoles,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width < 480
        ? 8.0
        : width < 900
        ? 12.0
        : 16.0;

    return _RbacAccessBoundary(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _currentPage(),
        ),
      ),
    );
  }
}

/// Blocks the RBAC section until the auth context is known, with distinct
/// loading, failure (retry), and no-access states. Legacy admins keep access
/// even when the fine-grained permission is missing.
class _RbacAccessBoundary extends StatefulWidget {
  const _RbacAccessBoundary({required this.child});

  final Widget child;

  @override
  State<_RbacAccessBoundary> createState() => _RbacAccessBoundaryState();
}

class _RbacAccessBoundaryState extends State<_RbacAccessBoundary> {
  @override
  void initState() {
    super.initState();
    context.read<RbacBloc>().add(const LoadCurrentPermissions());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (previous, current) =>
          previous.authContext != current.authContext ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.authContext == null) {
          if (state.status == RbacStatus.failure) {
            return _BoundaryMessage(
              icon: Icons.cloud_off_rounded,
              title: context.l10n.tOr(
                'rbacAccessCheckFailed',
                'Unable to verify your access',
              ),
              body: context.l10n.tOr(
                'rbacAccessCheckFailedBody',
                'Your permissions could not be loaded. Check your connection and try again.',
              ),
              action: FilledButton.icon(
                onPressed: () => context.read<RbacBloc>().add(
                  const LoadCurrentPermissions(force: true),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.tOr('retry', 'Retry')),
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
                    context.l10n.tOr(
                      'rbacCheckingAccess',
                      'Checking your access…',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final allowed = PermissionManager.canManageRoles(context);
        if (allowed) return widget.child;

        return _BoundaryMessage(
          icon: Icons.lock_outline_rounded,
          iconColor: Theme.of(context).colorScheme.error,
          title: context.l10n.tOr(
            'rbacInsufficientPermissions',
            'Insufficient permissions',
          ),
          body: context.l10n.tOr(
            'rbacInsufficientPermissionsBody',
            'You need the role management permission to open this section. Contact an administrator if you believe this is a mistake.',
          ),
          action: OutlinedButton.icon(
            onPressed: () => context.read<RbacBloc>().add(
              const LoadCurrentPermissions(force: true),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              context.l10n.tOr('rbacRecheckAccess', 'Re-check access'),
            ),
          ),
        );
      },
    );
  }
}

class _BoundaryMessage extends StatelessWidget {
  const _BoundaryMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: iconColor ?? scheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 24),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
