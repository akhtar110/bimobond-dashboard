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
