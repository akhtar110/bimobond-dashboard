import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';

class GiftReportRangeFilterButton extends StatelessWidget {
  const GiftReportRangeFilterButton({
    super.key,
    required this.label,
    required this.hasRange,
    required this.onTap,
    this.icon = Icons.date_range_rounded,
    this.onClear,
    this.dense = false,
  });

  final String label;
  final bool hasRange;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = hasRange ? scheme.primary : scheme.outlineVariant;
    final bgColor = hasRange
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerLow;
    final textColor = hasRange ? scheme.primary : scheme.onSurfaceVariant;
    final height = dense ? 34.0 : 40.0;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: textColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded, size: 13, color: textColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: context.l10n.t('clear'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GiftReportPriceRangeDialog extends StatefulWidget {
  const GiftReportPriceRangeDialog({
    super.key,
    this.initialMin,
    this.initialMax,
    required this.onApply,
  });

  final double? initialMin;
  final double? initialMax;
  final void Function(double? minPrice, double? maxPrice) onApply;

  @override
  State<GiftReportPriceRangeDialog> createState() =>
      _GiftReportPriceRangeDialogState();
}

class GiftReportDateRangeDialog extends StatefulWidget {
  const GiftReportDateRangeDialog({
    super.key,
    this.initialFrom,
    this.initialTo,
    required this.onApply,
  });

  final DateTime? initialFrom;
  final DateTime? initialTo;
  final void Function(DateTime? fromDate, DateTime? toDate) onApply;

  @override
  State<GiftReportDateRangeDialog> createState() =>
      _GiftReportDateRangeDialogState();
}

class _GiftReportDateRangeDialogState extends State<GiftReportDateRangeDialog> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFrom;
    _toDate = widget.initialTo;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _fromDate ?? _toDate ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _toDate ?? _fromDate ?? DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_fromDate != null && _fromDate!.isAfter(_toDate!)) {
        _fromDate = _toDate;
      }
    });
  }

  void _clear() {
    widget.onApply(null, null);
    Navigator.of(context).pop();
  }

  void _apply() {
    widget.onApply(_fromDate, _toDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.t('dateRange')),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _pickFromDate,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                alignment: Alignment.centerLeft,
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('${l10n.t('from')}: ${_formatDate(_fromDate)}'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _pickToDate,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                alignment: Alignment.centerLeft,
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('${l10n.t('to')}: ${_formatDate(_toDate)}'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        TextButton(
          onPressed: _clear,
          child: Text(l10n.t('clear')),
        ),
        FilledButton(
          onPressed: _apply,
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}

class _GiftReportPriceRangeDialogState extends State<GiftReportPriceRangeDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(text: _format(widget.initialMin));
    _maxCtrl = TextEditingController(text: _format(widget.initialMax));
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  String _format(double? value) => value == null
      ? ''
      : value.truncateToDouble() == value
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(2);

  double? _parse(String text) {
    final cleaned = text.trim().replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _apply() {
    var min = _parse(_minCtrl.text);
    var max = _parse(_maxCtrl.text);
    if (min != null && max != null && min > max) {
      final swapped = min;
      min = max;
      max = swapped;
    }
    widget.onApply(min, max);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return AlertDialog(
      title: Text(l10n.t('priceRange')),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _minCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.t('minPriceLabel'),
                hintText: l10n.t('priceExample'),
                border: border,
                enabledBorder: border,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.t('maxPriceLabel'),
                hintText: l10n.t('priceExampleMax'),
                border: border,
                enabledBorder: border,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: _apply,
          child: Text(l10n.t('apply')),
        ),
      ],
    );
  }
}

String giftReportPriceRangeLabel(
  BuildContext context, {
  required double? minPrice,
  required double? maxPrice,
}) {
  final l10n = context.l10n;
  if (minPrice == null && maxPrice == null) return l10n.t('priceRange');
  String fmt(double v) => v.truncateToDouble() == v
      ? '\$${v.toInt()}'
      : '\$${v.toStringAsFixed(2)}';
  if (minPrice != null && maxPrice != null) {
    return '${fmt(minPrice)} – ${fmt(maxPrice)}';
  }
  if (minPrice != null) return '${fmt(minPrice)}+';
  return context.tr('priceUpTo', {'amount': fmt(maxPrice!)});
}

String giftReportDateRangeLabel(
  BuildContext context, {
  required DateTime? fromDate,
  required DateTime? toDate,
}) {
  final l10n = context.l10n;
  if (fromDate == null && toDate == null) return l10n.t('dateRange');
  final fmt = (DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  if (fromDate != null && toDate != null) {
    return '${fmt(fromDate)} – ${fmt(toDate)}';
  }
  if (fromDate != null) {
    return context.tr('dateFrom', {'date': fmt(fromDate)});
  }
  return context.tr('dateUntil', {'date': fmt(toDate!)});
}
