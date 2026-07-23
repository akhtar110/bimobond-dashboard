import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../utils/fe_effect_emoji_display.dart';
import '../utils/fe_preview_color_utils.dart';
import 'fe_preview_scene_view.dart';

enum FeCatalogPreviewMode { filter, effect }

String feEffectRenderTypeLabel(BuildContext context, String? type) {
  final l10n = context.l10n;
  return switch (CameraEffectRenderTypeApi.fromResponse(type ?? '')) {
    CameraEffectRenderTypeApi.sticker => l10n.tOr(
      'feRenderTypeSticker',
      'Sticker',
    ),
    CameraEffectRenderTypeApi.composite => l10n.tOr(
      'feRenderTypeComposite',
      'Composite',
    ),
    CameraEffectRenderTypeApi.distortion => l10n.tOr(
      'feRenderTypeDistortion',
      'Distortion',
    ),
    _ => l10n.tOr('feRenderTypeNone', 'None'),
  };
}

/// Live preview of how a filter/effect appears on the bundled portrait scene.
class FeCatalogItemPreview extends StatelessWidget {
  const FeCatalogItemPreview({
    super.key,
    required this.mode,
    required this.label,
    this.previewColorHex,
    this.emoji,
    this.thumbnailUrl,
    this.renderType,
    this.lutUrl,
    this.lutPreviewBytes,
    this.lutPreviewFilename,
    this.colorMatrix = const [],
    this.adjustments = const {},
    this.effectAnchor = const {},
    this.effectStickers = const [],
    this.distortionPreset,
    this.stickersCount = 0,
    this.externalLoading = false,
  });

  final FeCatalogPreviewMode mode;
  final String label;
  final String? previewColorHex;
  final String? emoji;
  final String? thumbnailUrl;

