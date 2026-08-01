import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../../core/utils/search_debounce.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_users.dart';

/// Max suggestions shown in the autocomplete dropdown (5–8 range).
const int _kUserSearchMaxResults = 6;

/// Fixed row height keeps the dropdown compact and predictable.
const double _kUserSearchItemHeight = 44;

/// Searchable user picker with a compact autocomplete dropdown below the field.
class AdminUserSearchField extends StatefulWidget {
  const AdminUserSearchField({
    super.key,
    required this.onUserSelected,
    this.onUserConfirmed,
    this.selectedUser,
    this.label,
    this.hintText,
    this.getUsers,
    this.compact = false,
    this.compactFilterStyle = false,
    @Deprecated('Dropdown is always rendered below the input.')
    this.inlineDropdown = false,
    this.height,
    this.maxResults = _kUserSearchMaxResults,
  });

  final ValueChanged<UserEntity?> onUserSelected;

  /// Called after [onUserSelected] when the user confirms via Enter.
  final VoidCallback? onUserConfirmed;

  final UserEntity? selectedUser;
  final String? label;
  final String? hintText;
  final GetUsers? getUsers;
  final bool compact;
  final bool compactFilterStyle;

  /// Deprecated — kept for call-site compatibility.
  final bool inlineDropdown;

  final double? height;
  final int maxResults;

  @override
  State<AdminUserSearchField> createState() => _AdminUserSearchFieldState();
}

