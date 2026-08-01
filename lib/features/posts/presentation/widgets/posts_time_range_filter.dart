import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_time_format.dart';
import '../utils/posts_time_filter_utils.dart';

const _kTimeRangeTitle = 'Time Range';

String postsTimeRangeTitle(AppLocalizations l10n) =>
    l10n.tOr('postFilterTimeRange', _kTimeRangeTitle);

String _timeLabel(AppLocalizations l10n, String key, String fallback) =>
    l10n.tOr(key, fallback);

/// Resolves time-range filter strings with English fallbacks.
String postsTimeRangeLabelT(AppLocalizations l10n, String key) =>
    switch (key) {
      'postFilterTimeRange' => postsTimeRangeTitle(l10n),
      'startTime' => _timeLabel(l10n, 'startTime', 'Start Time'),
      'endTime' => _timeLabel(l10n, 'endTime', 'End Time'),
      _ => l10n.tOr(key, key),
    };

/// Start/end time range picker — two fields only.
class PostsTimeRangePicker extends StatelessWidget {
  const PostsTimeRangePicker({
    super.key,
    required this.fromMinutes,
    required this.toMinutes,
    required this.onChanged,
    this.forceVertical = false,
  });

  final int? fromMinutes;
  final int? toMinutes;
  final void Function(int? fromMinutes, int? toMinutes) onChanged;
  final bool forceVertical;

  Future<void> _pickTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = TimeOfDay.now();
    final initial = isStart
        ? (fromMinutes != null ? postMinutesToTime(fromMinutes!) : now)
        : (toMinutes != null ? postMinutesToTime(toMinutes!) : now);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: isStart
          ? _timeLabel(l10n, 'startTime', 'Start Time')
          : _timeLabel(l10n, 'endTime', 'End Time'),
      builder: (ctx, child) => Theme(data: theme, child: child!),
    );
    if (picked == null || !context.mounted) return;

    final (from, to) = normalizePostTimeRange(
      isStart: isStart,
      pickedMinutes: postTimeToMinutes(picked),
      from: fromMinutes,
      to: toMinutes,
    );
    onChanged(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;

    final startField = _TimeField(
      label: _timeLabel(l10n, 'startTime', 'Start Time'),
      value: fromMinutes != null
          ? formatPostDisplayTime(fromMinutes!, locale: locale)
          : null,
      onTap: () => _pickTime(context, isStart: true),
    );
    final endField = _TimeField(
      label: _timeLabel(l10n, 'endTime', 'End Time'),
      value: toMinutes != null
          ? formatPostDisplayTime(toMinutes!, locale: locale)
          : null,
      onTap: () => _pickTime(context, isStart: false),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = forceVertical || constraints.maxWidth < 440;

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              startField,
              const SizedBox(height: 14),
              endField,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: startField),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
            Expanded(child: endField),
          ],
        );
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasValue
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outlineVariant.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: hasValue ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Time range section inside the filter popup.
class PostsTimeRangeFilterPanel extends StatelessWidget {
  const PostsTimeRangeFilterPanel({
    super.key,
    required this.fromMinutes,
    required this.toMinutes,
    required this.onChanged,
  });

  final int? fromMinutes;
  final int? toMinutes;
  final void Function(int? fromMinutes, int? toMinutes) onChanged;

  @override
  Widget build(BuildContext context) {
    return PostsTimeRangePicker(
      fromMinutes: fromMinutes,
      toMinutes: toMinutes,
      onChanged: onChanged,
    );
  }
}

/// Responsive time range dialog — matches [showPostsDateRangePickerDialog].
Future<void> showPostsTimeRangePickerDialog({
  required BuildContext context,
  required int? fromMinutes,
  required int? toMinutes,
  required void Function(int? from, int? to) onApply,
}) {
  final width = MediaQuery.sizeOf(context).width;

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.85;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _PostsTimeRangePickerSheet(
              fromMinutes: fromMinutes,
              toMinutes: toMinutes,
              onApply: onApply,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              showDragHandle: true,
              forceVertical: true,
            ),
          ),
        );
      },
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final media = MediaQuery.of(dialogContext);
      final screenWidth = media.size.width;
      final screenHeight = media.size.height;
      final dialogWidth = (screenWidth * 0.92).clamp(340.0, 480.0);
      final maxDialogHeight = screenHeight * 0.75;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth < 900 ? 20 : 40,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: maxDialogHeight,
          ),
          child: _PostsTimeRangePickerSheet(
            fromMinutes: fromMinutes,
            toMinutes: toMinutes,
            onApply: onApply,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    },
  );
}

