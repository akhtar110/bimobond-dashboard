import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/rbac_repository.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import '../widgets/permission_selector.dart';
import '../widgets/rbac_ui.dart';

final RegExp _slugPattern = RegExp(r'^[a-z][a-z0-9_]*$');

class CreateEditRolePage extends StatefulWidget {
  const CreateEditRolePage({
    super.key,
    this.role,
    this.onSaved,
    this.onBack,
  });

  final RoleEntity? role;
  final ValueChanged<RoleEntity>? onSaved;
  final VoidCallback? onBack;

  @override
  State<CreateEditRolePage> createState() => _CreateEditRolePageState();
}

class _CreateEditRolePageState extends State<CreateEditRolePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slugController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Set<String> _permissionIds;
  late bool _isActive;
  bool _hydratedFromDetails = false;

  bool get _editing => widget.role != null;
  bool get _isSystemRole => widget.role?.isSystem == true;

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController(text: widget.role?.slug);
    _nameController = TextEditingController(text: widget.role?.name);
    _descriptionController = TextEditingController(
      text: widget.role?.description,
    );
    _permissionIds =
        widget.role?.permissions.map((permission) => permission.id).toSet() ??
        <String>{};
    _isActive = widget.role?.isActive ?? true;
    final bloc = context.read<RbacBloc>();
    bloc.add(const LoadPermissions());
    // List summaries omit permissions — load details so the picker is populated.
    if (_editing && (widget.role?.permissions.isEmpty ?? true)) {
      bloc.add(LoadRoleDetails(widget.role!.id));
    }
  }

  @override
  void dispose() {
    _slugController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final description = _descriptionController.text.trim();
    final slug = _slugController.text.trim();
    final draft = RoleDraft(
      // PATCH rejects slug changes on system roles, so only send the slug
      // when it actually changed. An empty slug is omitted from the body.
      slug: _editing && slug == widget.role!.slug ? '' : slug,
      name: _nameController.text.trim(),
      permissionIds: _permissionIds.toList(growable: false),
      // Send an empty value too, so PATCH can explicitly clear a description.
      description: description,
      isActive: _isActive,
    );
    final bloc = context.read<RbacBloc>();
    if (_editing) {
      bloc.add(UpdateRole(widget.role!.id, draft));
    } else {
      bloc.add(CreateRole(draft));
    }
  }

  String? _validateSlug(String? value) {
    final slug = value?.trim() ?? '';
    if (slug.length < 2) {
      return context.l10n.tOr(
        'roleSlugTooShort',
        'Slug must be at least 2 characters',
      );
    }
    if (!_slugPattern.hasMatch(slug)) {
      return context.l10n.tOr(
        'roleSlugInvalid',
        'Use lowercase letters, digits, and underscores; start with a letter',
      );
    }
    return null;
  }

  String? _validateName(String? value) {
    if ((value?.trim().length ?? 0) < 2) {
      return context.l10n.tOr(
        'roleNameTooShort',
        'Name must be at least 2 characters',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RbacBloc, RbacState>(
      listenWhen: (previous, current) =>
          previous.selectedRole != current.selectedRole ||
          (current.feedback != null && previous.feedback != current.feedback) ||
          (current.errorMessage != null &&
              previous.errorMessage != current.errorMessage),
      listener: (context, state) {
        // Hydrate permission selection once role details arrive.
        if (_editing &&
            !_hydratedFromDetails &&
            state.selectedRole?.id == widget.role?.id &&
            state.selectedRole!.permissions.isNotEmpty) {
          _hydratedFromDetails = true;
          setState(() {
            _permissionIds = state.selectedRole!.permissions
                .map((permission) => permission.id)
                .toSet();
            _isActive = state.selectedRole!.isActive;
            if (_descriptionController.text.isEmpty &&
                (state.selectedRole!.description?.isNotEmpty ?? false)) {
              _descriptionController.text = state.selectedRole!.description!;
            }
          });
        }

        if (state.feedback != null) {
          showRbacFeedback(
            context,
            rbacFeedbackText(context, state.feedback!),
            false,
          );
          final saved =
              state.feedback == RbacFeedback.roleCreated ||
              state.feedback == RbacFeedback.roleUpdated;
          if (saved && state.selectedRole != null) {
            widget.onSaved?.call(state.selectedRole!);
          }
        } else if (state.errorMessage != null) {
          showRbacFeedback(
            context,
            rbacErrorText(context, state.errorMessage!),
            true,
          );
        }
        if (state.feedback != null || state.errorMessage != null) {
          context.read<RbacBloc>().add(const ClearRbacFeedback());
        }
      },
      builder: (context, state) => RbacPageFrame(
        title: _editing
            ? context.l10n.tOr('editRole', 'Edit role')
            : context.l10n.tOr('createRole', 'Create role'),
        subtitle: context.l10n.tOr(
          'roleFormSubtitle',
          'Define the role and choose the access it grants.',
        ),
        onBack: widget.onBack,
        actions: [
          FilledButton.icon(
            onPressed: state.isSubmitting ? null : _submit,
            icon: state.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(context.l10n.tOr('save', 'Save')),
          ),
        ],
        child: state.status == RbacStatus.loading && state.permissions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.status == RbacStatus.failure && state.permissions.isEmpty
            ? RbacErrorView(
                message: state.errorMessage == null
                    ? context.l10n.tOr(
                        'rbacPermissionsLoadFailed',
                        'Unable to load permissions',
                      )
                    : rbacErrorText(context, state.errorMessage!),
                onRetry: () =>
                    context.read<RbacBloc>().add(const LoadPermissions()),
              )
            : _form(context, state),
      ),
    );
  }

  Widget _form(BuildContext context, RbacState state) {
    final details = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _slugController,
            enabled: !_isSystemRole,
            decoration: InputDecoration(
              labelText: context.l10n.tOr('roleSlug', 'Slug'),
              helperText: _isSystemRole
                  ? context.l10n.tOr(
                      'rbacSystemRoleSlugLocked',
                      'System role slug cannot be modified',
                    )
                  : context.l10n.tOr(
                      'roleSlugHelper',
                      'Lowercase identifier, e.g. content_moderator',
                    ),
              border: const OutlineInputBorder(),
            ),
            validator: _validateSlug,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.l10n.tOr('roleName', 'Role name'),
              border: const OutlineInputBorder(),
            ),
            validator: _validateName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: context.l10n.tOr('description', 'Description'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            title: Text(context.l10n.tOr('active', 'Active')),
            subtitle: Text(
              context.l10n.tOr(
                'roleActiveHelper',
                'Inactive roles keep their configuration but grant nothing.',
              ),
            ),
            contentPadding: EdgeInsetsDirectional.zero,
          ),
          const SizedBox(height: 12),
          Text(
            '${_permissionIds.length} '
            '${context.l10n.tOr('permissionsSelected', 'permissions selected')}',
          ),
        ],
      ),
    );
    final selector = PermissionSelector(
      permissions: state.permissions,
      selectedIds: _permissionIds,
      onChanged: (ids) => setState(() => _permissionIds = ids),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 360,
                child: SingleChildScrollView(child: details),
              ),
              const SizedBox(width: 20),
              Expanded(child: SingleChildScrollView(child: selector)),
            ],
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [details, const SizedBox(height: 20), selector],
          ),
        );
      },
    );
  }
}