class _AdminUserSearchFieldState extends State<AdminUserSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  final _searchGuard = SearchRequestGuard();
  bool _showDropdown = false;
  bool _loading = false;
  bool _searched = false;
  bool _isReplacingUser = false;
  bool _dropdownPointerDown = false;
  int _highlightedIndex = 0;
  List<UserEntity> _results = [];

  GetUsers get _getUsers => widget.getUsers ?? sl<GetUsers>();

  int get _resultLimit => widget.maxResults.clamp(5, 8);

  bool get _shouldShowDropdown =>
      _showDropdown &&
      (widget.selectedUser == null || _isReplacingUser) &&
      (_loading || _searched || _controller.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = _onKeyEvent;
    _syncSelectedUserText();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AdminUserSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUser?.id == widget.selectedUser?.id) return;

    if (widget.selectedUser != null) {
      _isReplacingUser = false;
      _syncSelectedUserText(rebuild: true);
      return;
    }

    // Parent cleared selection while the user is typing a replacement — keep query.
    if (_isReplacingUser && _focusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _showDropdown = _controller.text.trim().isNotEmpty;
        });
      }
      return;
    }

    _isReplacingUser = false;
    _syncSelectedUserText(rebuild: true);
  }

  void _syncSelectedUserText({bool rebuild = false}) {
    final user = widget.selectedUser;
    if (user == null) {
      _controller.clear();
      void apply() {
        _showDropdown = false;
        _results = [];
        _loading = false;
        _searched = false;
      }

      if (rebuild && mounted) {
        setState(apply);
      } else {
        apply();
      }
      return;
    }

    _controller.text = _displayLabel(user);
  }

  String _displayLabel(UserEntity user) {
    if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
      return '@${user.username} · ${user.fullName!.trim()}';
    }
    return '@${user.username}';
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.trim().isNotEmpty) {
        setState(() => _showDropdown = true);
      }
      return;
    }

    if (!_showDropdown) return;
    if (_dropdownPointerDown) return;
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _focusNode.hasFocus || _dropdownPointerDown) return;
      setState(() => _showDropdown = false);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.onKeyEvent = null;
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (widget.selectedUser != null) {
      _isReplacingUser = true;
      widget.onUserSelected(null);
    }

    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _searchGuard.next();
      setState(() {
        _showDropdown = false;
        _loading = false;
        _searched = false;
        _results = [];
      });
      return;
    }

    setState(() => _showDropdown = true);

    _debounce = Timer(dashboardSearchDebounce, () async {
      final token = _searchGuard.next();
      if (!mounted) return;
      setState(() {
        _loading = true;
        _searched = false;
      });

      try {
        final page = await _getUsers(
          page: 1,
          limit: _resultLimit,
          search: trimmed,
        );
        if (!mounted || !_searchGuard.isCurrent(token)) return;
        setState(() {
          _results = page.users.take(_resultLimit).toList();
          _loading = false;
          _searched = true;
          _highlightedIndex = 0;
        });
      } catch (_) {
        if (!mounted || !_searchGuard.isCurrent(token)) return;
        setState(() {
          _results = [];
          _loading = false;
          _searched = true;
          _highlightedIndex = 0;
        });
      }
    });
  }

  void _selectUser(UserEntity user, {bool apply = false}) {
    _isReplacingUser = false;
    widget.onUserSelected(user);
    _controller.text = _displayLabel(user);
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
      _searched = false;
      _highlightedIndex = 0;
    });
    _focusNode.unfocus();
    if (apply) {
      widget.onUserConfirmed?.call();
    }
  }

  void _confirmHighlightedUser() {
    if (_loading || _results.isEmpty) return;
    final index = _highlightedIndex.clamp(0, _results.length - 1);
    _selectUser(_results[index], apply: true);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!_shouldShowDropdown || _results.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex =
            (_highlightedIndex + 1).clamp(0, _results.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex =
            (_highlightedIndex - 1).clamp(0, _results.length - 1);
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _setDropdownPointerDown(bool down) {
    _dropdownPointerDown = down;
  }

  void _clearSelection() {
    _isReplacingUser = false;
    _controller.clear();
    setState(() {
      _showDropdown = false;
      _results = [];
      _loading = false;
      _searched = false;
    });
    widget.onUserSelected(null);
  }

  double _resolveFieldHeight(BoxConstraints constraints) {
    if (widget.height != null) return widget.height!;
    if (constraints.hasBoundedHeight &&
        constraints.maxHeight.isFinite &&
        constraints.maxHeight < double.infinity) {
      return constraints.maxHeight;
    }
    return ToolbarFilterStyle.controlHeight;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = widget.label ?? l10n.tOr('selectWinner', 'Select winner');
    final hint =
        widget.hintText ??
        l10n.tOr('notificationSearchUsersHint', 'Search by username or name…');

    final field = LayoutBuilder(
      builder: (context, constraints) {
        final fieldHeight = widget.compact
            ? _resolveFieldHeight(constraints)
            : null;

        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          textAlign: TextAlign.start,
          textDirection: null,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: widget.compact ? 12.5 : 14),
          decoration: _buildDecoration(
            scheme: scheme,
            label: label,
            hint: hint,
            compact: widget.compact,
            fieldHeight: fieldHeight,
          ),
          onChanged: _onChanged,
          onTap: () => setState(() => _showDropdown = true),
          onSubmitted: (_) => _confirmHighlightedUser(),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.compact)
          LayoutBuilder(
            builder: (context, constraints) {
              final fieldHeight = _resolveFieldHeight(constraints);
              return SizedBox(height: fieldHeight, child: field);
            },
          )
        else
          field,
        if (_shouldShowDropdown)
          Listener(
            onPointerDown: (_) => _setDropdownPointerDown(true),
            onPointerUp: (_) => _setDropdownPointerDown(false),
            onPointerCancel: (_) => _setDropdownPointerDown(false),
            child: _UserAutocompleteDropdown(
              loading: _loading,
              results: _results,
              searched: _searched,
              maxResults: _resultLimit,
              highlightedIndex: _highlightedIndex,
              onSelected: (user) => _selectUser(user),
              onHighlight: (index) {
                if (_highlightedIndex == index) return;
                setState(() => _highlightedIndex = index);
              },
            ),
          ),
      ],
    );
  }

  InputDecoration _buildDecoration({
    required ColorScheme scheme,
    required String label,
    required String hint,
    required bool compact,
    double? fieldHeight,
  }) {
    final useToolbarStyle = widget.compactFilterStyle && compact;
    final h = fieldHeight ?? ToolbarFilterStyle.controlHeight;
    final iconBox = h.clamp(28.0, 40.0);

    final prefix = widget.selectedUser != null
        ? _avatarPrefix(
            widget.selectedUser!,
            scheme,
            compact: compact,
            boxSize: iconBox,
          )
        : SizedBox(
            width: iconBox,
            height: iconBox,
            child: Icon(
              Icons.person_search_outlined,
              size: compact ? 16 : 20,
              color: scheme.onSurfaceVariant,
            ),
          );

    final suffix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loading)
          Padding(
            padding: EdgeInsetsDirectional.only(end: compact ? 6 : 10),
            child: SizedBox(
              width: compact ? 12 : 14,
              height: compact ? 12 : 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ),
        if (widget.selectedUser != null)
          IconButton(
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(iconBox - 2, iconBox - 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            icon: Icon(Icons.close_rounded, size: compact ? 16 : 20),
            color: scheme.onSurfaceVariant,
            onPressed: _clearSelection,
            tooltip: context.l10n.t('clear'),
          ),
      ],
    );

    final iconConstraints = BoxConstraints(
      minWidth: iconBox,
      maxWidth: compact ? iconBox + 8 : 48,
      minHeight: h,
      maxHeight: h,
    );

    if (useToolbarStyle) {
      return ToolbarFilterStyle.inputDecoration(
        scheme,
        hintText: hint,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        prefixIcon: prefix,
        suffixIcon: suffix,
      ).copyWith(
        prefixIconConstraints: iconConstraints,
        suffixIconConstraints: BoxConstraints(minHeight: h, maxHeight: h),
      );
    }

    return InputDecoration(
      labelText: compact ? null : label,
      hintText: hint,
      hintStyle: compact
          ? TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)
          : null,
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: compact,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(
        alpha: compact ? 0.35 : 0.4,
      ),
      contentPadding: compact
          ? const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 0)
          : null,
      prefixIconConstraints: compact ? iconConstraints : null,
      suffixIconConstraints: compact
          ? BoxConstraints(minHeight: h, maxHeight: h)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
    );
  }

  Widget _avatarPrefix(
    UserEntity user,
    ColorScheme scheme, {
    bool compact = false,
    double boxSize = 40,
  }) {
    final url = resolveMediaUrl(user.avatarUrl);
    final radius = compact ? 11.0 : 14.0;
    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Center(
        child: CircleAvatar(
          radius: radius,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null
              ? Text(
                  (user.username.isNotEmpty ? user.username[0] : '?')
                      .toUpperCase(),
                  style: TextStyle(fontSize: compact ? 10 : 12),
                )
              : null,
        ),
      ),
    );
  }
}

