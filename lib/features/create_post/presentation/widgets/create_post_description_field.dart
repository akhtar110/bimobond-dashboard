import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_users.dart';

/// Matches an in-progress @mention token (ASCII + Arabic/Hebrew per API rules).
final RegExp _mentionTokenPattern = RegExp(
  r'@([\w\u0600-\u06FF\u0590-\u05FF]*)$',
);

/// Description field with @mention autocomplete (debounced via [GetUsers]).
class CreatePostDescriptionField extends StatefulWidget {
  const CreatePostDescriptionField({
    super.key,
    required this.value,
    required this.onChanged,
    this.getUsers,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final GetUsers? getUsers;

  @override
  State<CreatePostDescriptionField> createState() =>
      _CreatePostDescriptionFieldState();
}

class _CreatePostDescriptionFieldState
    extends State<CreatePostDescriptionField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  Timer? _debounce;
  Timer? _hideDropdownTimer;
  bool _showDropdown = false;
  bool _loading = false;
  List<UserEntity> _results = [];
  String _mentionQuery = '';
  int? _mentionStart;
  int? _mentionEnd;

  GetUsers get _getUsers => widget.getUsers ?? sl<GetUsers>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CreatePostDescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != (widget.value ?? '')) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hideDropdownTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    _hideDropdownTimer?.cancel();
    if (!_focusNode.hasFocus) {
      // Delay hiding so ListTile taps register before the dropdown is removed.
      _hideDropdownTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted || _focusNode.hasFocus) return;
        setState(() {
          _showDropdown = false;
          _results = [];
        });
      });
    }
  }

  int _effectiveCursor(String value) {
    final offset = _controller.selection.baseOffset;
    if (offset >= 0 && offset <= value.length) return offset;
    return value.length;
  }

  void _onChanged(String value) {
    widget.onChanged(value.trim().isEmpty ? null : value);
    _detectMention(value);
  }

  void _detectMention(String value) {
    _debounce?.cancel();
    final cursor = _effectiveCursor(value);

    final before = value.substring(0, cursor);
    final match = _mentionTokenPattern.firstMatch(before);
    if (match == null) {
      setState(() {
        _showDropdown = false;
        _results = [];
        _mentionQuery = '';
        _mentionStart = null;
        _mentionEnd = null;
      });
      return;
    }

    _mentionStart = match.start;
    _mentionEnd = cursor;
    _mentionQuery = match.group(1) ?? '';
    setState(() {
      _showDropdown = true;
      _loading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final page = await _getUsers(
          page: 1,
          limit: 10,
          search: _mentionQuery.isEmpty ? null : _mentionQuery,
        );
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

  void _insertMention(UserEntity user) {
    _hideDropdownTimer?.cancel();
    final start = _mentionStart;
    final end = _mentionEnd ?? _effectiveCursor(_controller.text);
    if (start == null || end < start) return;

    final value = _controller.text;
    final prefix = value.substring(0, start);
    final suffix = value.substring(end);
    final mention = '@${user.username} ';
    final next = '$prefix$mention$suffix';
    final newCursor = prefix.length + mention.length;

    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    widget.onChanged(next.trim().isEmpty ? null : next);
    setState(() {
      _showDropdown = false;
      _results = [];
      _mentionStart = null;
      _mentionEnd = null;
      _mentionQuery = '';
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.t('description'),
            hintText: l10n.t('postDescriptionHint'),
            alignLabelWithHint: true,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: _onChanged,
        ),
        if (_showDropdown && _results.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: scheme.surface,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, i) {
                  final user = _results[i];
                  final url = resolveMediaUrl(user.avatarUrl);
                  return InkWell(
                    onTapDown: (_) => _insertMention(user),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundImage: url != null ? NetworkImage(url) : null,
                        child: url == null
                            ? Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        '@${user.username}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: user.fullName != null
                          ? Text(
                              user.fullName!,
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
