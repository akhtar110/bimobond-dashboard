import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';

class UserActionButtons extends StatelessWidget {
  const UserActionButtons({
    super.key,
    required this.user,
    this.compact = false,
  });

  final UserEntity user;
  final bool compact;

  bool get _isAdmin => user.roles.contains(UserRole.admin);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<UsersBloc>();

    if (compact) {
      return _CompactActionsMenu(
        user: user,
        isAdmin: _isAdmin,
        onDetails: () => _openDetails(context),
        onBan: () => bloc.add(ToggleBanUserEvent(user.id)),
        onPromote: () => bloc.add(PromoteUserEvent(user.id)),
        onDemote: () => bloc.add(DemoteUserEvent(user.id)),
        onDelete: () => UserDeleteDialog.show(context, user.id),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        _ActionChip(
          label: l10n.t('details'),
          icon: Icons.open_in_new_rounded,
          onPressed: () => _openDetails(context),
        ),
        _ActionChip(
          label: user.isBanned ? l10n.t('unban') : l10n.t('ban'),
          icon: user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
          onPressed: () => bloc.add(ToggleBanUserEvent(user.id)),
        ),
        _ActionChip(
          label: _isAdmin ? l10n.t('demote') : l10n.t('promote'),
          icon: _isAdmin
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          onPressed: () => bloc.add(
            _isAdmin ? DemoteUserEvent(user.id) : PromoteUserEvent(user.id),
          ),
        ),
        _ActionChip(
          label: l10n.t('delete'),
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onPressed: () => UserDeleteDialog.show(context, user.id),
        ),
      ],
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.userDetail, arguments: user);
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDestructive ? const Color(0xFFEF4444) : theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: 0.08),
        splashColor: color.withValues(alpha: 0.12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.45 : 0.35),
            ),
            color: isDark
                ? color.withValues(alpha: 0.06)
                : color.withValues(alpha: 0.04),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactActionsMenu extends StatelessWidget {
  const _CompactActionsMenu({
    required this.user,
    required this.isAdmin,
    required this.onDetails,
    required this.onBan,
    required this.onPromote,
    required this.onDemote,
    required this.onDelete,
  });

  final UserEntity user;
  final bool isAdmin;
  final VoidCallback onDetails;
  final VoidCallback onBan;
  final VoidCallback onPromote;
  final VoidCallback onDemote;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 8),
      icon: Icon(
        Icons.more_horiz_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onSelected: (value) {
        switch (value) {
          case 'details':
            onDetails();
          case 'ban':
            onBan();
          case 'promote':
            isAdmin ? onDemote() : onPromote();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'details',
          child: _MenuRow(Icons.open_in_new_rounded, l10n.t('details')),
        ),
        PopupMenuItem(
          value: 'ban',
          child: _MenuRow(
            user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
            user.isBanned ? l10n.t('unban') : l10n.t('ban'),
          ),
        ),
        PopupMenuItem(
          value: 'promote',
          child: _MenuRow(
            isAdmin ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            isAdmin ? l10n.t('demote') : l10n.t('promote'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            Icons.delete_outline_rounded,
            l10n.t('delete'),
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class UserDeleteDialog {
  static void show(BuildContext context, String userId) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 32),
        title: Text(
          l10n.t('deleteUserTitle'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.t('deleteUserMessage'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UsersBloc>().add(DeleteUserEvent(userId));
            },
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }
}
