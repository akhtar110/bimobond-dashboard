import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/post_date_format.dart';

const _kCustomDateRangeTitle = 'Custom Date Range';

/// Start/end date range picker — two fields only.
class PostsDateRangePicker extends StatelessWidget {
  const PostsDateRangePicker({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
    this.forceVertical = false,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;
  final bool forceVertical;

  Future<void> _pickDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bounds = postDatePickerBounds(
      isStart: isStart,
      from: from,
      to: to,
    );

    final picked = await showDatePicker(
      context: context,
      firstDate: bounds.firstDate,
      lastDate: bounds.lastDate,
      initialDate: bounds.initialDate,
      helpText: isStart
          ? l10n.tOr('startDate', 'Start Date')
          : l10n.tOr('endDate', 'End Date'),
      builder: (ctx, child) => Theme(data: theme, child: child!),
    );
    if (picked == null || !context.mounted) return;

    final (nextFrom, nextTo) = normalizePostDateRange(
      isStart: isStart,
      picked: picked,
      from: from,
      to: to,
    );
    onChanged(nextFrom, nextTo);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;

    final startField = _DateField(
      label: l10n.tOr('startDate', 'Start Date'),
      value: from != null
          ? formatPostDisplayDate(from!, locale: locale)
          : null,
      onTap: () => _pickDate(context, isStart: true),
    );
    final endField = _DateField(
      label: l10n.tOr('endDate', 'End Date'),
      value: to != null ? formatPostDisplayDate(to!, locale: locale) : null,
      onTap: () => _pickDate(context, isStart: false),
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

class _DateField extends StatelessWidget {
  const _DateField({
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
                    Icons.calendar_today_rounded,
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

/// Date range section inside the filter popup.
class PostsDateRangeFilterPanel extends StatelessWidget {
  const PostsDateRangeFilterPanel({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;

  @override
  Widget build(BuildContext context) {
    return PostsDateRangePicker(
      from: from,
      to: to,
      onChanged: onChanged,
    );
  }
}

String postsCustomDateRangeTitle(AppLocalizations l10n) =>
    l10n.tOr('postFilterCustomDateRange', _kCustomDateRangeTitle);

/// Responsive custom date range dialog.
Future<void> showPostsDateRangePickerDialog({
  required BuildContext context,
  required DateTime? from,
  required DateTime? to,
  required void Function(DateTime? from, DateTime? to) onApply,
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
            child: _PostsDateRangePickerSheet(
              from: from,
              to: to,
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
          child: _PostsDateRangePickerSheet(
            from: from,
            to: to,
            onApply: onApply,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    },
  );
}

class _PostsDateRangePickerSheet extends StatefulWidget {
  const _PostsDateRangePickerSheet({
    required this.from,
    required this.to,
    required this.onApply,
    required this.borderRadius,
    this.showDragHandle = false,
    this.forceVertical = false,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onApply;
  final BorderRadius borderRadius;
  final bool showDragHandle;
  final bool forceVertical;

  @override
  State<_PostsDateRangePickerSheet> createState() =>
      _PostsDateRangePickerSheetState();
}

class _PostsDateRangePickerSheetState extends State<_PostsDateRangePickerSheet> {
  late DateTime? _draftFrom;
  late DateTime? _draftTo;

  @override
  void initState() {
    super.initState();
    _draftFrom = widget.from;
    _draftTo = widget.to;
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
              postsCustomDateRangeTitle(l10n),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 20),
            PostsDateRangePicker(
              from: _draftFrom,
              to: _draftTo,
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
