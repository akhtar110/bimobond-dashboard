import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/search_debounce.dart';
import '../../../../core/utils/location_data_cache.dart';
import '../../../../injection_container.dart' as di;
import '../../../create_post/presentation/utils/create_post_geolocation.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/repositories/users_repository.dart';
import '../../../create_post/domain/entities/create_post_location_entity.dart';
import '../../domain/services/posts_location_search_service.dart';
import 'posts_location_filter.dart';

/// Place search for the posts geographic location filter.
class PostsLocationSearchField extends StatefulWidget {
  const PostsLocationSearchField({
    super.key,
    this.selectedPlace,
    this.onPlaceSelected,
    this.onClear,
    this.onSelectionCleared,
    this.compact = false,
    this.dialogStyle = false,
  });

  final CreatePostLocationEntity? selectedPlace;
  final ValueChanged<CreatePostLocationEntity>? onPlaceSelected;
  final VoidCallback? onClear;
  final VoidCallback? onSelectionCleared;
  final bool compact;
  final bool dialogStyle;

  @override
  State<PostsLocationSearchField> createState() =>
      _PostsLocationSearchFieldState();
}

class _PostsLocationSearchFieldState extends State<PostsLocationSearchField> {
  final _searchService = postsLocationSearchService;
  final _searchGuard = SearchRequestGuard();
  final _debouncer = SearchDebouncer(delay: const Duration(milliseconds: 280));

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<CreatePostLocationEntity> _results = const [];
  bool _loading = false;
  bool _searched = false;
  int _highlightedIndex = -1;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(PostsLocationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlace != widget.selectedPlace) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final place = widget.selectedPlace;
    final label = _placeLabel(place);
    if (_controller.text != label) {
      _controller.text = label;
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() => _highlightedIndex = -1);
    }
  }

  String _placeLabel(CreatePostLocationEntity? place) {
    if (place == null) return '';
    final city = place.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    return place.name.trim();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = const [];
        _searched = trimmed.isNotEmpty;
        _highlightedIndex = -1;
      });
      return;
    }

    final token = _searchGuard.next();
    if (!mounted || !_searchGuard.isCurrent(token)) return;
    setState(() => _loading = true);

    final results = await _searchService.search(trimmed, limit: 10);
    if (!mounted || !_searchGuard.isCurrent(token)) return;

    setState(() {
      _loading = false;
      _results = results;
      _searched = true;
      _highlightedIndex = results.isEmpty ? -1 : 0;
    });
  }

  void _onQueryChanged(String value) {
    final trimmed = value.trim();

    if (widget.selectedPlace != null) {
      final selectedLabel = _placeLabel(widget.selectedPlace);
      if (trimmed != selectedLabel) {
        widget.onSelectionCleared?.call();
      }
    }

    if (trimmed.length < 2) {
      _debouncer.cancel();
      _searchGuard.next();
      setState(() {
        _loading = false;
        _results = const [];
        _searched = trimmed.isNotEmpty;
        _highlightedIndex = -1;
      });
      return;
    }

    final instant = _searchService.instantMatches(trimmed);
    if (instant.isNotEmpty) {
      setState(() {
        _results = instant;
        _searched = true;
        _highlightedIndex = 0;
        _loading = false;
      });
    }

    _debouncer.run(() {
      if (!mounted) return;
      unawaited(_search(trimmed));
    });
  }

  void _selectPlace(CreatePostLocationEntity place) {
    _controller.text = _placeLabel(place);
    _focusNode.unfocus();
    setState(() {
      _results = const [];
      _searched = false;
      _highlightedIndex = -1;
    });
    widget.onPlaceSelected?.call(place);
  }

  void _clear() {
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _results = const [];
      _searched = false;
      _highlightedIndex = -1;
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (widget.dialogStyle) {
      return _buildDialogStyleField(context, l10n, scheme, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInlineTextField(context, l10n, scheme, theme),
        ..._buildResultsSection(context, l10n, scheme, theme),
      ],
    );
  }

  Widget _buildInlineTextField(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: widget.compact ? 13.5 : 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: l10n.t('postFilterLocationSearch'),
        hintText: l10n.t('postFilterLocationSearchHint'),
        prefixIcon: Icon(
          Icons.place_outlined,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
        suffixIcon: _buildSuffixIcon(context, l10n, scheme),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        isDense: false,
      ),
      onChanged: _onQueryChanged,
      onSubmitted: _onSubmitted,
    );
  }

  Widget _buildDialogStyleField(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    final hasValue = widget.selectedPlace != null || _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.t('postFilterLocationSearch'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue
                    ? scheme.primary.withValues(alpha: 0.45)
                    : scheme.outlineVariant.withValues(alpha: 0.75),
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: l10n.t('postFilterLocationSearchHint'),
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
                suffixIcon: _buildSuffixIcon(context, l10n, scheme),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                isDense: false,
              ),
              onChanged: _onQueryChanged,
              onSubmitted: _onSubmitted,
            ),
          ),
        ),
        ..._buildResultsSection(context, l10n, scheme, theme),
      ],
    );
  }

  Widget _buildSuffixIcon(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            if (value.text.isNotEmpty)
              IconButton(
                tooltip: l10n.t('clear'),
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: _clear,
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: widget.selectedPlace != null
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
          ],
        );
      },
    );
  }

  void _onSubmitted(String value) {
    if (_highlightedIndex >= 0 && _highlightedIndex < _results.length) {
      _selectPlace(_results[_highlightedIndex]);
      return;
    }
    unawaited(_search(value));
  }

  List<Widget> _buildResultsSection(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    if (_results.isEmpty && !(_searched && _results.isEmpty)) {
      return const [];
    }

    return [
      const SizedBox(height: 6),
      Material(
        elevation: widget.dialogStyle ? 0 : 2,
        borderRadius: BorderRadius.circular(10),
        color: widget.dialogStyle
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.65)
            : scheme.surfaceContainerHighest,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: _searched && _results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    l10n.t('postFilterLocationNoResults'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final place = _results[index];
                    final highlighted = index == _highlightedIndex;
                    return ListTile(
                      dense: true,
                      selected: highlighted,
                      selectedTileColor:
                          scheme.primary.withValues(alpha: 0.08),
                      leading: Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: highlighted
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        _placeLabel(place),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              highlighted ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      subtitle: place.address != null &&
                              place.address!.trim().isNotEmpty
                          ? Text(
                              place.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            )
                          : null,
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
        ),
      ),
    ];
  }
}

