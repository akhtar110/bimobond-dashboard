import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../domain/entities/post_filters.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_date_format.dart';
import '../utils/posts_responsive.dart';

/// Compact start/end date pickers for filtering posts by `createdAt`.
class PostsDateRangeFilter extends StatelessWidget {
  const PostsDateRangeFilter({super.key, this.metrics});

  final PostsLayoutMetrics? metrics;

  double get _controlHeight {
    final m = metrics;
    if (m == null) return ToolbarFilterStyle.controlHeight;
    return switch (m.deviceType) {
      PostsDeviceType.mobileSmall => 34.0,
      PostsDeviceType.mobileLarge => 36.0,
      PostsDeviceType.tablet => 38.0,
      PostsDeviceType.desktop => 40.0,
    };
  }

  PostFilters? _filtersFromState(PostsState state) {
    return switch (state) {
      PostsLoaded(:final filters) => filters,
      PostsEmpty(:final filters) => filters,
      _ => null,
    };
  }

  PostFilters _readFilters(PostsState state, BuildContext context) {
    return _filtersFromState(state) ?? context.read<PostsBloc>().activeFilters;
  }

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStart,
    required PostFilters filters,
  }) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bounds = postDatePickerBounds(
      isStart: isStart,
      from: filters.createdFrom,
      to: filters.createdTo,
    );

    final picked = await showDatePicker(
      context: context,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
      initialDate: bounds.initialDate,
      helpText: isStart ? l10n.t('startDate') : l10n.t('endDate'),
      builder: (ctx, child) => Theme(data: theme, child: child!),
    );
    if (picked == null || !context.mounted) return;

    final (from, to) = normalizePostDateRange(
      isStart: isStart,
      picked: picked,
      from: filters.createdFrom,
      to: filters.createdTo,
    );

    context.read<PostsBloc>().add(
          FilterPostsByDateRangeEvent(createdFrom: from, createdTo: to),
        );
  }

  void _clearDates(BuildContext context) {
    context.read<PostsBloc>().add(
          const FilterPostsByDateRangeEvent(
            createdFrom: null,
            createdTo: null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = _controlHeight;
    final gap = metrics?.filterGap ?? 8.0;

    return BlocBuilder<PostsBloc, PostsState>(
      buildWhen: (prev, next) {
        final prevF = _filtersFromState(prev);
        final nextF = _filtersFromState(next);
        if (prevF == null || nextF == null) return prev.runtimeType != next.runtimeType;
        return prevF.createdFrom != nextF.createdFrom ||
            prevF.createdTo != nextF.createdTo;
      },
      builder: (context, state) {
        final filters = _readFilters(state, context);
        final hasRange = filters.hasDateRange;

        final startField = _PostsDateField(
          label: l10n.t('startDate'),
          value: filters.createdFrom,
          height: height,
          onTap: () => _pickDate(context, isStart: true, filters: filters),
          onClear: filters.createdFrom != null
              ? () => context.read<PostsBloc>().add(
                    FilterPostsByDateRangeEvent(
                      createdFrom: null,
                      createdTo: filters.createdTo,
                    ),
                  )
              : null,
        );

        final endField = _PostsDateField(
          label: l10n.t('endDate'),
          value: filters.createdTo,
          height: height,
          onTap: () => _pickDate(context, isStart: false, filters: filters),
          onClear: filters.createdTo != null
              ? () => context.read<PostsBloc>().add(
                    FilterPostsByDateRangeEvent(
                      createdFrom: filters.createdFrom,
                      createdTo: null,
                    ),
                  )
              : null,
        );

        if (metrics?.isMobile == true) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              startField,
              SizedBox(height: gap),
              endField,
              if (hasRange) ...[
                SizedBox(height: gap),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () => _clearDates(context),
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: Text(l10n.t('clear')),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: startField),
            SizedBox(width: gap),
            Expanded(child: endField),
            if (hasRange) ...[
              SizedBox(width: gap),
              IconButton(
                onPressed: () => _clearDates(context),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                tooltip: l10n.t('clear'),
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints(minWidth: height, minHeight: height),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PostsDateField extends StatelessWidget {
  const _PostsDateField({
    required this.label,
    required this.value,
    required this.height,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final double height;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null;
    final display = hasValue
        ? formatPostDisplayDate(value!)
        : l10n.tOr('selectDate', 'Select date');

    return Material(
      color: hasValue ? scheme.primaryContainer : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(ToolbarFilterStyle.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ToolbarFilterStyle.borderRadius),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ToolbarFilterStyle.borderRadius),
            border: Border.all(
              color: hasValue
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: hasValue
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: height <= 36
                    ? Text(
                        hasValue ? '$label · $display' : label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: hasValue
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                          height: 1.1,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: hasValue
                                  ? scheme.onPrimaryContainer
                                      .withValues(alpha: 0.85)
                                  : scheme.onSurfaceVariant,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasValue
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: scheme.onPrimaryContainer,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  tooltip: l10n.t('clear'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
