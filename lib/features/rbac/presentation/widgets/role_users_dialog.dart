import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/role_user_entity.dart';
import '../bloc/rbac_bloc.dart';
import '../bloc/rbac_event.dart';
import 'rbac_ui.dart';

/// Shows role holders in a responsive dialog (desktop) or bottom sheet (mobile).
Future<void> showRoleUsersDialog(
  BuildContext context, {
  required RoleEntity role,
}) async {
  final rbacBloc = context.read<RbacBloc>();

  // Wait until the Actions [MenuAnchor] finishes disposing. Opening a dialog
  // in the same frame causes Flutter Web focus crashes
  // ("Cannot get renderObject of inactive element").
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;

  rbacBloc.add(LoadRoleUsers(role.id));

  final width = MediaQuery.sizeOf(context).width;
  final useSheet = width < 640;

  Widget wrap(Widget child) => BlocProvider.value(
        value: rbacBloc,
        child: child,
      );

  if (useSheet) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.85;
        return wrap(
          SizedBox(
            height: height,
            child: _RoleUsersPopupBody(
              role: role,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
          ),
        );
      },
    ).whenComplete(() {
      rbacBloc.add(const ClearRoleUsers());
    });
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return wrap(
        Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
            child: _RoleUsersPopupBody(
              role: role,
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ),
      );
    },
  ).whenComplete(() {
    rbacBloc.add(const ClearRoleUsers());
  });
}

class _RoleUsersPopupBody extends StatefulWidget {
  const _RoleUsersPopupBody({
    required this.role,
    required this.onClose,
  });

  final RoleEntity role;
  final VoidCallback onClose;

  @override
  State<_RoleUsersPopupBody> createState() => _RoleUsersPopupBodyState();
}

class _RoleUsersPopupBodyState extends State<_RoleUsersPopupBody> {
  String _query = '';
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List<RoleUserEntity> _filteredUsers(List<RoleUserEntity> users) {
    final normalized = _query.trim().toLowerCase();
    if (normalized.isEmpty) return users;
    return users
        .where(
          (user) =>
              user.username.toLowerCase().contains(normalized) ||
              user.displayName.toLowerCase().contains(normalized) ||
              (user.email ?? '').toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Future<void> _copyUsername(String username) async {
    await Clipboard.setData(ClipboardData(text: username));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(context.l10n.tOr('copied', 'Copied')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.role.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.tOr(
                          'roleUsersSubtitle',
                          'Users assigned to this role.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.tOr('refresh', 'Refresh'),
                  onPressed: () => context
                      .read<RbacBloc>()
                      .add(LoadRoleUsers(widget.role.id)),
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  tooltip: l10n.tOr('close', 'Close'),
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              focusNode: _searchFocus,
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.tOr('searchUsers', 'Search users'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: scheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<RbacBloc, RbacState>(
              buildWhen: (previous, current) =>
                  previous.roleUsers != current.roleUsers ||
                  previous.isLoadingRoleUsers != current.isLoadingRoleUsers ||
                  previous.roleUsersRoleId != current.roleUsersRoleId ||
                  previous.errorMessage != current.errorMessage,
              builder: (context, state) {
                final forThisRole = state.roleUsersRoleId == widget.role.id;
                final loading = state.isLoadingRoleUsers ||
                    (!forThisRole && state.roleUsers.isEmpty);

                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (forThisRole &&
                    state.errorMessage != null &&
                    state.roleUsers.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: RbacErrorView(
                      message: rbacErrorText(context, state.errorMessage!),
                      onRetry: () => context
                          .read<RbacBloc>()
                          .add(LoadRoleUsers(widget.role.id)),
                    ),
                  );
                }

                final filtered = _filteredUsers(
                  forThisRole ? state.roleUsers : const [],
                );
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: RbacEmptyView(
                      title: _query.trim().isEmpty
                          ? l10n.tOr(
                              'roleUsersEmpty',
                              'No users are assigned to this role.',
                            )
                          : l10n.tOr(
                              'noUsersMatchSearch',
                              'No users match your search.',
                            ),
                      icon: Icons.people_outline_rounded,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    return _RoleUserTile(
                      user: user,
                      onCopyUsername: () => _copyUsername(user.username),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleUserTile extends StatelessWidget {
  const _RoleUserTile({
    required this.user,
    required this.onCopyUsername,
  });

  final RoleUserEntity user;
  final VoidCallback onCopyUsername;

  String _initials() {
    final source = user.displayName.trim();
    if (source.isEmpty) return '?';
    final parts =
        source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final avatarUrl = user.avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      _initials(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (user.email != null && user.email!.trim().isNotEmpty)
                    Text(
                      user.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
            if (user.isBanned || user.isVerified)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Column(
                  children: [
                    if (user.isBanned)
                      RbacBadge(label: l10n.tOr('banned', 'Banned')),
                    if (user.isVerified)
                      RbacBadge(
                        label: l10n.tOr('verified', 'Verified'),
                        emphasized: true,
                      ),
                  ],
                ),
              ),
            IconButton(
              onPressed: onCopyUsername,
              tooltip: l10n.tOr('copyUsername', 'Copy username'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
