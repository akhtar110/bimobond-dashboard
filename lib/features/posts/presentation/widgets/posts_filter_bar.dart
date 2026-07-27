import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_responsive.dart';
import 'posts_filter_button.dart';
import 'posts_filter_popup.dart';

/// Gifts-style filter bar: search + Filters button on one responsive row.
/// Advanced filters open in a popup; filter state lives in [PostsBloc].
class PostsFilterBar extends StatefulWidget {
  const PostsFilterBar({
    super.key,
    required this.isDark,
    this.compact = false,
    this.metrics,
  });

  /// Retained for hot-reload compatibility; styling uses [ColorScheme].
  final bool isDark;
  final bool compact;
  final PostsLayoutMetrics? metrics;

  @override
  State<PostsFilterBar> createState() => _PostsFilterBarState();
}

class _PostsFilterBarState extends State<PostsFilterBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _lastAppliedSearch = '';

  double get _controlHeight {
    final m = widget.metrics;
    if (m == null) return widget.compact ? 36.0 : 40.0;
    return switch (m.deviceType) {
      PostsDeviceType.mobileSmall => 34.0,
      PostsDeviceType.mobileLarge => 36.0,
      PostsDeviceType.tablet => 38.0,
      PostsDeviceType.desktop => 40.0,
    };
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final trimmed = value.trim();
    if (trimmed == _lastAppliedSearch) return;
    _lastAppliedSearch = trimmed;
    context.read<PostsBloc>().add(SearchPostsEvent(trimmed));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _applySearch(value);
    });
  }

  void _syncSearchFromFilters(PostFilters filters, {bool force = false}) {
    if (!force && _searchFocusNode.hasFocus) return;
    final text = filters.search ?? '';
    if (_searchController.text == text) return;
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _lastAppliedSearch = text;
  }

  PostFilters _readFilters(PostsState state) {
    return switch (state) {
      PostsLoaded(:final filters) => filters,
      PostsEmpty(:final filters) => filters,
      PostsError() => context.read<PostsBloc>().activeFilters,
      _ => context.read<PostsBloc>().activeFilters,
    };
  }

  bool _isApplying(PostsState state) =>
      state is PostsLoaded && state.isApplyingFilters;

  InputDecoration _fieldDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verticalPad = ((_controlHeight - 20) / 2).clamp(6.0, 10.0);
    return InputDecoration(
      hintText: context.l10n.t('postFilterSearch'),
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.metrics?.isMobile == true ? 8 : 10,
        vertical: verticalPad,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: 0.18),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: scheme.outline.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final height = _controlHeight;
    final gap = widget.metrics?.filterGap ?? 8.0;

    return BlocListener<PostsBloc, PostsState>(
      listenWhen: (prev, next) {
        final prevF = _readFilters(prev);
        final nextF = _readFilters(next);
        return prevF.search != nextF.search;
      },
      listener: (context, state) {
        _syncSearchFromFilters(_readFilters(state), force: true);
      },
      child: BlocBuilder<PostsBloc, PostsState>(
        buildWhen: (prev, next) {
          final prevF = _readFilters(prev);
          final nextF = _readFilters(next);
          return prevF != nextF || _isApplying(prev) != _isApplying(next);
        },
        builder: (context, state) {
          final filters = _readFilters(state);
          _syncSearchFromFilters(filters);
          final isApplying = _isApplying(state);
          final activeCount = postsAppliedFilterCount(filters);

          return SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SizedBox(
                    height: height,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      onSubmitted: _applySearch,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: widget.compact ? 12.5 : 13),
                      decoration: _fieldDecoration(context).copyWith(
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isApplying)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    child: SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                if (value.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 15),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applySearch('');
                                    },
                                    tooltip: l10n.t('clear'),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: gap + 2),
                Builder(
                  builder: (buttonContext) {
                    return PostsFilterButton(
                      activeCount: activeCount,
                      height: height,
                      onPressed: () {
                        final box =
                            buttonContext.findRenderObject() as RenderBox?;
                        final origin =
                            box?.localToGlobal(Offset.zero) ?? Offset.zero;
                        final size = box?.size ?? Size.zero;
                        final anchor = Rect.fromLTWH(
                          origin.dx,
                          origin.dy,
                          size.width,
                          size.height,
                        );
                        showPostsFilterPopup(
                          context: buttonContext,
                          filters: filters,
                          anchorRect: anchor,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
