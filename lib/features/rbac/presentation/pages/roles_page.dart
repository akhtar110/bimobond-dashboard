import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../domain/entities/role_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/permission_manager.dart';
import '../widgets/rbac_ui.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({
    super.key,
    this.onCreateRole,
    this.onViewRole,
    this.onEditRole,
    this.onAssignUsers,
    this.onAssignUserRoles,
    this.onPermissionCatalog,
    this.onViewRoleUsers,
  });

  final VoidCallback? onCreateRole;
  final ValueChanged<RoleEntity>? onViewRole;
  final ValueChanged<RoleEntity>? onEditRole;
  final ValueChanged<RoleEntity>? onAssignUsers;

  /// Opens the assign-roles flow for an arbitrary user (toolbar entry).
  final VoidCallback? onAssignUserRoles;
  final VoidCallback? onPermissionCatalog;
  final ValueChanged<RoleEntity>? onViewRoleUsers;

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  @override
  void initState() {
    super.initState();
    context.read<RbacBloc>()
      ..add(const LoadCurrentPermissions())
      ..add(const LoadRoles());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RbacBloc, RbacState>(
      listenWhen: (previous, current) =>
          (current.feedback != null && previous.feedback != current.feedback) ||
          (current.errorMessage != null &&
              previous.errorMessage != current.errorMessage),
      listener: (context, state) {
        if (state.feedback != null) {
          showRbacFeedback(
            context,
            rbacFeedbackText(context, state.feedback!),
            false,
          );
        } else if (state.errorMessage != null) {
          showRbacFeedback(
            context,
            rbacErrorText(context, state.errorMessage!),
            true,
          );
        }
        context.read<RbacBloc>().add(const ClearRbacFeedback());
      },
      builder: (context, state) {
        final isCompact = MediaQuery.sizeOf(context).width < 600;
        return RbacPageFrame(
          title: context.l10n.tOr('roles', 'Roles'),
          subtitle: isCompact
              ? null
              : context.l10n.tOr(
                  'rolesSubtitle',
                  'Manage access roles and their permissions.',
                ),
          actions: [
            _ToolbarAction(
              compact: isCompact,
              icon: Icons.policy_outlined,
              label: context.l10n.tOr(
                'permissionCatalog',
                'Permission catalog',
              ),
              outlined: true,
              onPressed: widget.onPermissionCatalog,
            ),
            PermissionGate(
              allOf: RbacPermissionKeys.assignmentKeys,
              allowLegacyAdmin: true,
              child: _ToolbarAction(
                compact: isCompact,
                icon: Icons.person_add_alt_1_outlined,
                label: context.l10n.tOr('assignUserRoles', 'Assign user roles'),
                outlined: true,
                onPressed: widget.onAssignUserRoles,
              ),
            ),
            PermissionGate(
              permission: RbacPermissionKeys.manageRoles,
              allowLegacyAdmin: true,
              child: _ToolbarAction(
                compact: isCompact,
                icon: Icons.add_rounded,
                label: context.l10n.tOr('createRole', 'Create role'),
                outlined: false,
                onPressed: widget.onCreateRole,
              ),
            ),
          ],
          child: _RolesBody(
            state: state,
            onViewRole: widget.onViewRole,
            onEditRole: widget.onEditRole,
            onAssignUsers: widget.onAssignUsers,
            onViewRoleUsers: widget.onViewRoleUsers,
          ),
        );
      },
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.compact,
    required this.icon,
    required this.label,
    required this.outlined,
    required this.onPressed,
  });

  final bool compact;
  final IconData icon;
  final String label;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final button = outlined
          ? IconButton.outlined(
              onPressed: onPressed,
              tooltip: label,
              icon: Icon(icon, size: 20),
            )
          : IconButton.filled(
              onPressed: onPressed,
              tooltip: label,
              icon: Icon(icon, size: 20),
            );
      return button;
    }
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _RolesBody extends StatelessWidget {
  const _RolesBody({
    required this.state,
    this.onViewRole,
    this.onEditRole,
    this.onAssignUsers,
    this.onViewRoleUsers,
  });

  final RbacState state;
  final ValueChanged<RoleEntity>? onViewRole;
  final ValueChanged<RoleEntity>? onEditRole;
  final ValueChanged<RoleEntity>? onAssignUsers;
  final ValueChanged<RoleEntity>? onViewRoleUsers;

  Future<void> _confirmDelete(BuildContext context, RoleEntity role) async {
    final bloc = context.read<RbacBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(dialogContext.l10n.tOr('deleteRole', 'Delete role')),
        content: Text(
          dialogContext.l10n
              .tOr(
                'deleteRoleConfirmationNamed',
                'You are about to delete "{name}". This action cannot be undone.',
              )
              .replaceAll('{name}', role.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.tOr('cancel', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.tOr('delete', 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(DeleteRole(role.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RbacBloc>();
    if (state.status == RbacStatus.loading && state.roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == RbacStatus.failure && state.roles.isEmpty) {
      return RbacErrorView(
        message: state.errorMessage == null
            ? context.l10n.tOr('rbacRolesLoadFailed', 'Unable to load roles')
            : rbacErrorText(context, state.errorMessage!),
        onRetry: () => bloc.add(const LoadRoles()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RolesToolbar(state: state),
        const SizedBox(height: 16),
        Expanded(
          child: state.pagedRoles.isEmpty
              ? RbacEmptyView(
                  title: context.l10n.tOr('noRolesFound', 'No roles found'),
                )
              : LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth < 760
                      ? RefreshIndicator(
                          onRefresh: () async =>
                              bloc.add(const LoadRoles(refresh: true)),
                          child: ListView.separated(
                            itemCount: state.pagedRoles.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _RoleCard(
                              role: state.pagedRoles[index],
                              onView: onViewRole,
                              onEdit: onEditRole,
                              onAssignUsers: onAssignUsers,
                              onViewRoleUsers: onViewRoleUsers,
                              onDelete: (role) => _confirmDelete(context, role),
                            ),
                          ),
                        )
                      : _RolesTable(
                          roles: state.pagedRoles,
                          maxWidth: constraints.maxWidth,
                          onView: onViewRole,
                          onEdit: onEditRole,
                          onAssignUsers: onAssignUsers,
                          onViewRoleUsers: onViewRoleUsers,
                          onDelete: (role) => _confirmDelete(context, role),
                        ),
                ),
        ),
        const SizedBox(height: 12),
        AppPaginationBar(
          currentPage: state.currentPage,
          lastPage: state.lastPage,
          total: state.total,
          pageSize: RbacState.pageSize,
          itemCount: state.pagedRoles.length,
          onPageChanged: (page) => bloc.add(ChangeRolesPage(page)),
        ),
      ],
    );
  }
}

class _RolesToolbar extends StatelessWidget {
  const _RolesToolbar({required this.state});

  final RbacState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RbacBloc>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = TextField(
          decoration: InputDecoration(
            labelText: context.l10n.tOr('searchRoles', 'Search roles'),
            prefixIcon: const Icon(Icons.search_rounded),
            border: const OutlineInputBorder(),
          ),
          onChanged: (query) => bloc.add(SearchRoles(query)),
        );
        final typeFilter = DropdownButtonFormField<RoleTypeFilter>(
          initialValue: state.typeFilter,
          decoration: InputDecoration(
            labelText: context.l10n.tOr('roleType', 'Type'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: RoleTypeFilter.all,
              child: Text(context.l10n.tOr('allRoles', 'All roles')),
            ),
            DropdownMenuItem(
              value: RoleTypeFilter.system,
              child: Text(context.l10n.tOr('systemRoles', 'System roles')),
            ),
            DropdownMenuItem(
              value: RoleTypeFilter.custom,
              child: Text(context.l10n.tOr('customRoles', 'Custom roles')),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              bloc.add(FilterRoles(typeFilter: value));
            }
          },
        );
        final statusFilter = DropdownButtonFormField<RoleStatusFilter>(
          initialValue: state.statusFilter,
          decoration: InputDecoration(
            labelText: context.l10n.tOr('status', 'Status'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: RoleStatusFilter.all,
              child: Text(context.l10n.tOr('allStatuses', 'All statuses')),
            ),
            DropdownMenuItem(
              value: RoleStatusFilter.active,
              child: Text(context.l10n.tOr('active', 'Active')),
            ),
            DropdownMenuItem(
              value: RoleStatusFilter.inactive,
              child: Text(context.l10n.tOr('inactive', 'Inactive')),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              bloc.add(FilterRoles(statusFilter: value));
            }
          },
        );
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: typeFilter),
                  const SizedBox(width: 10),
                  Expanded(child: statusFilter),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 190, child: typeFilter),
            const SizedBox(width: 12),
            SizedBox(width: 190, child: statusFilter),
          ],
        );
      },
    );
  }
}

