import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
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
    this.compact = false,
    this.compactFilterStyle = false,
    this.height,
  });

  final ValueChanged<UserEntity?> onUserSelected;
  final UserEntity? selectedUser;
  final String? label;
  final String? hintText;
  final GetUsers? getUsers;
  final bool compact;
  final bool compactFilterStyle;

  /// When set (or when the parent constrains height), the compact field fills
  /// that height instead of a fixed 40px — avoids toolbar overflow.
  final double? height;

  @override
  State<AdminUserSearchField> createState() => _AdminUserSearchFieldState();
}

class _AdminUserSearchFieldState extends State<AdminUserSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _fieldKey = GlobalKey();
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  Timer? _debounce;
  bool _showDropdown = false;
  bool _loading = false;
  List<UserEntity> _results = [];

  GetUsers get _getUsers => widget.getUsers ?? sl<GetUsers>();

  bool get _shouldShowOverlay =>
      widget.compact &&
      _showDropdown &&
      _results.isNotEmpty &&
      widget.selectedUser == null;

  @override
  void initState() {
    super.initState();
    _syncSelectedUserText();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AdminUserSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUser?.id != widget.selectedUser?.id) {
      _syncSelectedUserText(rebuild: true);
    }
  }

  void _syncSelectedUserText({bool rebuild = false}) {
    final user = widget.selectedUser;
    if (user == null) {
      _controller.clear();
      if (rebuild && mounted) {
        setState(() {
          _showDropdown = false;
          _results = [];
          _loading = false;
        });
        _syncOverlay();
      } else {
        _showDropdown = false;
        _results = [];
        _loading = false;
        _syncOverlay();
      }
      return;
    }
    _controller.text =
        '@${user.username}${user.fullName != null ? ' – ${user.fullName}' : ''}';
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _showDropdown) {
      // Allow list-item taps in the overlay to register first.
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || _focusNode.hasFocus) return;
        setState(() => _showDropdown = false);
        _syncOverlay();
      });
    }
  }

  void _syncOverlay() {
    if (!widget.compact) return;
    if (_shouldShowOverlay) {
      if (!_overlayController.isShowing) _overlayController.show();
    } else if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
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
      _syncOverlay();
      return;
    }

    setState(() {
      _showDropdown = true;
      _loading = true;
    });
    _syncOverlay();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final page = await _getUsers(page: 1, limit: 10, search: trimmed);
        if (!mounted) return;
        setState(() {
          _results = page.users;
          _loading = false;
        });
        _syncOverlay();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _loading = false;
        });
        _syncOverlay();
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
    _syncOverlay();
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
    _syncOverlay();
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
    final hint = widget.hintText ??
        l10n.tOr(
          'notificationSearchUsersHint',
          'Search by username or name…',
        );

    if (widget.compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fieldHeight = _resolveFieldHeight(constraints);
          return OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (context) =>
                _buildOverlayDropdown(context, scheme),
            child: CompositedTransformTarget(
              link: _layerLink,
              child: SizedBox(
                key: _fieldKey,
                height: fieldHeight,
                width: double.infinity,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: _buildDecoration(
                    scheme: scheme,
                    label: label,
                    hint: hint,
                    compact: true,
                    fieldHeight: fieldHeight,
                  ),
                  onChanged: _onChanged,
                  onTap: () {
                    setState(() => _showDropdown = true);
                    _syncOverlay();
                  },
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: _buildDecoration(
            scheme: scheme,
            label: label,
            hint: hint,
            compact: false,
          ),
          onChanged: _onChanged,
          onTap: () => setState(() => _showDropdown = true),
        ),
        _buildInlineDropdown(context, scheme),
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
              size: compact ? 16 : 24,
              color: scheme.onSurfaceVariant,
            ),
          );

    final suffix = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loading)
          Padding(
            padding: EdgeInsets.only(right: compact ? 6 : 12),
            child: SizedBox(
              width: compact ? 12 : 16,
              height: compact ? 12 : 16,
              child: const CircularProgressIndicator(strokeWidth: 2),
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
            icon: Icon(Icons.close, size: compact ? 16 : 24),
            color: scheme.onSurfaceVariant,
            onPressed: _clearSelection,
            tooltip: context.l10n.t('cancel'),
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
        suffixIconConstraints: BoxConstraints(
          minHeight: h,
          maxHeight: h,
        ),
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
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
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

  Widget _buildOverlayDropdown(
    BuildContext context,
    ColorScheme scheme,
  ) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 280.0;

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        color: scheme.surface,
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, _) => Divider(
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
      ),
    );
  }

  Widget _buildInlineDropdown(BuildContext context, ColorScheme scheme) {
    if (!_showDropdown ||
        _results.isEmpty ||
        widget.selectedUser != null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              separatorBuilder: (_, _) => Divider(
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
