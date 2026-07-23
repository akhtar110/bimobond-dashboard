import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/role_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../utils/permission_manager.dart';
import 'rbac_ui.dart';

/// Compact dialog to assign / remove RBAC roles for a user.
///
/// Requires both `users.admin.roles.assign` and `users.admin.roles.manage`
/// (backend PUT enforces both).
class AssignUserRolesDialog extends StatefulWidget {
  const AssignUserRolesDialog({
    super.key,
    required this.userId,
    this.userLabel,
  });

  final String userId;
  final String? userLabel;

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    String? userLabel,
  }) {
    if (!PermissionManager.canAssignRoles(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            context.l10n.tOr(
              'rbacInsufficientPermissions',
              'Insufficient permissions',
            ),
          ),
        ),
      );
      return Future.value(null);
    }

    final rbacBloc = context.read<RbacBloc>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: rbacBloc,
        child: AssignUserRolesDialog(
          userId: userId,
          userLabel: userLabel,
        ),
      ),
    );
  }

  @override
  State<AssignUserRolesDialog> createState() => _AssignUserRolesDialogState();
}

class _AssignUserRolesDialogState extends State<AssignUserRolesDialog> {
  Set<String>? _selectedRoleIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<RbacBloc>()
      ..add(const LoadRoles())
      ..add(LoadUserRoles(widget.userId));
  }

  List<RoleEntity> _visible(List<RoleEntity> roles) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return roles;
    return roles
        .where(
          (role) =>
              role.name.toLowerCase().contains(query) ||
              role.slug.toLowerCase().contains(query),
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

  void _clearAll() => setState(() => _selectedRoleIds = <String>{});

  void _selectAllActive(List<RoleEntity> roles) {
    setState(() {
      _selectedRoleIds = roles
          .where((role) => role.isActive)
          .map((role) => role.id)
          .toSet();
    });
  }

  void _save(Set<String> selected) {
    context.read<RbacBloc>().add(
      AssignUserRoles(widget.userId, selected.toList(growable: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 480;
    final dialogWidth = math.min(480.0, size.width - (isCompact ? 24 : 48));
    final dialogHeight = math.min(560.0, size.height * 0.85);

    return BlocConsumer<RbacBloc, RbacState>(
      listenWhen: (previous, current) =>
          previous.userRoleContext != current.userRoleContext ||
          (current.feedback != null && previous.feedback != current.feedback) ||
          (current.errorMessage != null &&
              previous.errorMessage != current.errorMessage),
      listener: (context, state) {
        if (state.activeUserId == widget.userId &&
            state.userRoleContext != null &&
            _selectedRoleIds == null) {
          setState(() {
            _selectedRoleIds = state.userRoleContext!.roles
                .map((role) => role.id)
                .toSet();
          });
        }

        if (state.feedback == RbacFeedback.userRolesUpdated) {
          context.read<RbacBloc>().add(const ClearRbacFeedback());
          Navigator.of(context).pop(true);
          return;
        }

        if (state.errorMessage != null) {
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
                ? state.userRoleContext?.roles.map((r) => r.id).toSet() ??
                      <String>{}
                : <String>{});
        final roles = _visible(state.roles);
        final loading =
            state.status == RbacStatus.loading && state.roles.isEmpty;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.tOr('manageRoles', 'Manage Roles'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (widget.userLabel != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.userLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.tOr('searchRoles', 'Search roles'),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: state.isSubmitting || roles.isEmpty
                            ? null
                            : () => _selectAllActive(state.roles),
                        child: Text(l10n.tOr('selectAll', 'Select all')),
                      ),
                      TextButton(
                        onPressed: state.isSubmitting || selected.isEmpty
                            ? null
                            : _clearAll,
                        child: Text(l10n.tOr('clearAll', 'Clear all')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${selected.length} ${l10n.tOr('selected', 'selected')}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : roles.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.tOr('noRolesFound', 'No roles found'),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: roles.length,
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            final checked = selected.contains(role.id);
                            return CheckboxListTile(
                              dense: true,
                              value: checked,
                              onChanged: state.isSubmitting || !role.isActive
                                  ? null
                                  : (value) =>
                                        _toggle(role.id, value ?? false),
                              title: Text(
                                role.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                role.slug,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              secondary: role.isSystem
                                  ? RbacBadge(
                                      label: l10n.tOr('system', 'System'),
                                      emphasized: true,
                                    )
                                  : (!role.isActive
                                        ? RbacBadge(
                                            label: l10n.tOr(
                                              'inactive',
                                              'Inactive',
                                            ),
                                          )
                                        : null),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => Navigator.pop(context, false),
                          child: Text(l10n.t('cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => _save(selected),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.tOr('save', 'Save')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
