import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/fe_preview_color_utils.dart';

/// Palette-based preview color picker (stores hex for the API).
class FePreviewColorPicker extends StatelessWidget {
  const FePreviewColorPicker({
    super.key,
    required this.selectedHex,
    required this.onSelected,
    this.allowClear = false,
  });

  final String? selectedHex;
  final ValueChanged<String?> onSelected;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final normalized = selectedHex?.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feSelectPreviewColor', 'Select preview color'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allowClear)
              _ColorSwatch(
                selected: normalized == null || normalized.isEmpty,
                gradient: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                label: l10n.tOr('fePreviewColorNone', 'None'),
                onTap: () => onSelected(null),
              ),
            for (final option in kFePreviewColorPalette)
              _ColorSwatch(
                selected: option.hex.toUpperCase() == normalized,
                gradient: option.colors,
                label: option.label,
                onTap: () => onSelected(option.hex),
              ),
          ],
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  l10n.tOr('fePreviewColorHexLabel', 'Stored hex'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (normalized != null && normalized.isNotEmpty)
                        ? normalized
                        : l10n.tOr('fePreviewColorNone', 'None'),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.selected,
    required this.gradient,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final List<Color> gradient;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(Icons.check_rounded, color: _contrastIconColor(gradient.first), size: 20)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _contrastIconColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.55 ? Colors.black87 : Colors.white;
  }
}
