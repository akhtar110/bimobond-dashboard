import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../features/users/domain/entities/user_entity.dart';
import '../bloc/notifications_bloc.dart';

/// Multi-user selector that shows chips for selected users.
class BulkUserSelector extends StatefulWidget {
  const BulkUserSelector({
    super.key,
    required this.selectedUsers,
    required this.onChanged,
  });

  final List<UserEntity> selectedUsers;
  final ValueChanged<List<UserEntity>> onChanged;

  @override
  State<BulkUserSelector> createState() => _BulkUserSelectorState();
}

class _BulkUserSelectorState extends State<BulkUserSelector> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _showDropdown = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addUser(UserEntity user) {
    if (widget.selectedUsers.any((u) => u.id == user.id)) return;
    final updated = [...widget.selectedUsers, user];
    widget.onChanged(updated);
    _controller.clear();
    setState(() => _showDropdown = false);
    context.read<NotificationsBloc>().add(
          const NotificationUserSearchChanged(''),
        );
  }

  void _removeUser(UserEntity user) {
    widget.onChanged(
      widget.selectedUsers.where((u) => u.id != user.id).toList(),
    );
  }

  void _onSearchChanged(String query) {
    setState(() => _showDropdown = true);
    context.read<NotificationsBloc>().add(
          NotificationUserSearchChanged(query),
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
            // Selected user chips
            if (widget.selectedUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.selectedUsers
                      .map(
                        (user) => _UserChip(
                          user: user,
                          onRemove: () => _removeUser(user),
                        ),
                      )
                      .toList(),
                ),
              ),

            // Search field
            TextFormField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                labelText: widget.selectedUsers.isEmpty
                    ? l10n.t('notificationBulkAddUsers')
                    : l10n.t('notificationBulkAddMore'),
                prefixIcon: state.userSearchLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.group_add_outlined),
                suffixText: widget.selectedUsers.isNotEmpty
                    ? l10n.tArgs(
                        'notificationUsersSelected',
                        {'count': '${widget.selectedUsers.length}'},
                      )
                    : null,
                suffixStyle: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                hintText: l10n.t('notificationBulkSearchHint'),
              ),
              onChanged: _onSearchChanged,
              onTap: () => setState(() => _showDropdown = true),
              validator: (_) {
                if (widget.selectedUsers.isEmpty) {
                  return l10n.t('notificationSelectAtLeastOne');
                }
                return null;
              },
            ),

            // Dropdown results
            if (_showDropdown && state.userSearchResults.isNotEmpty) ...[
              const SizedBox(height: 4),
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(10),
                color: scheme.surface,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: state.userSearchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, i) {
                      final user = state.userSearchResults[i];
                      final alreadyAdded =
                          widget.selectedUsers.any((u) => u.id == user.id);
                      return _BulkUserTile(
                        user: user,
                        alreadyAdded: alreadyAdded,
                        onTap: alreadyAdded ? null : () => _addUser(user),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.user, required this.onRemove});
  final UserEntity user;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = resolveMediaUrl(user.avatarUrl);

    return Chip(
      avatar: CircleAvatar(
        radius: 10,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null
            ? Text(
                (user.username.isNotEmpty ? user.username[0] : '?')
                    .toUpperCase(),
                style: const TextStyle(fontSize: 9),
              )
            : null,
      ),
      label: Text('@${user.username}'),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
      labelStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontSize: 13,
      ),
    );
  }
}

class _BulkUserTile extends StatelessWidget {
  const _BulkUserTile({
    required this.user,
    required this.alreadyAdded,
    required this.onTap,
  });
  final UserEntity user;
  final bool alreadyAdded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = resolveMediaUrl(user.avatarUrl);

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: alreadyAdded ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: url != null ? NetworkImage(url) : null,
                child: url == null
                    ? Text(
                        (user.username.isNotEmpty ? user.username[0] : '?')
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              if (alreadyAdded)
                Icon(Icons.check_circle_rounded,
                    size: 18, color: scheme.primary)
              else
                Icon(Icons.add_circle_outline_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
