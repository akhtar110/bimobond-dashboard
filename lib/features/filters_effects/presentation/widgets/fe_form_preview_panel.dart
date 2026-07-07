import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/fe_preview_color_utils.dart';
import 'fe_catalog_item_preview.dart';

/// Color palette for filter/effect form dialogs (left column).
class FeFormColorPicker extends StatelessWidget {
  const FeFormColorPicker({
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
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (allowClear)
              _ColorSwatch(
                selected: normalized == null || normalized.isEmpty,
                gradient: [
                  scheme.surfaceContainerHigh,
                  scheme.surfaceContainerHighest,
                ],
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
        width: 68,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
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
                  ? Icon(
                      Icons.check_rounded,
                      color: _contrastIconColor(context, gradient.first),
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _contrastIconColor(BuildContext context, Color background) {
    final scheme = Theme.of(context).colorScheme;
    return background.computeLuminance() > 0.55
        ? scheme.onSurface
        : scheme.surface;
  }
}

/// Live preview pane for filter/effect form dialogs (right column).
class FeFormPreviewPane extends StatelessWidget {
  const FeFormPreviewPane({
    super.key,
    required this.mode,
    required this.label,
    this.previewColorHex,
    this.emoji,
    this.thumbnailUrl,
    this.engineKey,
    this.effectType,
    this.requiresFaceDetection = false,
    this.isScreenEffect = false,
  });

  final FeCatalogPreviewMode mode;
  final String label;
  final String? previewColorHex;
  final String? emoji;
  final String? thumbnailUrl;
  final String? engineKey;
  final String? effectType;
  final bool requiresFaceDetection;
  final bool isScreenEffect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: FeCatalogItemPreview(
              mode: mode,
              label: label,
              previewColorHex: previewColorHex,
              emoji: emoji,
              thumbnailUrl: thumbnailUrl,
              engineKey: engineKey,
              effectType: effectType,
              requiresFaceDetection: requiresFaceDetection,
              isScreenEffect: isScreenEffect,
            ),
          ),
        ),
      ),
    );
  }
}
