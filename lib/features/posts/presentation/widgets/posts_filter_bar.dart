import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_responsive.dart';

/// Inline search field for the posts toolbar.
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
    if (m == null) return widget.compact ? 34.0 : 36.0;
    return switch (m.deviceType) {
      PostsDeviceType.mobileSmall => 34.0,
      PostsDeviceType.mobileLarge => 34.0,
      PostsDeviceType.tablet => 36.0,
      PostsDeviceType.desktop => 36.0,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSearchFromFilters(
        context.read<PostsBloc>().activeFilters,
        force: true,
      );
    });
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
    final verticalPad = ((_controlHeight - 20) / 2).clamp(5.0, 8.0);
    final borderColor = scheme.outline.withValues(alpha: 0.2);
    final radius = BorderRadius.circular(8);
    return InputDecoration(
      hintText: context.l10n.t('postFilterSearch'),
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        size: 17,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.metrics?.isMobile == true ? 4 : 8,
        vertical: verticalPad,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final height = _controlHeight;

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
          final isApplying = _isApplying(state);

          return SizedBox(
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
                    if (!isApplying && value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isApplying)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 2),
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
                            icon: const Icon(Icons.close, size: 14),
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
          );
        },
      ),
    );
  }
}
