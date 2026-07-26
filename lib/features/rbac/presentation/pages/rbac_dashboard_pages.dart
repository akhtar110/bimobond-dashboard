import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/role_entity.dart';
import '../utils/permission_manager.dart';
import '../widgets/access_denied_view.dart';
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

    return FeatureAccessBoundary(
      canAccess: PermissionManager.canManageRoles,
      deniedMessage: context.l10n.tOr(
        'rbacInsufficientPermissionsBody',
        'You need the role management permission to open this section. Contact an administrator if you believe this is a mistake.',
      ),
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
