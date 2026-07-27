import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';
import '../utils/selected_users_actions.dart';
import '../utils/responsive.dart';
import 'users_bulk_confirm_dialog.dart';

/// Selection bar with select-all controls (left) and bulk admin actions (right).
/// Hidden until at least one user is selected — matches [BulkSelectionToolbar].
class UsersSelectionHeader extends StatelessWidget {
  const UsersSelectionHeader({super.key, required this.metrics});

  final UsersLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<UsersBloc, UsersState, _UsersSelectionBarData>(
      selector: (state) {
        if (state is! UsersLoaded || !state.hasSelection) {
          return const _UsersSelectionBarData.hidden();
        }
        final selectedUsers = state.users
            .where((u) => state.selectedUserIds.contains(u.id))
            .toList();
        return _UsersSelectionBarData(
          state: state,
          allVisibleSelected: state.allVisibleSelected(state.users),
          someVisibleSelected: state.someVisibleSelected(state.users),
          actions: SelectedUsersActions(selectedUsers),
        );
      },
      builder: (context, data) {
        if (!data.visible) return const SizedBox.shrink();

        final state = data.state!;
        final actions = data.actions;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.compactSelectionBar ? 6 : 10,
            vertical: metrics.compactSelectionBar ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: state.isBulkActionLoading,
                child: Opacity(
                  opacity: state.isBulkActionLoading ? 0.55 : 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Collapse bulk admin actions before they collide with
                      // the selection controls on laptop/MacBook widths.
                      final narrow = metrics.compactSelectionBar ||
                          constraints.maxWidth < 1180;
                      return Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Checkbox(
                                  tristate: true,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  value: data.allVisibleSelected
                                      ? true
                                      : data.someVisibleSelected
                                          ? null
                                          : false,
                                  onChanged: (_) => context
                                      .read<UsersBloc>()
                                      .add(SelectAllUsersEvent()),
                                ),
                                Flexible(
                                  child: Text(
                                    context.tr('usersSelectedCount', {
                                      'count': '${state.selectedCount}',
                                    }),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (!narrow) ...[
                                  _ToolbarLink(
                                    icon: Icons.select_all_rounded,
                                    label: l10n.t('selectAllUsers'),
                                    onPressed: () => context
                                        .read<UsersBloc>()
                                        .add(SelectAllUsersEvent()),
                                  ),
                                  _ToolbarLink(
                                    icon: Icons.clear_all_rounded,
                                    label: l10n.t('clearSelection'),
                                    onPressed: () => context
                                        .read<UsersBloc>()
                                        .add(ClearUserSelectionEvent()),
                                  ),
                                ] else ...[
                                  IconButton(
                                    tooltip: l10n.t('selectAllUsers'),
                                    icon: const Icon(
                                      Icons.select_all_rounded,
                                      size: 20,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () => context
                                        .read<UsersBloc>()
                                        .add(SelectAllUsersEvent()),
                                  ),
                                  IconButton(
                                    tooltip: l10n.t('clearSelection'),
                                    icon: const Icon(
                                      Icons.clear_all_rounded,
                                      size: 20,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    onPressed: () => context
                                        .read<UsersBloc>()
                                        .add(ClearUserSelectionEvent()),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (narrow)
                            _BulkActionsMenu(l10n: l10n, actions: actions)
                          else ...[
                            if (actions.showBan) ...[
                              _BanButton(l10n: l10n, compact: false),
                              const SizedBox(width: 6),
                            ],
                            if (actions.showUnban) ...[
                              _UnbanButton(l10n: l10n, compact: false),
                              const SizedBox(width: 6),
                            ],
                            if (actions.showPromote) ...[
                              _PromoteButton(l10n: l10n, compact: false),
                              const SizedBox(width: 6),
                            ],
                            if (actions.showDemote) ...[
                              _DemoteButton(l10n: l10n, compact: false),
                              const SizedBox(width: 6),
                            ],
                            _DeleteButton(l10n: l10n, compact: false),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (state.isBulkActionLoading)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BulkActionsMenu extends StatelessWidget {
  const _BulkActionsMenu({
    required this.l10n,
    required this.actions,
  });

  final AppLocalizations l10n;
  final SelectedUsersActions actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      icon: Icon(Icons.more_vert_rounded, color: scheme.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 8),
      onSelected: (value) async {
        switch (value) {
          case 'ban':
            await _confirmBulkBan(context, l10n);
          case 'unban':
            await _confirmBulkUnban(context, l10n);
          case 'promote':
            await _confirmBulkPromote(context, l10n);
          case 'demote':
            await _confirmBulkDemote(context, l10n);
          case 'delete':
            await _confirmBulkDelete(context, l10n);
        }
      },
      itemBuilder: (_) => [
        if (actions.showBan)
          PopupMenuItem(
            value: 'ban',
            child: Row(
              children: [
                const Icon(Icons.block_rounded, size: 18),
                const SizedBox(width: 10),
                Text(l10n.t('ban')),
              ],
            ),
          ),
        if (actions.showUnban)
          PopupMenuItem(
            value: 'unban',
            child: Row(
              children: [
                const Icon(Icons.lock_open_rounded, size: 18),
                const SizedBox(width: 10),
                Text(l10n.t('unban')),
              ],
            ),
          ),
        if (actions.showPromote)
          PopupMenuItem(
            value: 'promote',
            child: Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 18),
                const SizedBox(width: 10),
                Text(l10n.t('promote')),
              ],
            ),
          ),
        if (actions.showDemote)
          PopupMenuItem(
            value: 'demote',
            child: Row(
              children: [
                const Icon(Icons.arrow_downward_rounded, size: 18),
                const SizedBox(width: 10),
                Text(l10n.t('demote')),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 10),
              Text(l10n.t('delete'), style: TextStyle(color: scheme.error)),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmBulkBan(BuildContext context, AppLocalizations l10n) async {
  final count = selectedUsersCount(context);
  if (count == 0) return;
  final confirmed = await confirmUsersBulkAction(
    context,
    title: l10n.t('ban'),
    message: usersBanConfirmMessage(l10n, count),
    destructive: true,
  );
  if (confirmed && context.mounted) {
    context.read<UsersBloc>().add(BulkSuspendUsersEvent());
  }
}

Future<void> _confirmBulkUnban(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final count = selectedUsersCount(context);
  if (count == 0) return;
  final confirmed = await confirmUsersBulkAction(
    context,
    title: l10n.t('unban'),
    message: usersUnbanConfirmMessage(l10n, count),
  );
  if (confirmed && context.mounted) {
    context.read<UsersBloc>().add(BulkActivateUsersEvent());
  }
}

Future<void> _confirmBulkPromote(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final count = selectedUsersCount(context);
  if (count == 0) return;
  final confirmed = await confirmUsersBulkAction(
    context,
    title: l10n.t('promote'),
    message: usersPromoteConfirmMessage(l10n, count),
  );
  if (confirmed && context.mounted) {
    context.read<UsersBloc>().add(BulkPromoteUsersEvent());
  }
}

Future<void> _confirmBulkDemote(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final count = selectedUsersCount(context);
  if (count == 0) return;
  final confirmed = await confirmUsersBulkAction(
    context,
    title: l10n.t('demote'),
    message: usersDemoteConfirmMessage(l10n, count),
    destructive: true,
  );
  if (confirmed && context.mounted) {
    context.read<UsersBloc>().add(BulkDemoteUsersEvent());
  }
}

Future<void> _confirmBulkDelete(
  BuildContext context,
  AppLocalizations l10n,
) async {
  final count = selectedUsersCount(context);
  if (count == 0) return;
  final confirmed = await confirmUsersBulkAction(
    context,
    title: l10n.t('delete'),
    message: usersDeleteConfirmMessage(l10n, count),
    destructive: true,
  );
  if (confirmed && context.mounted) {
    context.read<UsersBloc>().add(BulkDeleteUsersEvent());
  }
}

class _ToolbarLink extends StatelessWidget {
  const _ToolbarLink({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontSize: 12.5)),
    );
  }
}

class _BanButton extends StatelessWidget {
  const _BanButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmBan(context),
            tooltip: l10n.t('ban'),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.block_rounded, size: 18),
          )
        : OutlinedButton.icon(
            onPressed: () => _confirmBan(context),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            icon: const Icon(Icons.block_rounded, size: 17),
            label: Text(
              l10n.t('ban'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmBan(BuildContext context) async {
    final count = selectedUsersCount(context);
    if (count == 0) return;

    final confirmed = await confirmUsersBulkAction(
      context,
      title: l10n.t('ban'),
      message: usersBanConfirmMessage(l10n, count),
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<UsersBloc>().add(BulkSuspendUsersEvent());
    }
  }
}

class _UnbanButton extends StatelessWidget {
  const _UnbanButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmUnban(context),
            tooltip: l10n.t('unban'),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
          )
        : OutlinedButton.icon(
            onPressed: () => _confirmUnban(context),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            icon: const Icon(Icons.lock_open_rounded, size: 17),
            label: Text(
              l10n.t('unban'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmUnban(BuildContext context) async {
    final count = selectedUsersCount(context);
    if (count == 0) return;

    final confirmed = await confirmUsersBulkAction(
      context,
      title: l10n.t('unban'),
      message: usersUnbanConfirmMessage(l10n, count),
    );
    if (confirmed && context.mounted) {
      context.read<UsersBloc>().add(BulkActivateUsersEvent());
    }
  }
}

class _PromoteButton extends StatelessWidget {
  const _PromoteButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmPromote(context),
            tooltip: l10n.t('promote'),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
          )
        : OutlinedButton.icon(
            onPressed: () => _confirmPromote(context),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            icon: const Icon(Icons.arrow_upward_rounded, size: 17),
            label: Text(
              l10n.t('promote'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmPromote(BuildContext context) async {
    final count = selectedUsersCount(context);
    if (count == 0) return;

    final confirmed = await confirmUsersBulkAction(
      context,
      title: l10n.t('promote'),
      message: usersPromoteConfirmMessage(l10n, count),
    );
    if (confirmed && context.mounted) {
      context.read<UsersBloc>().add(BulkPromoteUsersEvent());
    }
  }
}

class _DemoteButton extends StatelessWidget {
  const _DemoteButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmDemote(context),
            tooltip: l10n.t('demote'),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
          )
        : OutlinedButton.icon(
            onPressed: () => _confirmDemote(context),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: scheme.outlineVariant),
            ),
            icon: const Icon(Icons.arrow_downward_rounded, size: 17),
            label: Text(
              l10n.t('demote'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmDemote(BuildContext context) async {
    final count = selectedUsersCount(context);
    if (count == 0) return;

    final confirmed = await confirmUsersBulkAction(
      context,
      title: l10n.t('demote'),
      message: usersDemoteConfirmMessage(l10n, count),
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<UsersBloc>().add(BulkDemoteUsersEvent());
    }
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.l10n, this.compact = false});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return compact
        ? IconButton.filledTonal(
            onPressed: () => _confirmDelete(context),
            tooltip: l10n.t('delete'),
            style: IconButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          )
        : FilledButton.tonalIcon(
            onPressed: () => _confirmDelete(context),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(64, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: Text(
              l10n.t('delete'),
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final count = selectedUsersCount(context);
    if (count == 0) return;

    final confirmed = await confirmUsersBulkAction(
      context,
      title: l10n.t('delete'),
      message: usersDeleteConfirmMessage(l10n, count),
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<UsersBloc>().add(BulkDeleteUsersEvent());
    }
  }
}

class _UsersSelectionBarData {
  const _UsersSelectionBarData({
    required this.state,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.actions,
  }) : visible = true;

  const _UsersSelectionBarData.hidden()
      : state = null,
        allVisibleSelected = false,
        someVisibleSelected = false,
        actions = const SelectedUsersActions([]),
        visible = false;

  final UsersLoaded? state;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final SelectedUsersActions actions;
  final bool visible;
}

