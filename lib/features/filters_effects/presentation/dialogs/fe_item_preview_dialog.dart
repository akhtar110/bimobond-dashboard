import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../utils/fe_filter_preview_support.dart';
import '../utils/fe_preview_color_utils.dart';
import '../widgets/fe_catalog_item_preview.dart';

void showFilterPreviewDialog(BuildContext context, CameraFilterEntity filter) {
  FeFilterPreviewSupport.ensureConfigured();
  // Open immediately with the list/entity payload (no blocking re-fetch).
  showDialog<void>(
    context: context,
    builder: (ctx) => _FeItemPreviewDialog(
      title: ctx.l10n.tOr('fePreviewFilter', 'Filter preview'),
      mode: FeCatalogPreviewMode.filter,
      label: filter.displayLabel,
      previewColorHex: filter.previewColorHex,
      emoji: filter.emoji,
      thumbnailUrl: filter.thumbnailUrl,
      renderType: filter.renderType,
      lutUrl: filter.lutUrl,
      colorMatrix: filter.colorMatrix,
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
      label: effect.displayLabel,
      previewColorHex: effect.previewColorHex,
      emoji: effect.emoji,
      thumbnailUrl: effect.assetUrl ?? effect.thumbnailUrl,
      renderType: effect.renderType,
      effectAnchor: effect.anchor,
      effectStickers: effect.stickers,
      distortionPreset: effect.distortionPreset,
      stickersCount: effect.stickers.length,
      hexLabel: ctx.l10n.tOr('fePreviewColorHexLabel', 'Stored hex'),
      hexValue: effect.previewColorHex?.trim().isNotEmpty == true
          ? effect.previewColorHex!.trim().toUpperCase()
          : ctx.l10n.tOr('fePreviewColorNone', 'None'),
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
    this.emoji,
    this.thumbnailUrl,
    this.renderType,
    this.lutUrl,
    this.colorMatrix = const [],
    this.effectAnchor = const {},
    this.effectStickers = const [],
    this.distortionPreset,
    this.stickersCount = 0,
  });

  final String title;
  final FeCatalogPreviewMode mode;
  final String label;
  final String hexLabel;
  final String hexValue;
  final String? previewColorHex;
  final String? emoji;
  final String? thumbnailUrl;
  final String? renderType;
  final String? lutUrl;
  final List<double> colorMatrix;
  final Map<String, dynamic> effectAnchor;
  final List<CameraEffectStickerLayer> effectStickers;
  final String? distortionPreset;
  final int stickersCount;

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
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: FeCatalogItemPreview(
                  mode: mode,
                  label: label,
                  previewColorHex: previewColorHex,
                  emoji: emoji,
                  thumbnailUrl: thumbnailUrl,
                  renderType: renderType,
                  lutUrl: lutUrl,
                  colorMatrix: colorMatrix,
                  effectAnchor: effectAnchor,
                  effectStickers: effectStickers,
                  distortionPreset: distortionPreset,
                  stickersCount: stickersCount,
                ),
              ),
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
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$hexLabel: $hexValue',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
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
          child: Text(l10n.t('close')),
        ),
      ],
    );
  }
}