/// Compact suggestion list anchored directly under the search field.
class _UserAutocompleteDropdown extends StatelessWidget {
  const _UserAutocompleteDropdown({
    required this.loading,
    required this.results,
    required this.searched,
    required this.maxResults,
    required this.highlightedIndex,
    required this.onSelected,
    required this.onHighlight,
  });

  final bool loading;
  final List<UserEntity> results;
  final bool searched;
  final int maxResults;
  final int highlightedIndex;
  final ValueChanged<UserEntity> onSelected;
  final ValueChanged<int> onHighlight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final maxHeight = maxResults * _kUserSearchItemHeight + 8;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 4),
      child: Material(
        elevation: 6,
        shadowColor: scheme.shadow.withValues(alpha: 0.14),
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: loading
                ? const SizedBox(
                    height: _kUserSearchItemHeight,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : results.isEmpty
                ? SizedBox(
                    height: _kUserSearchItemHeight,
                    child: Center(
                      child: Text(
                        l10n.tOr('noUsersFound', 'No users found'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    primary: false,
                    itemCount: results.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, index) => _UserSearchResultTile(
                      user: results[index],
                      highlighted: index == highlightedIndex,
                      onTap: () => onSelected(results[index]),
                      onHover: () => onHighlight(index),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _UserSearchResultTile extends StatefulWidget {
  const _UserSearchResultTile({
    required this.user,
    required this.onTap,
    required this.onHover,
    this.highlighted = false,
  });

  final UserEntity user;
  final VoidCallback onTap;
  final VoidCallback onHover;
  final bool highlighted;

  @override
  State<_UserSearchResultTile> createState() => _UserSearchResultTileState();
}

class _UserSearchResultTileState extends State<_UserSearchResultTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final scheme = Theme.of(context).colorScheme;
    final url = resolveMediaUrl(user.avatarUrl);
    final subtitle = _subtitleFor(user);

    return MouseRegion(
      onEnter: (_) {
        widget.onHover();
        setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: widget.highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : _hovered
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.65)
            : Colors.transparent,
        child: InkWell(
          onTapDown: (_) => widget.onTap(),
          child: SizedBox(
            height: _kUserSearchItemHeight,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: url != null ? NetworkImage(url) : null,
                    child: url == null
                        ? Text(
                            (user.username.isNotEmpty ? user.username[0] : '?')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: _LtrText(
                                '@${user.username}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.1,
                                    ),
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                size: 13,
                                color: scheme.primary,
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11.5,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.1,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _subtitleFor(UserEntity user) {
    final name = user.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return null;
  }
}

/// Keeps @handles readable in both Arabic (RTL) and English (LTR) layouts.
class _LtrText extends StatelessWidget {
  const _LtrText(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.start,
        style: style,
      ),
    );
  }
}
