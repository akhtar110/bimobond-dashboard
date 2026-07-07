import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../utils/fe_preview_color_utils.dart';
import '../widgets/fe_catalog_item_preview.dart';

void showFilterPreviewDialog(BuildContext context, CameraFilterEntity filter) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _FeItemPreviewDialog(
      title: ctx.l10n.tOr('fePreviewFilter', 'Filter preview'),
      mode: FeCatalogPreviewMode.filter,
      label: filter.displayLabel,
      previewColorHex: filter.previewColorHex,
      engineKey: filter.engineKey,
      thumbnailUrl: filter.thumbnailUrl,
      hexLabel: ctx.l10n.tOr('fePreviewColorHexLabel', 'Stored hex'),
      hexValue: filter.previewColorHex?.trim().isNotEmpty == true
          ? filter.previewColorHex!.trim().toUpperCase()
          : ctx.l10n.tOr('fePreviewColorNone', 'None'),
    ),
  );
}

void showEffectPreviewDialog(BuildContext context, CameraEffectEntity effect) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _FeItemPreviewDialog(
      title: ctx.l10n.tOr('fePreviewEffect', 'Effect preview'),
      mode: FeCatalogPreviewMode.effect,
      label: effect.labelKey,
      previewColorHex: effect.previewColorHex,
      emoji: effect.emoji,
      thumbnailUrl: effect.assetUrl,
      effectType: effect.effectType,
      requiresFaceDetection: effect.requiresFaceDetection,
      isScreenEffect: effect.isScreenEffect,
      hexLabel: ctx.l10n.tOr('fePreviewColorHexLabel', 'Stored hex'),
      hexValue: effect.previewColorHex?.trim().toUpperCase() ?? '—',
    ),
  );
}

class _FeItemPreviewDialog extends StatelessWidget {
  const _FeItemPreviewDialog({
    required this.title,
    required this.mode,
    required this.label,
    required this.hexLabel,
    required this.hexValue,
    this.previewColorHex,
    this.engineKey,
    this.emoji,
    this.thumbnailUrl,
    this.effectType,
    this.requiresFaceDetection = false,
    this.isScreenEffect = false,
  });

  final String title;
  final FeCatalogPreviewMode mode;
  final String label;
  final String? previewColorHex;
  final String? engineKey;
  final String? emoji;
  final String? thumbnailUrl;
  final String? effectType;
  final bool requiresFaceDetection;
  final bool isScreenEffect;
  final String hexLabel;
  final String hexValue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final gradient = previewGradientForHex(previewColorHex);

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeCatalogItemPreview(
              mode: mode,
              label: label,
              previewColorHex: previewColorHex,
              engineKey: engineKey,
              emoji: emoji,
              thumbnailUrl: thumbnailUrl,
              effectType: effectType,
              requiresFaceDetection: requiresFaceDetection,
              isScreenEffect: isScreenEffect,
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: gradient),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hexLabel, style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            hexValue,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
      ],
    );
  }
}
