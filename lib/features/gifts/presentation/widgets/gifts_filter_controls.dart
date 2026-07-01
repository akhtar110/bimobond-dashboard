import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/gifts_bloc.dart';

const double giftsToolbarControlHeight = 48;
const double giftsToolbarControlRadius = 16;

/// Background for the pinned filter bar — matches [GiftsPage] scaffold.
Color giftsToolbarBarBackground(ColorScheme scheme) => scheme.surfaceContainerLowest;

/// Default fill for search / filter controls sitting on the toolbar bar.
Color giftsToolbarControlFill(
  ColorScheme scheme, {
  bool isActive = false,
  bool hovered = false,
}) {
  if (isActive) return scheme.primaryContainer;
  if (hovered) return scheme.surfaceContainerHighest;
  return scheme.brightness == Brightness.dark
      ? scheme.surfaceContainerHigh
      : scheme.surfaceContainerLow;
}

Color giftsToolbarBorderColor(ColorScheme scheme) =>
    scheme.outline.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.18,
    );

OutlineInputBorder giftsToolbarInputBorder(
  ColorScheme scheme, {
  Color? color,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(giftsToolbarControlRadius),
    borderSide: BorderSide(
      color: color ?? giftsToolbarBorderColor(scheme),
      width: width,
    ),
  );
}

BoxDecoration giftsToolbarControlDecoration(
  ColorScheme scheme, {
  bool isActive = false,
  bool hovered = false,
}) {
  return BoxDecoration(
    color: giftsToolbarControlFill(
      scheme,
      isActive: isActive,
      hovered: hovered,
    ),
    borderRadius: BorderRadius.circular(giftsToolbarControlRadius),
    border: Border.all(
      color: isActive ? scheme.primary : giftsToolbarBorderColor(scheme),
      width: 1,
    ),
  );
}

// ─── Search field (stateful so controller survives BLoC rebuilds) ─────────────

class GiftsSearchField extends StatefulWidget {
  const GiftsSearchField({
    required this.searchQuery,
    required this.onChanged,
    this.height = giftsToolbarControlHeight,
    this.compact = false,
  });

  final String searchQuery;
  final ValueChanged<String> onChanged;
  final double height;
  final bool compact;

  @override
  State<GiftsSearchField> createState() => GiftsSearchFieldState();
}

class GiftsSearchFieldState extends State<GiftsSearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(GiftsSearchField old) {
    super.didUpdateWidget(old);
    // Sync externally-cleared state (e.g. refresh) without clobbering user input.
    if (widget.searchQuery != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final outline = giftsToolbarInputBorder(scheme);
    final focused = giftsToolbarInputBorder(scheme, color: scheme.primary, width: 1.5);

    final fontSize = widget.compact ? 12.0 : 13.0;
    final iconSize = widget.compact ? 16.0 : 18.0;

    return SizedBox(
      height: widget.height,
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: fontSize, color: scheme.onSurface),
        decoration: InputDecoration(
          hintText: l10n.t('searchGifts'),
          hintStyle: TextStyle(fontSize: fontSize, color: scheme.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: iconSize,
            color: scheme.onSurfaceVariant,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: widget.compact ? 36 : 44,
            minHeight: widget.height,
          ),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: widget.compact ? 14 : 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: widget.compact ? 28 : 32,
                    minHeight: widget.compact ? 28 : 32,
                  ),
                )
              : null,
          filled: true,
          fillColor: giftsToolbarControlFill(scheme),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 12,
            vertical: widget.compact ? 8 : 10,
          ),
          border: outline,
          enabledBorder: outline,
          disabledBorder: outline,
          focusedBorder: focused,
        ),
      ),
    );
  }
}

// â”€â”€â”€ Date range picker button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class GiftsDateRangeButton extends StatelessWidget {
  const GiftsDateRangeButton({
    required this.label,
    required this.hasRange,
    required this.theme,
    required this.onTap,
    this.icon = Icons.date_range_rounded,
    this.onClear,
  });

  final String label;
  final bool hasRange;
  final ThemeData theme;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final textColor =
        hasRange ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(giftsToolbarControlRadius),
        child: Ink(
          decoration: giftsToolbarControlDecoration(
            scheme,
            isActive: hasRange,
          ),
          child: Container(
            height: giftsToolbarControlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
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
                    icon: Icon(Icons.close_rounded, size: 14, color: textColor),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: context.l10n.t('clear'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Price range picker dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class GiftsPriceRangeDialog extends StatefulWidget {
  const GiftsPriceRangeDialog({
    required this.theme,
    this.initialMin,
    this.initialMax,
  });

  final ThemeData theme;
  final double? initialMin;
  final double? initialMax;

  @override
  State<GiftsPriceRangeDialog> createState() => GiftsPriceRangeDialogState();
}

class GiftsPriceRangeDialogState extends State<GiftsPriceRangeDialog> {
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
    if (min == null && max == null) {
      Navigator.of(context).pop(true);
      return;
    }
    context.read<GiftsBloc>().add(
          UpdatePriceRangeFilterEvent(minPrice: min, maxPrice: max),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.theme.colorScheme;
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
          onPressed: () => Navigator.of(context).pop(false),
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

// â”€â”€â”€ Tab chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class GiftsTabChip extends StatelessWidget {
  const GiftsTabChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : giftsToolbarControlFill(scheme),
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          border: Border.all(
            color: selected
                ? scheme.primary
                : giftsToolbarBorderColor(scheme),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: compact ? 11.5 : 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Sort dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class GiftsSortDropdown extends StatelessWidget {
  const GiftsSortDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final GiftSortType value;
  final List<GiftSortType> items;
  final String Function(GiftSortType) itemLabel;
  final ValueChanged<GiftSortType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<GiftSortType>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(itemLabel(s), overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