  /// Filter: `matrix` | `lut`. Effect: `none` | `sticker` | `composite` | `distortion`.
  final String? renderType;
  final String? lutUrl;
  final Uint8List? lutPreviewBytes;
  final String? lutPreviewFilename;
  final List<double> colorMatrix;
  final Map<String, int> adjustments;
  final Map<String, dynamic> effectAnchor;
  final List<CameraEffectStickerLayer> effectStickers;
  final String? distortionPreset;
  final int stickersCount;
  final bool externalLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final gradient = previewGradientForHex(previewColorHex);
    final hasColor =
        previewColorHex != null && previewColorHex!.trim().isNotEmpty;
    final isEffect = mode == FeCatalogPreviewMode.effect;
    final isLutFilter =
        !isEffect && CameraFilterRenderTypeApi.isLut(renderType ?? '');
    final effectType = isEffect
        ? CameraEffectRenderTypeApi.fromResponse(renderType ?? '')
        : null;
    final trimmedEmoji = emoji?.trim();
    final emojiText = FeEffectEmojiDisplay.textEmoji(trimmedEmoji);
    final emojiImageUrl = FeEffectEmojiDisplay.resolvedImageUrl(trimmedEmoji);
    final trimmedAsset = thumbnailUrl?.trim();
    final assetImageUrl = trimmedAsset != null && trimmedAsset.isNotEmpty
        ? resolveMediaUrl(trimmedAsset)
        : null;
    final stripImageUrl = isEffect
        ? emojiImageUrl
        : isLutFilter
        ? emojiImageUrl
        : (emojiImageUrl ??
              (assetImageUrl != null &&
                      lutUrl != null &&
                      assetImageUrl == resolveMediaUrl(lutUrl)
                  ? null
                  : assetImageUrl));
    final previewKey = isEffect
        ? ValueKey(
            '$previewColorHex|$trimmedEmoji|$trimmedAsset|$effectType|'
            '$distortionPreset|$effectAnchor|$effectStickers',
          )
        : ValueKey(
            // Label/slug must NOT be in this key — text edits must not remount
            // the scene or re-apply the LUT.
            '$previewColorHex|$trimmedAsset|$lutUrl|'
            '${lutPreviewBytes?.length}|$lutPreviewFilename|'
            '$renderType|$colorMatrix|$adjustments',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feLivePreview', 'Live preview'),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 9 / 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FePreviewSceneView(
                          key: previewKey,
                          previewColorHex: isEffect ? null : previewColorHex,
                          renderType: isEffect ? null : renderType,
                          lutUrl: isEffect ? null : lutUrl,
                          lutPreviewBytes: isEffect ? null : lutPreviewBytes,
                          lutPreviewFilename:
                              isEffect ? null : lutPreviewFilename,
                          colorMatrix: isEffect ? const [] : colorMatrix,
                          adjustments: isEffect ? const {} : adjustments,
                          effectRenderType: isEffect ? renderType : null,
                          effectAssetUrl: isEffect ? assetImageUrl : null,
                          effectEmoji: isEffect ? emojiText : null,
                          effectAnchor: isEffect ? effectAnchor : const {},
                          effectStickers: isEffect ? effectStickers : const [],
                          distortionPreset: isEffect ? distortionPreset : null,
                          externalLoading: externalLoading,
                        ),
                        if (hasColor && isEffect)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  gradient.first.withValues(alpha: 0.15),
                                  gradient.last.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 10,
                          child: _PickerStripHighlight(
                            label: label,
                            gradient: gradient,
                            hasColor: hasColor,
                            emoji: emojiText,
                            emojiImageUrl: stripImageUrl,
                          ),
                        ),
                        if (isEffect &&
                            CameraEffectRenderTypeApi.isComposite(
                              effectType ?? '',
                            ) &&
                            stickersCount > 0)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'x$stickersCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (isEffect && effectType != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _EffectTypeBadge(renderType: effectType),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mode == FeCatalogPreviewMode.filter
                      ? l10n.tOr(
                          'fePreviewFilterHint',
                          'Scene preview with LUT or color matrix applied.',
                        )
                      : _effectHint(context, effectType!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _effectHint(BuildContext context, String effectType) {
    final l10n = context.l10n;
    return switch (effectType) {
      CameraEffectRenderTypeApi.sticker => l10n.tOr(
        'fePreviewEffectStickerHint',
        'Sticker positioned using anchor landmarks and scale.',
      ),
      CameraEffectRenderTypeApi.composite => l10n.tOr(
        'fePreviewEffectCompositeHint',
        'Each sticker layer is anchored independently on the face.',
      ),
      CameraEffectRenderTypeApi.distortion => l10n.tOr(
        'fePreviewEffectDistortionHint',
        'Face distortion preset applied to the preview region.',
      ),
      _ => l10n.tOr(
        'fePreviewEffectNoneHint',
        'Visual-only entry with no render pipeline.',
      ),
    };
  }
}

class _PickerStripHighlight extends StatelessWidget {
  const _PickerStripHighlight({
    required this.label,
    required this.gradient,
    required this.hasColor,
    this.emoji,
    this.emojiImageUrl,
  });

  final String label;
  final List<Color> gradient;
  final bool hasColor;
  final String? emoji;
  final String? emojiImageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasColor
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  )
                : null,
            color: hasColor ? null : scheme.surfaceContainerHighest,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: emojiImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    emojiImageUrl!,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                )
              : emoji != null && emoji!.trim().isNotEmpty
              ? Text(emoji!, style: const TextStyle(fontSize: 22))
              : null,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label.isEmpty ? '—' : label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EffectTypeBadge extends StatelessWidget {
  const _EffectTypeBadge({required this.renderType});

  final String renderType;

  @override
  Widget build(BuildContext context) {
    final label = feEffectRenderTypeLabel(context, renderType);
    final icon = switch (renderType) {
      CameraEffectRenderTypeApi.sticker => Icons.emoji_emotions_outlined,
      CameraEffectRenderTypeApi.composite => Icons.layers_outlined,
      CameraEffectRenderTypeApi.distortion =>
        Icons.face_retouching_natural_outlined,
      _ => Icons.blur_off_rounded,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
