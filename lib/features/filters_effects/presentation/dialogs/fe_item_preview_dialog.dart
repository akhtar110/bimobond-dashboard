import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/filter_settings_entities.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../../domain/usecases/filters_effects_usecases.dart';
import '../utils/fe_filter_settings_preview.dart';
import '../utils/fe_preview_color_utils.dart';
import '../widgets/fe_catalog_item_preview.dart';

class _FilterPreviewBundle {
  const _FilterPreviewBundle({
    required this.filter,
    required this.schema,
  });

  final CameraFilterEntity filter;
  final FilterSettingsSchemaEntity schema;
}

Future<_FilterPreviewBundle> _loadFilterPreviewBundle(
  CameraFilterEntity filter,
) async {
  final schema = await di.sl<GetFilterSettingsSchemaUseCase>()();
  var loaded = filter;
  if (filter.id.trim().isNotEmpty) {
    try {
      // Detail endpoint has complete filterSettings (list payloads can be sparse).
      loaded = await di.sl<GetCameraFilterUseCase>()(filter.id);
    } catch (_) {
      loaded = filter;
    }
  }
  return _FilterPreviewBundle(filter: loaded, schema: schema);
}

void showFilterPreviewDialog(BuildContext context, CameraFilterEntity filter) {
  showDialog<void>(
    context: context,
    builder: (ctx) => FutureBuilder<_FilterPreviewBundle>(
      future: _loadFilterPreviewBundle(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return AlertDialog(
            title: Text(ctx.l10n.tOr('fePreviewFilter', 'Filter preview')),
            content: const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return AlertDialog(
            title: Text(ctx.l10n.tOr('fePreviewFilter', 'Filter preview')),
            content: Text(
              ctx.l10n.tOr('fePreviewLoadFailed', 'Could not load preview'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(ctx.l10n.t('cancel')),
              ),
            ],
          );
        }

        final bundle = snapshot.data!;
        final loaded = bundle.filter;
        final previewLook = filterSettingsPreviewLook(
          filterSettings: loaded.filterSettings,
          schema: bundle.schema,
          engineKey: loaded.engineKey,
        );

        return _FeItemPreviewDialog(
          title: ctx.l10n.tOr('fePreviewFilter', 'Filter preview'),
          mode: FeCatalogPreviewMode.filter,
          label: loaded.displayLabel,
          previewColorHex: loaded.previewColorHex,
          engineKey: loaded.engineKey,
          thumbnailUrl: loaded.thumbnailUrl,
          filterPreviewLook: previewLook,
          hexLabel: ctx.l10n.tOr('fePreviewColorHexLabel', 'Stored hex'),
          hexValue: loaded.previewColorHex?.trim().isNotEmpty == true
              ? loaded.previewColorHex!.trim().toUpperCase()
              : ctx.l10n.tOr('fePreviewColorNone', 'None'),
        );
      },
    ),
  );
}

void showEffectPreviewDialog(BuildContext context, CameraEffectEntity effect) {
  final placement = effect.placement;
  final label = effect.labelKey.trim().isNotEmpty
      ? effect.labelKey
      : (effect.slug.trim().isNotEmpty ? effect.slug : '—');

  showDialog<void>(
    context: context,
    builder: (ctx) => _FeItemPreviewDialog(
      title: ctx.l10n.tOr('fePreviewEffect', 'Effect preview'),
      mode: FeCatalogPreviewMode.effect,
      label: label,
      previewColorHex: effect.previewColorHex,
      emoji: effect.emoji,
      thumbnailUrl: effect.assetUrl,
      effectType: effect.effectType,
      requiresFaceDetection: effect.requiresFaceDetection,
      isScreenEffect: effect.isScreenEffect,
      anchorType: placement.anchorType,
      scaleFactor: placement.scaleFactor,
      offsetX: placement.offsetX,
      offsetY: placement.offsetY,
      landmarkSize: placement.landmarkSize,
      anchorLandmarks: placement.anchorLandmarks,
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
    this.filterPreviewLook,
    this.effectType,
    this.requiresFaceDetection = false,
    this.isScreenEffect = false,
    this.anchorType,
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.landmarkSize,
    this.anchorLandmarks = const [],
  });

  final String title;
  final FeCatalogPreviewMode mode;
  final String label;
  final String? previewColorHex;
  final String? engineKey;
  final String? emoji;
  final String? thumbnailUrl;
  final FilterSettingsPreviewLook? filterPreviewLook;
  final String? effectType;
  final bool requiresFaceDetection;
  final bool isScreenEffect;
  final String? anchorType;
  final double? scaleFactor;
  final double? offsetX;
  final double? offsetY;
  final double? landmarkSize;
  final List<String> anchorLandmarks;
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
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: FeCatalogItemPreview(
                  mode: mode,
                  label: label,
                  previewColorHex: previewColorHex,
                  engineKey: engineKey,
                  emoji: emoji,
                  thumbnailUrl: thumbnailUrl,
                  filterPreviewLook: filterPreviewLook,
                  effectType: effectType,
                  requiresFaceDetection: requiresFaceDetection,
                  isScreenEffect: isScreenEffect,
                  anchorType: anchorType,
                  scaleFactor: scaleFactor,
                  offsetX: offsetX,
                  offsetY: offsetY,
                  landmarkSize: landmarkSize,
                  anchorLandmarks: anchorLandmarks,
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
