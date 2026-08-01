import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_filter_chip.dart';
import '../bloc/posts_bloc.dart';
import '../utils/posts_datetime_filter_utils.dart';
import 'posts_date_range_picker.dart';
class PostsDateTimeFilterPanel extends StatelessWidget {
  const PostsDateTimeFilterPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PostsDateTimeFilterValue value;
  final ValueChanged<PostsDateTimeFilterValue> onChanged;

  void _emit(PostsDateTimeFilterValue next) => onChanged(next);

  void _applyPreset(PostsDateTimePreset preset) {
    if (preset == PostsDateTimePreset.all) {
      _emit(value.copyWith(clearDates: true));
      return;
    }
    final next = postsDateTimePresetValue(preset);
    _emit(
      PostsDateTimeFilterValue(
        from: next.from,
        to: next.to,
        timeFromMinutes: value.timeFromMinutes,
        timeToMinutes: value.timeToMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preset = value.detectPreset();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GiftsFilterChipWrap(
          children: [
            for (final p in PostsDateTimePreset.values)
              GiftsFilterChoiceChip(
                label: postsDateTimePresetLabel(p, l10n.t),
                selected: preset == p,
                onTap: () => _applyPreset(p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PostsDateRangeFilterPanel(
          from: value.from,
          to: value.to,
          onChanged: (from, to) {
            if (from == null && to == null) {
              _emit(value.copyWith(clearDates: true));
              return;
            }
            _emit(
              PostsDateTimeFilterValue(
                from: from,
                to: to,
                timeFromMinutes: value.timeFromMinutes,
                timeToMinutes: value.timeToMinutes,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Toolbar control — calendar icon with date presets and custom range.
class PostsDateTimeFilterButton extends StatelessWidget {
  const PostsDateTimeFilterButton({super.key, required this.height});

  final double height;

  static const _customRangeKey = Object();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PostsBloc, PostsState, PostsDateTimeFilterValue>(
      selector: (state) {
        final filters = switch (state) {
          PostsLoaded(:final filters) => filters,
          PostsEmpty(:final filters) => filters,
          _ => context.read<PostsBloc>().activeFilters,
        };
        return postsDateTimeFromFilters(
          from: filters.createdFrom,
          to: filters.createdTo,
        );
      },
      builder: (context, value) {
        final isActive = value.hasDateRange;
        final locale = Localizations.localeOf(context).languageCode;
        final label = formatPostsDateFilterLabel(
          value,
          locale: locale,
          t: l10n.t,
        );
        final preset = value.detectPreset();
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: l10n.t('postFilterDateTimeSection'),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<Object>(
              tooltip: l10n.t('postFilterDateTimeSection'),
              offset: Offset(0, height + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (item) {
                if (item == _customRangeKey) {
                  _openCustomRangeDialog(context, value);
                  return;
                }
                _applyPreset(context, item as PostsDateTimePreset);
              },
              itemBuilder: (context) => [
                for (final item in PostsDateTimePreset.values)
                  PopupMenuItem(
                    value: item,
                    height: 36,
                    child: Row(
                      children: [
                        if (preset == item)
                          Icon(Icons.check_rounded,
                              size: 16, color: scheme.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            postsDateTimePresetLabel(item, l10n.t),
                            style: TextStyle(
                              fontWeight: preset == item
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: preset == item ? scheme.primary : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _customRangeKey,
                  height: 36,
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(postsCustomDateRangeTitle(l10n)),
                    ],
                  ),
                ),
              ],
              child: Container(
                height: height,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 10 : 0,
                ),
                constraints: BoxConstraints(
                  minWidth: isActive ? 0 : height,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.date_range_outlined, size: 17, color: fg),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyPreset(BuildContext context, PostsDateTimePreset preset) {
    final bloc = context.read<PostsBloc>();
    final filters = bloc.activeFilters;
    if (preset == PostsDateTimePreset.all) {
      bloc.add(
        UpdatePostFiltersEvent(filters.copyWith(clearDateRange: true)),
      );
      return;
    }
    final next = postsDateTimePresetValue(preset);
    bloc.add(
      UpdatePostFiltersEvent(
        filters.copyWith(
          createdFrom: next.from,
          createdTo: next.to,
        ),
      ),
    );
  }

  void _openCustomRangeDialog(
    BuildContext context,
    PostsDateTimeFilterValue value,
  ) {
    final bloc = context.read<PostsBloc>();

    showPostsDateRangePickerDialog(
      context: context,
      from: value.from,
      to: value.to,
      onApply: (from, to) {
        final filters = bloc.activeFilters;
        bloc.add(
          UpdatePostFiltersEvent(
            from == null && to == null
                ? filters.copyWith(clearDateRange: true)
                : filters.copyWith(
                    createdFrom: from,
                    createdTo: to,
                  ),
          ),
        );
      },
    );
  }
}