/// Quick anchors for user GPS / filtered-user location in filter panels.
class PostsLocationAnchorButtons extends StatefulWidget {
  const PostsLocationAnchorButtons({
    super.key,
    this.filterUser,
    required this.onPlaceSelected,
  });

  final UserEntity? filterUser;
  final ValueChanged<CreatePostLocationEntity> onPlaceSelected;

  @override
  State<PostsLocationAnchorButtons> createState() =>
      _PostsLocationAnchorButtonsState();
}

class _PostsLocationAnchorButtonsState extends State<PostsLocationAnchorButtons> {
  bool _locating = false;
  final _searchService = postsLocationSearchService;

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final l10n = context.l10n;
      const geolocation = CreatePostGeolocation();
      final result = await geolocation.getCurrentPosition();
      if (!mounted) return;
      if (!result.hasRealPosition) {
        final message = postsLocationErrorMessage(l10n, result);
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
          );
        }
        return;
      }
      final resolved = await _searchService.reverseGeocode(
        latitude: result.point.latitude,
        longitude: result.point.longitude,
      );
      widget.onPlaceSelected(
        resolved ??
            CreatePostLocationEntity(
              name: l10n.t('postFilterMyLocationAnchor'),
              latitude: result.point.latitude,
              longitude: result.point.longitude,
            ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _useFilterUserLocation(UserEntity user) async {
    final l10n = context.l10n;
    final resolved = await _resolveFilterUser(user);
    if (!mounted) return;
    final coords = postsUserLocationCoordinates(resolved);
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('postFilterUserLocationUnavailable')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onPlaceSelected(
      CreatePostLocationEntity(
        name: postsUserLocationLabel(l10n, resolved),
        latitude: coords.latitude,
        longitude: coords.longitude,
        city: resolved.lastLocation?.city ?? resolved.city,
      ),
    );
  }

  Future<UserEntity> _resolveFilterUser(UserEntity user) async {
    if (postsUserLocationCoordinates(user) != null) return user;
    final cached = LocationDataCache.instance.getUser(user.id);
    if (cached != null) return cached;
    try {
      final detail = await di.sl<UsersRepository>().getUserById(user.id);
      LocationDataCache.instance.putUser(detail.user);
      return detail.user;
    } on Object {
      return user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      side: BorderSide(
        color: scheme.outlineVariant,
      ),
      foregroundColor: scheme.onSurfaceVariant,
      textStyle: const TextStyle(
        fontSize: 13.0,
        fontWeight: FontWeight.w600,
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _locating ? null : _useMyLocation,
          style: buttonStyle,
          icon: _locating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                )
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(l10n.t('postFilterUseMyLocation')),
        ),
        if (widget.filterUser != null)
          OutlinedButton.icon(
            onPressed:
                _locating ? null : () => _useFilterUserLocation(widget.filterUser!),
            style: buttonStyle,
            icon: const Icon(Icons.person_pin_circle_outlined, size: 18),
            label: Text(
              l10n.tArgs('postFilterUseUserLocation', {
                'user': widget.filterUser!.username,
              }),
            ),
          ),
      ],
    );
  }
}
