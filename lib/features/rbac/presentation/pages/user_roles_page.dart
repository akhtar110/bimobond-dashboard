import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/role_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/permission_manager.dart';
import '../utils/rbac_responsive.dart';
import '../widgets/rbac_ui.dart';

class UserRolesPage extends StatefulWidget {
  const UserRolesPage({
    super.key,
    required this.userId,
    this.userLabel,
    this.onSaved,
    this.onBack,
  });

  final String userId;
  final String? userLabel;
  final VoidCallback? onSaved;
  final VoidCallback? onBack;

  @override
  State<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends State<UserRolesPage> {
  Set<String>? _selectedRoleIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<RbacBloc>()
      ..add(const LoadRoles())
      ..add(LoadUserRoles(widget.userId));
  }

  List<RoleEntity> _visibleRoles(List<RoleEntity> roles) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return roles;
    return roles
        .where(
          (role) =>
              role.name.toLowerCase().contains(query) ||
              role.slug.toLowerCase().contains(query) ||
              (role.description ?? '').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  void _toggle(String roleId, bool selected) {
    setState(() {
      final next = Set<String>.of(_selectedRoleIds ?? const {});
      selected ? next.add(roleId) : next.remove(roleId);
      _selectedRoleIds = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RbacBloc, RbacState>(
      listenWhen: (previous, current) =>
          previous.userRoleContext != current.userRoleContext ||
          (current.feedback != null && previous.feedback != current.feedback) ||
          (current.errorMessage != null &&
              previous.errorMessage != current.errorMessage),
      listener: (context, state) {
        if (state.activeUserId == widget.userId &&
            state.userRoleContext != null) {
          setState(() {
            _selectedRoleIds = state.userRoleContext!.roles
                .map((role) => role.id)
                .toSet();
          });
        }
        if (state.feedback != null) {
          showRbacFeedback(
            context,
            rbacFeedbackText(context, state.feedback!),
            false,
          );
          if (state.feedback == RbacFeedback.userRolesUpdated) {
            widget.onSaved?.call();
          }
          context.read<RbacBloc>().add(const ClearRbacFeedback());
        } else if (state.errorMessage != null) {
          showRbacFeedback(
            context,
            rbacErrorText(context, state.errorMessage!),
            true,
          );
          context.read<RbacBloc>().add(const ClearRbacFeedback());
        }
      },
      builder: (context, state) {
        final selected =
            _selectedRoleIds ??
            (state.activeUserId == widget.userId
                ? state.userRoleContext?.roles.map((role) => role.id).toSet() ??
                      <String>{}
                : <String>{});
        final visibleRoles = _visibleRoles(state.roles);
        final metrics = RbacLayoutMetrics(
          getRbacDeviceType(MediaQuery.sizeOf(context).width),
        );
        return RbacPageFrame(
          title: widget.userLabel == null || widget.userLabel!.trim().isEmpty
              ? context.l10n.tOr('userRoles', 'User roles')
              : '${context.l10n.tOr('userRoles', 'User roles')} · ${widget.userLabel}',
          metrics: metrics,
          onBack: widget.onBack,
          actions: [
            PermissionGate(
              allOf: RbacPermissionKeys.assignmentKeys,
              child: RbacHeaderAction(
                compact: metrics.useIconActions,
                icon: Icons.save_outlined,
                label: context.l10n.tOr(
                  'saveAssignments',
                  'Save assignments',
                ),
                outlined: false,
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting
                    ? null
                    : () => context.read<RbacBloc>().add(
                        AssignUserRoles(
                          widget.userId,
                          selected.toList(growable: false),
                        ),
                      ),
              ),
            ),
          ],
          child: _body(context, state, visibleRoles, selected),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    RbacState state,
    List<RoleEntity> visibleRoles,
    Set<String> selected,
  ) {
    if (state.status == RbacStatus.loading && state.roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == RbacStatus.failure && state.roles.isEmpty) {
      return RbacErrorView(
        message: state.errorMessage == null
            ? context.l10n.tOr(
                'rbacUserRolesLoadFailed',
                'Unable to load user roles',
              )
            : rbacErrorText(context, state.errorMessage!),
        onRetry: () {
          context.read<RbacBloc>()
            ..add(const LoadRoles())
            ..add(LoadUserRoles(widget.userId));
        },
      );
    }
    final userContext = state.activeUserId == widget.userId
        ? state.userRoleContext
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (userContext != null) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              RbacBadge(
                label:
                    '${context.l10n.tOr('roles', 'Roles')}: '
                    '${userContext.roleSlugs.length}',
              ),
              RbacBadge(
                label:
                    '${context.l10n.tOr('permissions', 'Permissions')}: '
                    '${userContext.permissions.length}',
              ),
              if (userContext.legacyRoles.isNotEmpty)
                RbacBadge(
                  label:
                      '${context.l10n.tOr('legacyRoles', 'Legacy roles')}: '
                      '${userContext.legacyRoles.join(', ')}',
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          decoration: InputDecoration(
            labelText: context.l10n.tOr('searchRoles', 'Search roles'),
            prefixIcon: const Icon(Icons.search_rounded),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: visibleRoles.isEmpty
              ? RbacEmptyView(
                  title: context.l10n.tOr('noRolesFound', 'No roles found'),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return ListView.builder(
                        itemCount: visibleRoles.length,
                        itemBuilder: (context, index) {
                          final role = visibleRoles[index];
                          return Card(
                            child: CheckboxListTile(
                              value: selected.contains(role.id),
                              onChanged: role.isActive
                                  ? (value) => _toggle(role.id, value ?? false)
                                  : null,
                              title: Text(role.name),
                              subtitle: Text(role.description ?? role.slug),
                              secondary: RbacBadge(
                                label: role.isActive
                                    ? context.l10n.tOr('active', 'Active')
                                    : context.l10n.tOr('inactive', 'Inactive'),
                                emphasized: role.isActive,
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return Card(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columns: [
                              DataColumn(
                                label: Text(
                                  context.l10n.tOr('assigned', 'Assigned'),
                                ),
                              ),
                              DataColumn(
                                label: Text(context.l10n.tOr('role', 'Role')),
                              ),
                              DataColumn(
                                label: Text(context.l10n.tOr('slug', 'Slug')),
                              ),
                              DataColumn(
                                label: Text(
                                  context.l10n.tOr('status', 'Status'),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  context.l10n.tOr(
                                    'permissions',
                                    'Permissions',
                                  ),
                                ),
                              ),
                            ],
                            rows: visibleRoles
                                .map(
                                  (role) => DataRow(
                                    selected: selected.contains(role.id),
                                    cells: [
                                      DataCell(
                                        Checkbox(
                                          value: selected.contains(role.id),
                                          onChanged: role.isActive
                                              ? (value) => _toggle(
                                                  role.id,
                                                  value ?? false,
                                                )
                                              : null,
                                        ),
                                      ),
                                      DataCell(Text(role.name)),
                                      DataCell(Text(role.slug)),
                                      DataCell(
                                        RbacBadge(
                                          label: role.isActive
                                              ? context.l10n.tOr(
                                                  'active',
                                                  'Active',
                                                )
                                              : context.l10n.tOr(
                                                  'inactive',
                                                  'Inactive',
                                                ),
                                          emphasized: role.isActive,
                                        ),
                                      ),
                                      DataCell(Text('${role.permissionCount}')),
                                    ],
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
