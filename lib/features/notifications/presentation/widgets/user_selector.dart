import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../features/users/domain/entities/user_entity.dart';
import '../bloc/notifications_bloc.dart';

/// Single user selector with autocomplete.
class UserSelector extends StatefulWidget {
  const UserSelector({
    super.key,
    required this.onUserSelected,
    this.selectedUser,
    this.label,
  });

  final ValueChanged<UserEntity?> onUserSelected;
  final UserEntity? selectedUser;
  final String? label;

  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedUser != null) {
      _controller.text =
          '@${widget.selectedUser!.username} – ${widget.selectedUser!.fullName ?? ''}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() => _showDropdown = true);
    context.read<NotificationsBloc>().add(
          NotificationUserSearchChanged(query),
        );
  }

  void _selectUser(UserEntity user) {
    _controller.text =
        '@${user.username}${user.fullName != null ? ' – ${user.fullName}' : ''}';
    setState(() => _showDropdown = false);
    _focusNode.unfocus();
    widget.onUserSelected(user);
    context.read<NotificationsBloc>().add(
          const NotificationUserSearchChanged(''),
        );
  }

  void _clearSelection() {
    _controller.clear();
    widget.onUserSelected(null);
    context.read<NotificationsBloc>().add(
          const NotificationUserSearchChanged(''),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      buildWhen: (a, b) =>
          a.userSearchResults != b.userSearchResults ||
          a.userSearchLoading != b.userSearchLoading,
      builder: (context, state) {
        final l10n = context.l10n;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: widget.label ?? l10n.t('notificationSelectUserLabel'),
                prefixIcon: widget.selectedUser != null
                    ? _avatarPrefix(widget.selectedUser!, scheme)
                    : const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.person_search_outlined),
                      ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.userSearchLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (widget.selectedUser != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSelection,
                        tooltip: l10n.t('notificationClearSelection'),
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                hintText: l10n.t('notificationSearchUsersHint'),
              ),
              onChanged: _onChanged,
              onTap: () => setState(() => _showDropdown = true),
              validator: (v) {
                if (widget.selectedUser == null) {
                  return l10n.t('notificationUserRequired');
                }
                return null;
              },
            ),
            if (_showDropdown &&
                state.userSearchResults.isNotEmpty &&
                widget.selectedUser == null) ...[
              const SizedBox(height: 4),
              _SearchDropdown(
                users: state.userSearchResults,
                onTap: _selectUser,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _avatarPrefix(UserEntity user, ColorScheme scheme) {
    final url = resolveMediaUrl(user.avatarUrl);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: scheme.primaryContainer,
        backgroundImage:
            url != null ? NetworkImage(url) : null,
        child: url == null
            ? Text(
                (user.username.isNotEmpty
                        ? user.username[0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(fontSize: 12),
              )
            : null,
      ),
    );
  }
}

class _SearchDropdown extends StatelessWidget {
  const _SearchDropdown({
    required this.users,
    required this.onTap,
  });

  final List<UserEntity> users;
  final ValueChanged<UserEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: scheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          shrinkWrap: true,
          itemCount: users.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, i) => _UserTile(
            user: users[i],
            onTap: () => onTap(users[i]),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});
  final UserEntity user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = resolveMediaUrl(user.avatarUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: url != null ? NetworkImage(url) : null,
              child: url == null
                  ? Text(
                      (user.username.isNotEmpty
                              ? user.username[0]
                              : '?')
                          .toUpperCase(),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.username}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (user.fullName != null)
                    Text(
                      user.fullName!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
