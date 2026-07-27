import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/utils/posts_responsive.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_admin_l10n.dart';

/// Dense stories filters — prefers a single horizontal row to leave vertical
/// room for the stories catalog. Filter state lives in [StoriesBloc].
class StoryFiltersBar extends StatefulWidget {
  const StoryFiltersBar({
    super.key,
    this.compact = false,
    this.metrics,
  });

  final bool compact;
  final PostsLayoutMetrics? metrics;

  @override
  State<StoryFiltersBar> createState() => _StoryFiltersBarState();
}

class _StoryFiltersBarState extends State<StoryFiltersBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  String _lastAppliedSearch = '';

  /// Compact control height used only on the stories chrome (does not change
  /// shared [PostsLayoutMetrics] used by posts).
  double get _controlHeight {
    final m = widget.metrics;
    if (m == null) return widget.compact ? 36.0 : 40.0;
    return switch (m.deviceType) {
      PostsDeviceType.mobileSmall => 34.0,
      PostsDeviceType.mobileLarge => 36.0,
      PostsDeviceType.tablet => 36.0,
      PostsDeviceType.desktop => 38.0,
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
    context.read<StoriesBloc>().add(SearchStoriesEvent(trimmed));
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _applySearch(value);
    });
  }

  void _syncSearchFromState(String? search, {bool force = false}) {
    if (!force && _searchFocusNode.hasFocus) return;
    final text = search ?? '';
    if (_searchController.text == text) return;
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _lastAppliedSearch = text;
  }

  void _clearAllFilters() {
    _searchController.clear();
    _lastAppliedSearch = '';
    context.read<StoriesBloc>().add(const ClearStoriesFiltersEvent());
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final verticalPad = ((_controlHeight - 20) / 2).clamp(6.0, 10.0);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.metrics?.isMobile == true ? 8 : 10,
        vertical: verticalPad,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }

  _StoryFilterValues _valuesFromState(StoriesState state) {
    return switch (state) {
      StoriesLoaded(
        :final searchQuery,
        :final selectedStatus,
        :final selectedPrivacyStatus,
        :final activeOnly,
        :final isApplyingFilters,
      ) =>
        _StoryFilterValues(
          search: searchQuery,
          status: selectedStatus,
          privacy: selectedPrivacyStatus,
          activeOnly: activeOnly,
          isApplying: isApplyingFilters,
        ),
      StoriesEmpty(
        :final searchQuery,
        :final selectedStatus,
        :final selectedPrivacyStatus,
        :final activeOnly,
      ) =>
        _StoryFilterValues(
          search: searchQuery,
          status: selectedStatus,
          privacy: selectedPrivacyStatus,
          activeOnly: activeOnly,
        ),
      _ => const _StoryFilterValues(),
    };
  }

  int _activeFilterCount(_StoryFilterValues values) {
    var count = 0;
    if (values.search?.isNotEmpty ?? false) count++;
    if (values.status != null || values.activeOnly == true) count++;
    if (values.privacy != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<StoriesBloc, StoriesState>(
      listenWhen: (prev, next) {
        final prevSearch = _valuesFromState(prev).search;
        final nextSearch = _valuesFromState(next).search;
        return prevSearch != nextSearch;
      },
      listener: (context, state) {
        _syncSearchFromState(_valuesFromState(state).search, force: true);
      },
      child: BlocBuilder<StoriesBloc, StoriesState>(
        buildWhen: (prev, next) =>
            _valuesFromState(prev) != _valuesFromState(next),
        builder: (context, state) {
          final values = _valuesFromState(state);
          _syncSearchFromState(values.search);
          final filterCount = _activeFilterCount(values);
          final gap = widget.metrics?.filterGap ?? 6.0;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterContent(
                searchField: _searchField(l10n, theme, values.isApplying),
                dropdowns: [
                  _statusDropdown(l10n, values),
                  _privacyDropdown(l10n, values),
                ],
                compact: widget.compact,
                metrics: widget.metrics,
                controlHeight: _controlHeight,
              ),
              if (filterCount > 0) ...[
                SizedBox(height: gap * 0.6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('activeFiltersCount', {
                          'count': '$filterCount',
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: values.isApplying ? null : _clearAllFilters,
                      child: Text(
                        l10n.t('clearAllFilters'),
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );

          if (widget.compact) return content;

          return content;
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
    return SizedBox(
      height: _controlHeight,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onSubmitted: _applySearch,
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: widget.compact ? 12.5 : 13),
        decoration: _fieldDecoration(
          context,
          hint: StoriesAdminL10n.searchHint(context),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isApplying)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
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
    );
  }

  String? _statusDropdownValue(_StoryFilterValues values) {
    if (values.activeOnly == true) {
      return StoriesAdminL10n.activeStatusFilter;
    }
    return values.status;
  }

  Widget _statusDropdown(AppLocalizations l10n, _StoryFilterValues values) {
    final dropdownValue = _statusDropdownValue(values);

    return SizedBox(
      height: _controlHeight,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('story_status_$dropdownValue'),
        initialValue: dropdownValue,
        isExpanded: true,
        isDense: true,
        style: TextStyle(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: _fieldDecoration(
          context,
          hint: l10n.tOr('status', 'Status'),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(l10n.tOr('all', 'All')),
          ),
          for (final status in const ['PUBLISHED', 'HIDDEN', 'EXPIRED'])
            DropdownMenuItem(
              value: status,
              child: Text(StoriesAdminL10n.statusLabel(context, status)),
            ),
          DropdownMenuItem(
            value: StoriesAdminL10n.activeStatusFilter,
            child: Text(StoriesAdminL10n.activeStatusFilterLabel(context)),
          ),
        ],
        onChanged: values.isApplying
            ? null
            : (value) {
                if (value == null) {
                  context.read<StoriesBloc>().add(
                        const FilterStoriesEvent(
                          clearStatus: true,
                          clearActiveOnly: true,
                        ),
                      );
                  return;
                }
                if (value == StoriesAdminL10n.activeStatusFilter) {
                  context.read<StoriesBloc>().add(
                        const FilterStoriesEvent(
                          clearStatus: true,
                          activeOnly: true,
                        ),
                      );
                  return;
                }
                context.read<StoriesBloc>().add(
                      FilterStoriesEvent(
                        status: value,
                        clearActiveOnly: true,
                      ),
                    );
              },
      ),
    );
  }

  Widget _privacyDropdown(AppLocalizations l10n, _StoryFilterValues values) {
    return SizedBox(
      height: _controlHeight,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('story_privacy_${values.privacy}'),
        initialValue: values.privacy,
        isExpanded: true,
        isDense: true,
        style: TextStyle(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: _fieldDecoration(
          context,
          hint: l10n.tOr('privacy', 'Privacy'),
        ),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text(l10n.tOr('all', 'All')),
          ),
          for (final privacy in const ['PUBLIC', 'PRIVATE', 'FRIENDS'])
            DropdownMenuItem(
              value: privacy,
              child: Text(StoriesAdminL10n.privacyLabel(context, privacy)),
            ),
        ],
        onChanged: values.isApplying
            ? null
            : (value) {
                context.read<StoriesBloc>().add(
                      FilterStoriesEvent(
                        privacyStatus: value,
                        clearPrivacyStatus: value == null,
                      ),
                    );
              },
      ),
    );
  }
}

class _StoryFilterValues {
  const _StoryFilterValues({
    this.search,
    this.status,
    this.privacy,
    this.activeOnly,
    this.isApplying = false,
  });

  final String? search;
  final String? status;
  final String? privacy;
  final bool? activeOnly;
  final bool isApplying;

  @override
  bool operator ==(Object other) {
    return other is _StoryFilterValues &&
        other.search == search &&
        other.status == status &&
        other.privacy == privacy &&
        other.activeOnly == activeOnly &&
        other.isApplying == isApplying;
  }

  @override
  int get hashCode => Object.hash(
        search,
        status,
        privacy,
        activeOnly,
        isApplying,
      );
}

class _FilterContent extends StatelessWidget {
  const _FilterContent({
    required this.searchField,
    required this.dropdowns,
    required this.compact,
    required this.controlHeight,
    this.metrics,
  });

  final Widget searchField;
  final List<Widget> dropdowns;
  final bool compact;
  final double controlHeight;
  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final m = metrics ?? PostsLayoutMetrics(getPostsDeviceType(width));
        final gap = m.filterGap;
        // Stack only on very narrow widths so medium+ keep one filter row.
        final stackFilters = width < 560;

        if (stackFilters) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              searchField,
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: dropdowns[0]),
                  SizedBox(width: gap),
                  Expanded(child: dropdowns[1]),
                ],
              ),
            ],
          );
        }

        return SizedBox(
          height: controlHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: compact ? 3 : 3, child: searchField),
              SizedBox(width: gap),
              Expanded(flex: 2, child: dropdowns[0]),
              SizedBox(width: gap),
              Expanded(flex: 2, child: dropdowns[1]),
            ],
          ),
        );
      },
    );
  }
}