class _RoleActions extends StatelessWidget {
  const _RoleActions({
    required this.role,
    this.onView,
    this.onEdit,
    this.onAssignUsers,
    this.onViewRoleUsers,
    this.onDelete,
  });

  final RoleEntity role;
  final ValueChanged<RoleEntity>? onView;
  final ValueChanged<RoleEntity>? onEdit;
  final ValueChanged<RoleEntity>? onAssignUsers;
  final ValueChanged<RoleEntity>? onViewRoleUsers;
  final ValueChanged<RoleEntity>? onDelete;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (previous, current) =>
          previous.authContext != current.authContext,
      builder: (context, _) {
        final l10n = context.l10n;
        final canManage = PermissionManager.canManageRoles(context);
        final canAssign = PermissionManager.canAssignRoles(context);

        return MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              tooltip: l10n.tOr('actions', 'Actions'),
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_vert_rounded),
            );
          },
          menuChildren: [
            MenuItemButton(
              onPressed: onView == null ? null : () => onView!(role),
              leadingIcon: const Icon(Icons.visibility_outlined, size: 18),
              child: Text(l10n.tOr('viewDetails', 'View details')),
            ),
            MenuItemButton(
              onPressed: onViewRoleUsers == null
                  ? null
                  : () => onViewRoleUsers!(role),
              leadingIcon: const Icon(Icons.people_outline_rounded, size: 18),
              child: Text(l10n.tOr('viewRoleUsers', 'View users')),
            ),
            if (canManage)
              MenuItemButton(
                onPressed: onEdit == null ? null : () => onEdit!(role),
                leadingIcon: const Icon(Icons.edit_outlined, size: 18),
                child: Text(l10n.tOr('editRole', 'Edit role')),
              ),
            if (canAssign)
              MenuItemButton(
                onPressed: onAssignUsers == null
                    ? null
                    : () => onAssignUsers!(role),
                leadingIcon: const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 18,
                ),
                child: Text(l10n.tOr('assignUserRoles', 'Assign user roles')),
              ),
            if (canManage)
              MenuItemButton(
                onPressed: onDelete == null || role.isSystem
                    ? null
                    : () => onDelete!(role),
                leadingIcon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: role.isSystem
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
                child: Text(
                  role.isSystem
                      ? l10n.tOr(
                          'rbacSystemRoleDeleteBlocked',
                          'System roles cannot be deleted',
                        )
                      : l10n.tOr('deleteRole', 'Delete role'),
                  style: TextStyle(
                    color: role.isSystem
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RoleBadges extends StatelessWidget {
  const _RoleBadges({required this.role});

  final RoleEntity role;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        RbacBadge(
          label: role.isSystem
              ? context.l10n.tOr('system', 'System')
              : context.l10n.tOr('custom', 'Custom'),
          emphasized: role.isSystem,
        ),
        RbacBadge(
          label: role.isActive
              ? context.l10n.tOr('active', 'Active')
              : context.l10n.tOr('inactive', 'Inactive'),
          emphasized: role.isActive,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    this.onView,
    this.onEdit,
    this.onAssignUsers,
    this.onViewRoleUsers,
    this.onDelete,
  });

  final RoleEntity role;
  final ValueChanged<RoleEntity>? onView;
  final ValueChanged<RoleEntity>? onEdit;
  final ValueChanged<RoleEntity>? onAssignUsers;
  final ValueChanged<RoleEntity>? onViewRoleUsers;
  final ValueChanged<RoleEntity>? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView == null ? null : () => onView!(role),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: role.isSystem
                          ? scheme.primaryContainer.withValues(alpha: 0.6)
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      role.isSystem
                          ? Icons.verified_user_outlined
                          : Icons.shield_outlined,
                      size: 20,
                      color: role.isSystem
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          role.slug,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // Actions stay at the top so they're reachable without
                  // scanning the whole card.
                  _RoleActions(
                    role: role,
                    onView: onView,
                    onEdit: onEdit,
                    onAssignUsers: onAssignUsers,
                    onViewRoleUsers: onViewRoleUsers,
                    onDelete: onDelete,
                  ),
                ],
              ),
              if (role.description != null &&
                  role.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  role.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _RoleBadges(role: role),
                  RbacBadge(
                    label:
                        '${role.permissionCount} '
                        '${l10n.tOr('permissions', 'Permissions')}',
                  ),
                  RbacBadge(
                    label: '${role.userCount} ${l10n.tOr('users', 'Users')}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolesTable extends StatelessWidget {
  const _RolesTable({
    required this.roles,
    required this.maxWidth,
    this.onView,
    this.onEdit,
    this.onAssignUsers,
    this.onViewRoleUsers,
    this.onDelete,
  });

  final List<RoleEntity> roles;
  final double maxWidth;
  final ValueChanged<RoleEntity>? onView;
  final ValueChanged<RoleEntity>? onEdit;
  final ValueChanged<RoleEntity>? onAssignUsers;
  final ValueChanged<RoleEntity>? onViewRoleUsers;
  final ValueChanged<RoleEntity>? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Columns adapt to width so the Actions column is always visible
    // without horizontal scrolling.
    final showCounts = maxWidth >= 860;
    final showType = maxWidth >= 1000;
    final showCreated = maxWidth >= 1150;
    final showDescription = maxWidth >= 1300;

    final headingStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    // Cap the role cell so long names ellipsize instead of widening the
    // table beyond the card.
    final roleCellMaxWidth = (maxWidth * 0.32).clamp(170.0, 340.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(
              scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            headingTextStyle: headingStyle,
            columns: [
              DataColumn(label: Text(l10n.tOr('role', 'Role'))),
              if (showDescription)
                DataColumn(label: Text(l10n.tOr('description', 'Description'))),
              if (showCounts) ...[
                DataColumn(
                  label: Text(l10n.tOr('permissions', 'Permissions')),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(l10n.tOr('users', 'Users')),
                  numeric: true,
                ),
              ],
              if (showType) DataColumn(label: Text(l10n.tOr('type', 'Type'))),
              DataColumn(label: Text(l10n.tOr('status', 'Status'))),
              if (showCreated)
                DataColumn(label: Text(l10n.tOr('created', 'Created'))),
              DataColumn(label: Text(l10n.tOr('actions', 'Actions'))),
            ],
            rows: roles
                .map(
                  (role) => DataRow(
                    cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: roleCellMaxWidth,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: role.isSystem
                                      ? scheme.primaryContainer.withValues(
                                          alpha: 0.6,
                                        )
                                      : scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  role.isSystem
                                      ? Icons.verified_user_outlined
                                      : Icons.shield_outlined,
                                  size: 18,
                                  color: role.isSystem
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      role.slug,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showDescription)
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Text(
                              role.description ?? '—',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      if (showCounts) ...[
                        DataCell(Text('${role.permissionCount}')),
                        DataCell(Text('${role.userCount}')),
                      ],
                      if (showType)
                        DataCell(
                          RbacBadge(
                            label: role.isSystem
                                ? l10n.tOr('system', 'System')
                                : l10n.tOr('custom', 'Custom'),
                            emphasized: role.isSystem,
                          ),
                        ),
                      DataCell(
                        RbacBadge(
                          label: role.isActive
                              ? l10n.tOr('active', 'Active')
                              : l10n.tOr('inactive', 'Inactive'),
                          emphasized: role.isActive,
                        ),
                      ),
                      if (showCreated)
                        DataCell(Text(formatRbacDate(role.createdAt))),
                      DataCell(
                        _RoleActions(
                          role: role,
                          onView: onView,
                          onEdit: onEdit,
                          onAssignUsers: onAssignUsers,
                          onViewRoleUsers: onViewRoleUsers,
                          onDelete: onDelete,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}
