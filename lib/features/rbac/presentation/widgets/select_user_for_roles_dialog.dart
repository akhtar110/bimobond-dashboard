import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';

/// Result of picking a user for RBAC role assignment.
class RbacUserPick {
  const RbacUserPick({required this.userId, required this.label});

  final String userId;
  final String label;
}

/// Responsive dialog: search users by username / name / email, then continue.
class SelectUserForRolesDialog extends StatefulWidget {
  const SelectUserForRolesDialog({super.key});

  static Future<RbacUserPick?> show(BuildContext context) {
    return showDialog<RbacUserPick>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SelectUserForRolesDialog(),
    );
  }

  @override
  State<SelectUserForRolesDialog> createState() =>
      _SelectUserForRolesDialogState();
}

class _SelectUserForRolesDialogState extends State<SelectUserForRolesDialog> {
  UserEntity? _selected;
  bool _showError = false;

  void _submit() {
    final user = _selected;
    if (user == null) {
      setState(() => _showError = true);
      return;
    }
    final label = user.fullName?.trim().isNotEmpty == true
        ? '${user.fullName} (@${user.username})'
        : '@${user.username}';
    Navigator.pop(
      context,
      RbacUserPick(userId: user.id, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 480;
    final maxWidth = isCompact ? size.width - 24.0 : 440.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 20,
            16,
            isCompact ? 16 : 20,
            isCompact ? 16 : 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.person_search_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tOr('assignUserRoles', 'Assign user roles'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tOr(
                  'rbacSearchUserHint',
                  'Search by username, name, or email to pick a user.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              AdminUserSearchField(
                selectedUser: _selected,
                label: l10n.tOr('searchUsers', 'Search users'),
                hintText: l10n.tOr(
                  'rbacSearchUserFieldHint',
                  'Type a username or name…',
                ),
                onUserSelected: (user) {
                  setState(() {
                    _selected = user;
                    _showError = false;
                  });
                },
              ),
              if (_showError) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.tOr('rbacSelectUserRequired', 'Select a user to continue'),
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ],
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selected!.fullName?.trim().isNotEmpty == true
                              ? '${_selected!.fullName} (@${_selected!.username})'
                              : '@${_selected!.username}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(l10n.tOr('continueLabel', 'Continue')),
                    ),
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
