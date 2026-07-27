import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../core/localization/localization.dart';
import 'gift_dialog_layout.dart';

/// Compact color field that opens a full [ColorPicker] dialog.
class GiftColorPickerField extends StatelessWidget {
  const GiftColorPickerField({
    super.key,
    required this.layout,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final GiftDialogLayout layout;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hex = normalizeGiftHex(value);
    final color = parseGiftHex(hex);

    return InputDecorator(
      decoration: layout.denseDecoration(
        labelText: l10n.tOr('giftColor', 'Color'),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color ?? scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: color == null
                  ? Icon(
                      Icons.format_color_reset_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hex ?? l10n.tOr('giftNoColor', 'None'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: hex == null ? scheme.onSurfaceVariant : null,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: enabled ? () => _openPicker(context) : null,
            child: Text(l10n.tOr('giftPickColor', 'Pick')),
          ),
          if (hex != null)
            IconButton(
              tooltip: l10n.tOr('giftClearColor', 'Clear'),
              onPressed: enabled ? () => onChanged(null) : null,
              icon: const Icon(Icons.clear_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showGiftColorPickerDialog(
      context,
      initialHex: value,
    );
    if (result == null) return;
    onChanged(result.isEmpty ? null : result);
  }
}

/// Shows a full color picker popup via `flutter_colorpicker`.
///
/// Returns:
/// - `null` if cancelled
/// - empty string if cleared
/// - `#RRGGBB` if confirmed
Future<String?> showGiftColorPickerDialog(
  BuildContext context, {
  String? initialHex,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _GiftColorPickerDialog(initialHex: initialHex),
  );
}

class _GiftColorPickerDialog extends StatefulWidget {
  const _GiftColorPickerDialog({this.initialHex});

  final String? initialHex;

  @override
  State<_GiftColorPickerDialog> createState() => _GiftColorPickerDialogState();
}

class _GiftColorPickerDialogState extends State<_GiftColorPickerDialog> {
  late Color _color;

  @override
  void initState() {
    super.initState();
    _color = parseGiftHex(normalizeGiftHex(widget.initialHex)) ??
        const Color(0xFFFF2D55);
  }

  String get _hex => colorToGiftHex(_color);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.tOr('giftPickColor', 'Pick color')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hex,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ColorPicker(
              pickerColor: _color,
              onColorChanged: (color) => setState(() => _color = color),
              enableAlpha: false,
              hexInputBar: true,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.72,
              displayThumbColor: true,
              portraitOnly: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(l10n.tOr('giftClearColor', 'Clear')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.tOr('cancel', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _hex),
          child: Text(l10n.tOr('apply', 'Apply')),
        ),
      ],
    );
  }
}

String? normalizeGiftHex(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  final withHash = value.startsWith('#') ? value : '#$value';
  if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(withHash)) {
    return withHash.toUpperCase();
  }
  if (RegExp(r'^#[0-9a-fA-F]{3}$').hasMatch(withHash)) {
    final expanded = withHash
        .substring(1)
        .split('')
        .map((c) => '$c$c')
        .join();
    return '#$expanded'.toUpperCase();
  }
  return null;
}

Color? parseGiftHex(String? hex) {
  final normalized = normalizeGiftHex(hex);
  if (normalized == null) return null;
  final value = int.tryParse(normalized.substring(1), radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

String colorToGiftHex(Color color) {
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;
  return '#${r.toRadixString(16).padLeft(2, '0')}'
          '${g.toRadixString(16).padLeft(2, '0')}'
          '${b.toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}
