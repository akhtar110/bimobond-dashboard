import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_users.dart';

/// Searchable user picker for admin flows (auctions, notifications, etc.).
class AdminUserSearchField extends StatefulWidget {
  const AdminUserSearchField({
    super.key,
    required this.onUserSelected,
    this.selectedUser,
    this.label,
    this.hintText,
    this.getUsers,
  });

  final ValueChanged<UserEntity?> onUserSelected;
  final UserEntity? selectedUser;
  final String? label;
  final String? hintText;
  final GetUsers? getUsers;

  @override
  State<AdminUserSearchField> createState() => _AdminUserSearchFieldState();
}

class _AdminUserSearchFieldState extends State<AdminUserSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  bool _showDropdown = false;
  bool _loading = false;
  List<UserEntity> _results = [];

  GetUsers get _getUsers => widget.getUsers ?? sl<GetUsers>();

  @override
  void initState() {
    super.initState();
    _syncSelectedUserText();
  }

  @override
  void didUpdateWidget(covariant AdminUserSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUser?.id != widget.selectedUser?.id) {
      _syncSelectedUserText();
    }
  }

  void _syncSelectedUserText() {
    final user = widget.selectedUser;
    if (user == null) return;
    _controller.text =
        '@${user.username}${user.fullName != null ? ' – ${user.fullName}' : ''}';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (widget.selectedUser != null) {
      widget.onUserSelected(null);
    }

    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _showDropdown = false;
        _loading = false;
        _results = [];
      });
      return;
    }

    setState(() {
      _showDropdown = true;
      _loading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final page = await _getUsers(page: 1, limit: 10, search: trimmed);
        if (!mounted) return;
        setState(() {
          _results = page.users;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    });
  }

  void _selectUser(UserEntity user) {
    _controller.text =
        '@${user.username}${user.fullName != null ? ' – ${user.fullName}' : ''}';
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
    });
    _focusNode.unfocus();
    widget.onUserSelected(user);
  }

  void _clearSelection() {
    _controller.clear();
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
    });
    widget.onUserSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = widget.label ?? l10n.tOr('selectWinner', 'Select winner');
    final hint = widget.hintText ??
        l10n.tOr(
          'notificationSearchUsersHint',
          'Search by username or name…',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: widget.selectedUser != null
                ? _avatarPrefix(widget.selectedUser!, scheme)
                : const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.person_search_outlined),
                  ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (widget.selectedUser != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                    tooltip: l10n.t('cancel'),
                  ),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            hintText: hint,
          ),
          onChanged: _onChanged,
          onTap: () => setState(() => _showDropdown = true),
        ),
        if (_showDropdown &&
            _results.isNotEmpty &&
            widget.selectedUser == null) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: scheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, i) => _UserSearchTile(
                  user: _results[i],
                  onTap: () => _selectUser(_results[i]),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _avatarPrefix(UserEntity user, ColorScheme scheme) {
    final url = resolveMediaUrl(user.avatarUrl);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null
            ? Text(
                (user.username.isNotEmpty ? user.username[0] : '?')
                    .toUpperCase(),
                style: const TextStyle(fontSize: 12),
              )
            : null,
      ),
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  const _UserSearchTile({required this.user, required this.onTap});

  final UserEntity user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = resolveMediaUrl(user.avatarUrl);

    return InkWell(
      onTap: onTap,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
