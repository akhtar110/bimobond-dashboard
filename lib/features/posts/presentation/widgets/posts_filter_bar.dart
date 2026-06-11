import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';

/// Advanced filters for the posts feed (search + dropdowns).
class PostsFilterBar extends StatefulWidget {
  const PostsFilterBar({
    super.key,
    required this.isDark,
    this.compact = false,
  });

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
  final bool isDark;
  final bool compact;

  @override
  State<PostsFilterBar> createState() => _PostsFilterBarState();
}

class _PostsFilterBarState extends State<PostsFilterBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _lastAppliedSearch = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Dispatches [UpdatePostFiltersEvent] for dropdown-driven filter changes.
  /// Always reads [PostsBloc.activeFilters] as the base so the current
  /// category (and any other filter) is preserved.
  void _apply(PostFilters filters) {
    context.read<PostsBloc>().add(UpdatePostFiltersEvent(filters));
  }

  /// Dispatches the dedicated [SearchPostsEvent].
  /// The BLoC handler merges the search query into the current filters so
  /// the active category and other filters are never lost.
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

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: widget.compact ? 10 : 12,
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
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<PostsBloc, PostsState>(
      listenWhen: (prev, next) {
        final prevF = _filtersFromState(prev);
        final nextF = _filtersFromState(next);
        return prevF.search != nextF.search;
      },
      listener: (context, state) {
        _syncSearchFromFilters(_filtersFromState(state), force: true);
      },
      child: BlocBuilder<PostsBloc, PostsState>(
        buildWhen: (prev, next) {
          final prevF = _filtersFromState(prev);
          final nextF = _filtersFromState(next);
          return prevF != nextF ||
              _isApplyingFilters(prev) != _isApplyingFilters(next);
        },
        builder: (context, state) {
          final filters = _filtersFromState(state);
          final isApplying = _isApplyingFilters(state);

          final content = _FilterContent(
            searchField: _searchField(l10n, theme, isApplying),
            dropdowns: [
              _postTypeDropdown(l10n, filters, isApplying),
              _typeDropdown(l10n, filters, isApplying),
              _sortDropdown(l10n, filters, isApplying),
            ],
            activeFilters: _activeFilters(l10n, theme, filters, isApplying),
            compact: widget.compact,
          );

          if (widget.compact) return content;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: content,
          );
        },
      ),
    );
  }

  Widget _searchField(
    AppLocalizations l10n,
    ThemeData theme,
    bool isApplying,
  ) {
    final scheme = theme.colorScheme;
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: _onSearchChanged,
      onSubmitted: _applySearch,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: widget.compact ? 13 : 14),
      decoration: _fieldDecoration(
        context,
        hint: l10n.t('postFilterSearch'),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: widget.compact ? 18 : 20,
          color: scheme.onSurfaceVariant,
        ),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isApplying)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
              ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _searchController.clear();
                  _applySearch('');
                },
                tooltip: l10n.t('clear'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _activeFilters(
    AppLocalizations l10n,
    ThemeData theme,
    PostFilters filters,
    bool isApplying,
  ) {
    if (!filters.hasAdvancedFilters) return const [];

    return [
      const SizedBox(height: 8),
      Row(
        children: [
          Text(
            context.tr('activeFiltersCount', {
              'count': '${filters.advancedActiveCount}',
            }),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: isApplying
                ? null
                : () {
                    _searchController.clear();
                    _lastAppliedSearch = '';
                    context.read<PostsBloc>().add(ClearPostFiltersEvent());
                  },
            child: Text(
              l10n.t('clearAllFilters'),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      _ActiveFilterChips(
        filters: filters,
        onClearSearch: () {
          _searchController.clear();
          _lastAppliedSearch = '';
          context.read<PostsBloc>().add(SearchPostsEvent(''));
        },
      ),
    ];
  }

  bool _isApplyingFilters(PostsState state) =>
      state is PostsLoaded && state.isApplyingFilters;

  PostFilters _filtersFromState(PostsState state) {
    return switch (state) {
      PostsLoaded(:final filters) => filters,
      PostsEmpty(:final filters) => filters,
      PostsError() => context.read<PostsBloc>().activeFilters,
      _ => context.read<PostsBloc>().activeFilters,
    };
  }

  Widget _postTypeDropdown(
    AppLocalizations l10n,
    PostFilters filters,
    bool loading,
  ) {
    final selected = filters.postTypeFilter;
    return DropdownButtonFormField<PostTypeFilter>(
      key: ValueKey('postType_$selected'),
      initialValue: selected,
      isExpanded: true,
      decoration: _fieldDecoration(context, hint: l10n.t('postFilterPostType')),
      items: [
        DropdownMenuItem(
          value: PostTypeFilter.all,
          child: Text(l10n.t('postFilterAuctionAll')),
        ),
        DropdownMenuItem(
          value: PostTypeFilter.auction,
          child: Text(l10n.t('postFilterAuctionOnly')),
        ),
        DropdownMenuItem(
          value: PostTypeFilter.stories,
          child: Text(context.trOr('postFilterStoriesOnly', 'Stories Only')),
        ),
        DropdownMenuItem(
          value: PostTypeFilter.ads,
          child: Text(context.trOr('postFilterAdsOnly', 'Ads only')),
        ),
      ],
      onChanged: loading
          ? null
          : (v) {
              if (v == null) return;
              final bloc = context.read<PostsBloc>();
              switch (v) {
                case PostTypeFilter.all:
                  bloc.add(FilterPostsByTypeEvent());
                case PostTypeFilter.auction:
                  bloc.add(FilterPostsByTypeEvent(isAuctionable: true));
                case PostTypeFilter.stories:
                  bloc.add(FilterPostsByTypeEvent(isStory: true));
                case PostTypeFilter.ads:
                  bloc.add(FilterPostsByTypeEvent(isAd: true));
              }
            },
    );
  }

  Widget _typeDropdown(
    AppLocalizations l10n,
    PostFilters filters,
    bool loading,
  ) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('type_${filters.type}'),
      initialValue: filters.type,
      isExpanded: true,
      decoration: _fieldDecoration(context, hint: l10n.t('postFilterType')),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.t('postFilterTypeAll'))),
        DropdownMenuItem(
          value: 'VIDEO',
          child: Text(l10n.t('postFilterTypeVideo')),
        ),
        DropdownMenuItem(
          value: 'IMAGE',
          child: Text(l10n.t('postFilterTypeImage')),
        ),
        DropdownMenuItem(
          value: 'CAROUSEL',
          child: Text(l10n.t('postFilterTypeCarousel')),
        ),
      ],
      onChanged: loading
          ? null
          : (v) {
              final bloc = context.read<PostsBloc>();
              _apply(
                bloc.activeFilters.copyWith(type: v, clearType: v == null),
              );
            },
    );
  }

  Widget _sortDropdown(
    AppLocalizations l10n,
    PostFilters filters,
    bool loading,
  ) {
    final sortValue = filters.sort ?? PostFilters.defaultSort;
    return DropdownButtonFormField<String>(
      key: ValueKey('sort_$sortValue'),
      initialValue: sortValue,
      isExpanded: true,
      decoration: _fieldDecoration(context, hint: l10n.t('postFilterSort')),
      items: [
        DropdownMenuItem(
          value: 'LATEST',
          child: Text(l10n.t('postFilterSortLatest')),
        ),
        DropdownMenuItem(
          value: 'POPULAR',
          child: Text(l10n.t('postFilterSortPopular')),
        ),
      ],
      onChanged: loading
          ? null
          : (v) {
              if (v == null) return;
              _apply(context.read<PostsBloc>().activeFilters.copyWith(sort: v));
            },
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.filters,
    required this.onClearSearch,
  });

  final PostFilters filters;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[];

    void addChip(String label, VoidCallback onRemove) {
      chips.add(
        InputChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          onDeleted: onRemove,
          deleteIcon: const Icon(Icons.close, size: 16),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    final search = filters.search?.trim();
    if (search != null && search.isNotEmpty) {
      addChip(
        context.tr('filterChipSearch', {'value': search}),
        onClearSearch,
      );
    }

    if (filters.type != null) {
      final label = switch (filters.type) {
        'VIDEO' => l10n.t('postFilterTypeVideo'),
        'IMAGE' => l10n.t('postFilterTypeImage'),
        'CAROUSEL' => l10n.t('postFilterTypeCarousel'),
        _ => filters.type!,
      };
      addChip(
        label,
        () => _remove(context, (f) => f.copyWith(clearType: true)),
      );
    }

    if (filters.sort != null && filters.sort != PostFilters.defaultSort) {
      final label = filters.sort == 'POPULAR'
          ? l10n.t('postFilterSortPopular')
          : l10n.t('postFilterSortLatest');
      addChip(
        label,
        () => _remove(context, (f) => f.copyWith(clearSort: true)),
      );
    }

    if (filters.isAuctionable == true) {
      addChip(
        l10n.t('postFilterAuctionOnly'),
        () => context.read<PostsBloc>().add(FilterPostsByTypeEvent()),
      );
    }

    if (filters.isStory == true) {
      addChip(
        context.trOr('postFilterStoriesOnly', 'Stories Only'),
        () => context.read<PostsBloc>().add(FilterPostsByTypeEvent()),
      );
    }

    if (filters.isAd == true) {
      addChip(
        context.trOr('postFilterAdsOnly', 'Ads only'),
        () => context.read<PostsBloc>().add(FilterPostsByTypeEvent()),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  void _remove(BuildContext context, PostFilters Function(PostFilters) update) {
    final bloc = context.read<PostsBloc>();
    context.read<PostsBloc>().add(UpdatePostFiltersEvent(update(bloc.activeFilters)));
  }
}

class _FilterContent extends StatelessWidget {
  const _FilterContent({
    required this.searchField,
    required this.dropdowns,
    required this.activeFilters,
    required this.compact,
  });

  final Widget searchField;
  final List<Widget> dropdowns;
  final List<Widget> activeFilters;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < (compact ? 560 : 640);

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              searchField,
              const SizedBox(height: 8),
              for (var i = 0; i < dropdowns.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                dropdowns[i],
              ],
              ...activeFilters,
            ],
          );
        }

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(width: 220, child: searchField),
                  SizedBox(width: 158, child: dropdowns[0]),
                  SizedBox(width: 120, child: dropdowns[1]),
                  SizedBox(width: 120, child: dropdowns[2]),
                ],
              ),
              ...activeFilters,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            searchField,
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: dropdowns[0]),
                const SizedBox(width: 8),
                Expanded(child: dropdowns[1]),
                const SizedBox(width: 8),
                Expanded(child: dropdowns[2]),
              ],
            ),
            ...activeFilters,
          ],
        );
      },
    );
  }
}
