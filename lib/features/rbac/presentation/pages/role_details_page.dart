import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/permission_entity.dart';
import '../../domain/entities/role_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/permission_manager.dart';
import '../widgets/rbac_ui.dart';

class RoleDetailsPage extends StatefulWidget {
  const RoleDetailsPage({
    super.key,
    required this.roleId,
    this.onEdit,
    this.onAssignUsers,
    this.onDeleted,
    this.onBack,
    this.onViewUsers,
  });

  final String roleId;
  final ValueChanged<RoleEntity>? onEdit;
  final ValueChanged<RoleEntity>? onAssignUsers;
  final VoidCallback? onDeleted;
  final VoidCallback? onBack;
  final ValueChanged<RoleEntity>? onViewUsers;

  @override
  State<RoleDetailsPage> createState() => _RoleDetailsPageState();
}

class _RoleDetailsPageState extends State<RoleDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<RbacBloc>().add(LoadRoleDetails(widget.roleId));
  }

  Future<void> _delete(RoleEntity role) async {
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
          if (state.feedback == RbacFeedback.roleDeleted) {
            widget.onDeleted?.call();
          }
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
        final role = state.selectedRole;
        return RbacPageFrame(
          title: role?.name ?? context.l10n.tOr('roleDetails', 'Role details'),
          subtitle: role?.slug,
          onBack: widget.onBack,
          actions: role == null
              ? const []
              : [
                  if (widget.onViewUsers != null)
                    OutlinedButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () => widget.onViewUsers!(role),
                      icon: const Icon(Icons.people_outline_rounded),
                      label: Text(
                        context.l10n.tOr('viewRoleUsers', 'View users'),
                      ),
                    ),
                  PermissionGate(
                    permission: RbacPermissionKeys.manageRoles,
                    allowLegacyAdmin: true,
                    child: OutlinedButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () => widget.onEdit?.call(role),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.l10n.tOr('editRole', 'Edit role')),
                    ),
                  ),
                  PermissionGate(
                    allOf: RbacPermissionKeys.assignmentKeys,
                    allowLegacyAdmin: true,
                    child: OutlinedButton.icon(
                      onPressed: state.isSubmitting
                          ? null
                          : () => widget.onAssignUsers?.call(role),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(
                        context.l10n.tOr('assignUserRoles', 'Assign user roles'),
                      ),
                    ),
                  ),
                  PermissionGate(
                    permission: RbacPermissionKeys.manageRoles,
                    allowLegacyAdmin: true,
                    child: Tooltip(
                      message: role.isSystem
                          ? context.l10n.tOr(
                              'rbacSystemRoleDeleteBlocked',
                              'System roles cannot be deleted',
                            )
                          : '',
                      child: FilledButton.tonalIcon(
                        onPressed: state.isSubmitting || role.isSystem
                            ? null
                            : () => _delete(role),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(context.l10n.tOr('deleteRole', 'Delete role')),
                      ),
                    ),
                  ),
                ],
          child: _body(context, state, role),
        );
      },
    );
  }

  Widget _body(BuildContext context, RbacState state, RoleEntity? role) {
    if (state.status == RbacStatus.loading && role == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == RbacStatus.failure && role == null) {
      return RbacErrorView(
        message: state.errorMessage == null
            ? context.l10n.tOr('rbacRoleLoadFailed', 'Unable to load role')
            : rbacErrorText(context, state.errorMessage!),
        onRetry: () =>
            context.read<RbacBloc>().add(LoadRoleDetails(widget.roleId)),
      );
    }
    if (role == null) {
      return RbacEmptyView(
        title: context.l10n.tOr('roleNotFound', 'Role not found'),
      );
    }

    final grouped = <String, List<PermissionEntity>>{};
    for (final permission in role.permissions) {
      grouped.putIfAbsent(permission.group, () => []).add(permission);
    }
    return ListView(
      children: [
        _MetadataCard(role: role),
        const SizedBox(height: 12),
        if (grouped.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(20),
              child: Text(
                context.l10n.tOr(
                  'roleHasNoPermissions',
                  'This role has no permissions assigned.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...grouped.entries.map(
            (entry) => Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(entry.key),
                subtitle: Text('${entry.value.length}'),
                children: entry.value
                    .map(
                      (permission) => ListTile(
                        leading: const Icon(Icons.check_circle_outline_rounded),
                        title: Text(permission.label),
                        subtitle: Text(permission.key),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.role});

  final RoleEntity role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(context.l10n.tOr('slug', 'Slug'), SelectableText(role.slug)),
            row(
              context.l10n.tOr('description', 'Description'),
              Text(role.description ?? '—'),
            ),
            row(
              context.l10n.tOr('type', 'Type'),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: RbacBadge(
                  label: role.isSystem
                      ? context.l10n.tOr('system', 'System')
                      : context.l10n.tOr('custom', 'Custom'),
                  emphasized: role.isSystem,
                ),
              ),
            ),
            row(
              context.l10n.tOr('status', 'Status'),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: RbacBadge(
                  label: role.isActive
                      ? context.l10n.tOr('active', 'Active')
                      : context.l10n.tOr('inactive', 'Inactive'),
                  emphasized: role.isActive,
                ),
              ),
            ),
            row(
              context.l10n.tOr('permissions', 'Permissions'),
              Text('${role.permissionCount}'),
            ),
            row(context.l10n.tOr('users', 'Users'), Text('${role.userCount}')),
            row(
              context.l10n.tOr('created', 'Created'),
              Text(formatRbacDate(role.createdAt)),
            ),
            row(
              context.l10n.tOr('updated', 'Updated'),
              Text(formatRbacDate(role.updatedAt)),
            ),
          ],
        ),
      ),
    );
  }
}