class _PostsTimeRangePickerSheet extends StatefulWidget {
  const _PostsTimeRangePickerSheet({
    required this.fromMinutes,
    required this.toMinutes,
    required this.onApply,
    required this.borderRadius,
    this.showDragHandle = false,
    this.forceVertical = false,
  });

  final int? fromMinutes;
  final int? toMinutes;
  final void Function(int? from, int? to) onApply;
  final BorderRadius borderRadius;
  final bool showDragHandle;
  final bool forceVertical;

  @override
  State<_PostsTimeRangePickerSheet> createState() =>
      _PostsTimeRangePickerSheetState();
}

class _PostsTimeRangePickerSheetState extends State<_PostsTimeRangePickerSheet> {
  late int? _draftFrom;
  late int? _draftTo;

  @override
  void initState() {
    super.initState();
    _draftFrom = widget.fromMinutes;
    _draftTo = widget.toMinutes;
  }

  void _apply() {
    widget.onApply(_draftFrom, _draftTo);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _draftFrom = null;
      _draftTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final topPadding = widget.showDragHandle ? 10.0 : 22.0;

    return Material(
      color: scheme.surface,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showDragHandle)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Text(
              postsTimeRangeTitle(l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 20),
            PostsTimeRangePicker(
              fromMinutes: _draftFrom,
              toMinutes: _draftTo,
              forceVertical: widget.forceVertical,
              onChanged: (from, to) {
                setState(() {
                  _draftFrom = from;
                  _draftTo = to;
                });
              },
            ),
            const SizedBox(height: 20),
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.tOr('apply', 'Apply')),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          child: Text(l10n.tOr('clear', 'Clear')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.tOr('cancel', 'Cancel')),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.tOr('cancel', 'Cancel')),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: Text(l10n.tOr('clear', 'Clear')),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.tOr('apply', 'Apply')),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Toolbar control — opens the time range dialog.
class PostsTimeRangeFilterButton extends StatelessWidget {
  const PostsTimeRangeFilterButton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PostsBloc, PostsState, (int?, int?)>(
      selector: (state) {
        final filters = switch (state) {
          PostsLoaded(:final filters) => filters,
          PostsEmpty(:final filters) => filters,
          _ => context.read<PostsBloc>().activeFilters,
        };
        return (filters.createdTimeFromMinutes, filters.createdTimeToMinutes);
      },
      builder: (context, times) {
        final (fromMinutes, toMinutes) = times;
        final isActive = fromMinutes != null || toMinutes != null;
        final locale = Localizations.localeOf(context).languageCode;
        final label = formatPostsTimeRangeLabel(
          fromMinutes: fromMinutes,
          toMinutes: toMinutes,
          locale: locale,
          t: (key) => postsTimeRangeLabelT(l10n, key),
        );
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainerLow;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: postsTimeRangeTitle(l10n),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openDialog(
                context,
                fromMinutes: fromMinutes,
                toMinutes: toMinutes,
              ),
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
                    Icon(Icons.access_time_rounded, size: 17, color: fg),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
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

  void _openDialog(
    BuildContext context, {
    required int? fromMinutes,
    required int? toMinutes,
  }) {
    final bloc = context.read<PostsBloc>();

    showPostsTimeRangePickerDialog(
      context: context,
      fromMinutes: fromMinutes,
      toMinutes: toMinutes,
      onApply: (from, to) {
        final filters = bloc.activeFilters;
        bloc.add(
          UpdatePostFiltersEvent(
            from == null && to == null
                ? filters.copyWith(clearTimeRange: true)
                : filters.copyWith(
                    createdTimeFromMinutes: from,
                    createdTimeToMinutes: to,
                  ),
          ),
        );
      },
    );
  }
}
