import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';

/// Inline search field for the categories toolbar (matches posts style).
class CategoriesFilterBar extends StatefulWidget {
  const CategoriesFilterBar({
    super.key,
    this.metrics,
    this.height,
  });

  final CategoriesLayoutMetrics? metrics;
  final double? height;

  @override
  State<CategoriesFilterBar> createState() => _CategoriesFilterBarState();
}

class _CategoriesFilterBarState extends State<CategoriesFilterBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _lastAppliedSearch = '';

  double get _controlHeight {
    if (widget.height != null) return widget.height!;
    final m = widget.metrics;
    if (m == null) return 36.0;
    return m.filterControlHeight;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSearch(
        context.read<CategoriesBloc>().activeSearchQuery,
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
    if (value.trim() == _lastAppliedSearch.trim()) return;
    _lastAppliedSearch = value;
    context.read<CategoriesBloc>().add(UpdateCategorySearchEvent(value));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _applySearch(value);
    });
  }

  void _syncSearch(String text, {bool force = false}) {
    if (!force && _searchFocusNode.hasFocus) return;
    if (_searchController.text == text) return;
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _lastAppliedSearch = text;
  }

  bool _isFetching(CategoriesState state) =>
      state is CategoriesLoaded && state.isFetching;

  InputDecoration _fieldDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = _controlHeight;
    final verticalPad = ((height - 20) / 2).clamp(5.0, 10.0);
    final borderColor = scheme.outline.withValues(alpha: 0.22);
    final radius = BorderRadius.circular(8);
    return InputDecoration(
      hintText: context.l10n.tOr(
        'searchCategories',
        'Search by name, slug, ID, or keywords…',
      ),
      hintStyle: TextStyle(
        fontSize: 12.5,
        height: 1.1,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        size: 17,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      prefixIconConstraints: BoxConstraints(
        minWidth: height,
        minHeight: height,
      ),
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.metrics?.isMobile == true ? 4 : 8,
        vertical: verticalPad,
      ),
      constraints: BoxConstraints(minHeight: height, maxHeight: height),
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

    return BlocListener<CategoriesBloc, CategoriesState>(
      listenWhen: (prev, next) {
        final bloc = context.read<CategoriesBloc>();
        final prevQ = prev is CategoriesLoaded
            ? prev.searchQuery
            : bloc.activeSearchQuery;
        final nextQ = next is CategoriesLoaded
            ? next.searchQuery
            : bloc.activeSearchQuery;
        return prevQ != nextQ;
      },
      listener: (context, state) {
        final query = state is CategoriesLoaded
            ? state.searchQuery
            : context.read<CategoriesBloc>().activeSearchQuery;
        _syncSearch(query, force: true);
      },
      child: BlocBuilder<CategoriesBloc, CategoriesState>(
        buildWhen: (prev, next) =>
            _isFetching(prev) != _isFetching(next) ||
            (prev is CategoriesLoaded &&
                next is CategoriesLoaded &&
                prev.searchQuery != next.searchQuery),
        builder: (context, state) {
          final isFetching = _isFetching(state);

          return SizedBox(
            height: height,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _applySearch,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 12.5, height: 1.1),
              decoration: _fieldDecoration(context).copyWith(
                suffixIconConstraints: BoxConstraints(
                  minWidth: height,
                  maxWidth: height,
                  minHeight: height,
                  maxHeight: height,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    return SizedBox(
                      width: height,
                      height: height,
                      child: Center(
                        child: isFetching
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applySearch('');
                                    },
                                    tooltip: l10n.t('clear'),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                      minWidth: height,
                                      minHeight: height,
                                    ),
                                  )
                                : null,
                      ),
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
