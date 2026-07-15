import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../domain/entities/user_interest_entities.dart';
import '../bloc/user_interests_bloc.dart';
import '../bloc/user_interests_event.dart';
import '../bloc/user_interests_state.dart';
import '../utils/user_interests_responsive.dart';
import 'user_interests_date_range_dialog.dart';

class UserInterestsFiltersBar extends StatefulWidget {
  const UserInterestsFiltersBar({
    super.key,
    this.metrics,
  });

  final UserInterestsLayoutMetrics? metrics;

  static const controlHeight = ToolbarFilterStyle.controlHeight;
  static const dropdownWidth = 148.0;
  static const dateButtonWidth = 168.0;

  @override
  State<UserInterestsFiltersBar> createState() =>
      _UserInterestsFiltersBarState();
}

class _UserInterestsFiltersBarState extends State<UserInterestsFiltersBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<UserInterestsBloc>().add(SearchInterestsEvent(value));
    });
  }

  Future<void> _pickDateRange(UserInterestsFilterQuery filter) async {
    final result = await showUserInterestsDateRangeDialog(
      context,
      initialFrom: filter.createdFrom,
      initialTo: filter.createdTo,
    );
    if (result == null || !mounted) return;

    if (result.clear) {
      context.read<UserInterestsBloc>().add(
            const FilterByDateRangeEvent(),
          );
      return;
    }

    if (result.range != null) {
      context.read<UserInterestsBloc>().add(
            FilterByDateRangeEvent(
              from: result.range!.start,
              to: result.range!.end,
            ),
          );
    }
  }

  String _fmtDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  UserInterestsFilterQuery? _filterFrom(UserInterestsState state) {
    return switch (state) {
      UserInterestsLoaded s => s.filter,
      UserInterestsEmpty s => s.filter,
      _ => null,
    };
  }

  String? _searchFrom(UserInterestsState state) {
    return _filterFrom(state)?.search;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<UserInterestsBloc, UserInterestsState>(
      buildWhen: (p, c) =>
          _filterFrom(p) != _filterFrom(c) ||
          p.runtimeType != c.runtimeType,
      builder: (context, state) {
        final filter = _filterFrom(state);
        if (filter == null) return const SizedBox.shrink();

        final hasActiveFilters = filter.hasActiveFilters;
        final hasDateRange =
            filter.createdFrom != null && filter.createdTo != null;
        final dateLabel = hasDateRange
            ? '${_fmtDate(filter.createdFrom!)} – ${_fmtDate(filter.createdTo!)}'
            : l10n.t('dateRange');

        final searchField = _SearchField(
          hint: l10n.tOr(
            'userInterestSearchPlaceholder',
            'Search category name or slug…',
          ),
          initialValue: _searchFrom(state) ?? '',
          onChanged: _onSearchChanged,
        );

        final preferenceDropdown = _FilterDropdown<UserInterestPreference?>(
          hint: l10n.tOr('userInterestPreference', 'Preference'),
          value: filter.preference,
          items: const [null, ...UserInterestPreference.values],
          itemLabel: (v) => v == null
              ? l10n.t('all')
              : v == UserInterestPreference.interested
                  ? l10n.tOr('userInterestInterested', 'Interested')
                  : l10n.tOr('userInterestNotInterested', 'Not Interested'),
          onChanged: (v) => context
              .read<UserInterestsBloc>()
              .add(FilterByPreferenceEvent(v)),
        );

        final sourceDropdown = _FilterDropdown<UserInterestSource?>(
          hint: l10n.tOr('userInterestSource', 'Source'),
          value: filter.source == UserInterestSource.unknown
              ? null
              : filter.source,
          items: const [
            null,
            UserInterestSource.onboarding,
            UserInterestSource.manual,
            UserInterestSource.like,
            UserInterestSource.comment,
          ],
          itemLabel: (v) => switch (v) {
            null => l10n.t('all'),
            UserInterestSource.onboarding =>
              l10n.tOr('userInterestSourceOnboarding', 'Onboarding'),
            UserInterestSource.manual =>
              l10n.tOr('userInterestSourceManual', 'Manual'),
            UserInterestSource.like =>
              l10n.tOr('userInterestSourceLike', 'Learned from Like'),
            UserInterestSource.comment =>
              l10n.tOr('userInterestSourceComment', 'Learned from Comment'),
            UserInterestSource.unknown => l10n.t('all'),
          },
          onChanged: (v) =>
              context.read<UserInterestsBloc>().add(FilterBySourceEvent(v)),
        );

        final dateButton = _DateRangeButton(
          label: dateLabel,
          hasRange: hasDateRange,
          onTap: () => _pickDateRange(filter),
          onClear: hasDateRange
              ? () => context
                  .read<UserInterestsBloc>()
                  .add(const FilterByDateRangeEvent())
              : null,
        );

        final clearButton = hasActiveFilters
            ? IconButton(
                tooltip: l10n.tOr('clearFilters', 'Clear filters'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () => context
                    .read<UserInterestsBloc>()
                    .add(const ClearUserInterestsFiltersEvent()),
                icon: Icon(
                  Icons.filter_alt_off_outlined,
                  size: 17,
                  color: scheme.error,
                ),
              )
            : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            final m = widget.metrics ??
                UserInterestsLayoutMetrics(
                  getUserInterestsDeviceType(constraints.maxWidth),
                );
            final gap = m.toolbarFilterGap;
            final controlHeight = m.toolbarControlHeight;
            final veryNarrow = constraints.maxWidth < 520;
            final narrow = constraints.maxWidth < 760;

            Widget sized(Widget child, {double? width}) {
              return SizedBox(
                width: width,
                height: controlHeight,
                child: child,
              );
            }

            if (veryNarrow || narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sized(searchField),
                  SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(child: sized(preferenceDropdown)),
                      SizedBox(width: gap),
                      Expanded(child: sized(sourceDropdown)),
                      if (clearButton != null) ...[
                        SizedBox(width: gap),
                        clearButton,
                      ],
                    ],
                  ),
                  SizedBox(height: gap),
                  sized(dateButton),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: sized(searchField)),
                SizedBox(width: gap),
                sized(
                  preferenceDropdown,
                  width: UserInterestsFiltersBar.dropdownWidth,
                ),
                SizedBox(width: gap),
                sized(
                  sourceDropdown,
                  width: UserInterestsFiltersBar.dropdownWidth,
                ),
                SizedBox(width: gap),
                sized(
                  dateButton,
                  width: UserInterestsFiltersBar.dateButtonWidth,
                ),
                ?clearButton,
              ],
            );
          },
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.hint,
    required this.onChanged,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: _controller,
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
      style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
      textInputAction: TextInputAction.search,
      decoration: ToolbarFilterStyle.inputDecoration(
        scheme,
        hintText: widget.hint,
        hintStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : null,
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final safeValue = items.contains(value) ? value : items.first;

    return Container(
      height: UserInterestsFiltersBar.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          isDense: true,
          borderRadius: ToolbarFilterStyle.radius,
          dropdownColor: scheme.surface,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          hint: Text(
            hint,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(
                    itemLabel(v),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            onChanged(v as T);
          },
        ),
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.label,
    required this.hasRange,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool hasRange;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ToolbarFilterStyle.radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: UserInterestsFiltersBar.controlHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_outlined,
                  size: 16,
                  color: hasRange ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: hasRange
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight:
                          hasRange ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: context.l10n.t('clear'),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
