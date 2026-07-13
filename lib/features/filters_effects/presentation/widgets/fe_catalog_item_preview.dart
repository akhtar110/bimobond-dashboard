import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../constants/fe_preview_assets.dart';
import '../utils/fe_effect_emoji_display.dart';
import '../utils/fe_engine_filter_preview.dart';
import '../utils/fe_effect_placement_preview.dart';
import '../utils/fe_filter_settings_preview.dart';
import '../utils/fe_preview_color_utils.dart';
import '../../domain/entities/filters_effects_entities.dart';

enum FeCatalogPreviewMode { filter, effect }

/// Live preview of how a filter/effect appears in the mobile picker strip.
class FeCatalogItemPreview extends StatelessWidget {
  const FeCatalogItemPreview({
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
    this.filterPreviewLook,
    this.anchorType,
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.landmarkSize,
    this.anchorLandmarks = const [],
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
  final FilterSettingsPreviewLook? filterPreviewLook;
  final String? anchorType;
  final double? scaleFactor;
  final double? offsetX;
  final double? offsetY;
  final double? landmarkSize;
  final List<String> anchorLandmarks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final gradient = previewGradientForHex(previewColorHex);
    final hasColor = previewColorHex != null && previewColorHex!.trim().isNotEmpty;
    final isEffect = mode == FeCatalogPreviewMode.effect;
    final isScreenOverlay = isEffect &&
        CameraEffectTypeApi.isScreenOverlay(effectType ?? CameraEffectTypeApi.faceAr);
    final trimmedEmoji = emoji?.trim();
    final emojiText = FeEffectEmojiDisplay.textEmoji(trimmedEmoji);
    final emojiImageUrl = FeEffectEmojiDisplay.resolvedImageUrl(trimmedEmoji);
    final trimmedAsset = thumbnailUrl?.trim();
    final assetImageUrl = trimmedAsset != null && trimmedAsset.isNotEmpty
        ? resolveMediaUrl(trimmedAsset)
        : null;
    final overlayImageUrl = emojiImageUrl ?? assetImageUrl;
    final placementLayout = isEffect && !isScreenOverlay
        ? EffectPlacementPreviewLayout.forPlacement(
            anchorType: anchorType,
            scaleFactor: scaleFactor,
            offsetX: offsetX,
            offsetY: offsetY,
            landmarkSize: landmarkSize,
            anchorLandmarks: anchorLandmarks,
          )
        : null;
    final previewKey = isEffect
        ? ValueKey(
            '$previewColorHex|$trimmedEmoji|$trimmedAsset|$effectType|'
            '$isScreenOverlay|$anchorType|$scaleFactor|$offsetX|$offsetY|'
            '$landmarkSize|${anchorLandmarks.join(',')}',
          )
        : ValueKey(
            '$previewColorHex|$trimmedAsset|$engineKey|$label|'
            '${filterPreviewLook?.blurSigma}|'
            '${filterPreviewLook?.vignette}|'
            '${filterPreviewLook?.colorMatrix?.join(',')}',
          );

    return Column(
      key: previewKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feLivePreview', 'Live preview'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                        _PreviewSceneBackground(
                          engineKey: engineKey,
                          filterPreviewLook: filterPreviewLook,
                          previewColorHex: isEffect ? null : previewColorHex,
                        ),
                        if (hasColor && isEffect)
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isScreenOverlay
                                    ? [
                                        gradient.first.withValues(alpha: 0.35),
                                        gradient.last.withValues(alpha: 0.72),
                                      ]
                                    : [
                                        gradient.first.withValues(alpha: 0.15),
                                        gradient.last.withValues(alpha: 0.55),
                                      ],
                              ),
                            ),
                          ),
                        if (isEffect && !isScreenOverlay)
                          const _FaceArGuide(),
                        if (isEffect)
                          _EffectOverlayLayer(
                            key: ValueKey(
                              'overlay-$trimmedEmoji-$trimmedAsset-'
                              '$isScreenOverlay-$anchorType-$scaleFactor-'
                              '$offsetX-$offsetY',
                            ),
                            isScreenOverlay: isScreenOverlay,
                            emoji: emojiText,
                            assetUrl: overlayImageUrl,
                            requiresFaceDetection: requiresFaceDetection,
                            layout: placementLayout,
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
                            emojiImageUrl: isEffect
                                ? emojiImageUrl
                                : (emojiImageUrl ?? assetImageUrl),
                          ),
                        ),
                        if (isEffect)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _EffectTypeBadge(isScreenOverlay: isScreenOverlay),
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
                          'How this filter tile appears in the app camera strip.',
                        )
                      : isScreenOverlay
                          ? l10n.tOr(
                              'fePreviewEffectScreenOverlayHint',
                              'Full-screen overlay covering the camera preview.',
                            )
                          : l10n.tOr(
                              'fePreviewEffectFaceArHint',
                              'Face AR effect anchored on the detected face.',
                            ),
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
}

class _PreviewSceneBackground extends StatelessWidget {
  const _PreviewSceneBackground({
    this.engineKey,
    this.filterPreviewLook,
    this.previewColorHex,
  });

  final String? engineKey;
  final FilterSettingsPreviewLook? filterPreviewLook;
  final String? previewColorHex;

  @override
  Widget build(BuildContext context) {
    Widget scene = Image.asset(
      FePreviewAssets.previewScene,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
            ),
          ),
          child: Center(
            child: Icon(Icons.person_rounded, size: 72, color: Colors.white70),
          ),
        );
      },
    );

    // Mobile pipeline: engine look → color/settings/beauty overlays.
    scene = applyEnginePreviewLook(engineKey: engineKey, child: scene);
    final look = filterPreviewLook;
    if (look != null) {
      scene = applyFilterSettingsPreviewLook(child: scene, look: look);
    }

    final hex = previewColorHex?.trim();
    if (hex != null && hex.isNotEmpty) {
      final gradient = previewGradientForHex(hex);
      scene = Stack(
        fit: StackFit.expand,
        children: [
          scene,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  gradient.first.withValues(alpha: 0.22),
                  gradient.last.withValues(alpha: 0.58),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return scene;
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
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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

class _FaceArGuide extends StatelessWidget {
  const _FaceArGuide();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.22),
      child: Container(
        width: 92,
        height: 118,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.75),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _EffectOverlayLayer extends StatelessWidget {
  const _EffectOverlayLayer({
    super.key,
    required this.isScreenOverlay,
    this.emoji,
    this.assetUrl,
    this.requiresFaceDetection = false,
    this.layout,
  });

  final bool isScreenOverlay;
  final String? emoji;
  final String? assetUrl;
  final bool requiresFaceDetection;
  final EffectPlacementPreviewLayout? layout;

  Widget _emojiWidget(double fontSize) {
    return Text(
      emoji!,
      style: TextStyle(
        fontSize: fontSize,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }

  Widget _assetWidget(double size, {BoxFit fit = BoxFit.contain}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        assetUrl!,
        key: ValueKey(assetUrl),
        fit: fit,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _placedContent({
    required Alignment alignment,
    required double sizeFactor,
    bool coverFace = false,
  }) {
    final hasEmoji = emoji != null && emoji!.isNotEmpty;
    final hasAsset = assetUrl != null && assetUrl!.isNotEmpty;
    if (!hasEmoji && !hasAsset) return const SizedBox.shrink();

    final emojiSize = (coverFace ? 56.0 : 48.0) * sizeFactor;
    final assetSize = (coverFace ? 110.0 : 72.0) * sizeFactor;

    return Align(
      alignment: alignment,
      child: hasAsset
          ? _assetWidget(assetSize, fit: coverFace ? BoxFit.cover : BoxFit.contain)
          : _emojiWidget(emojiSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEmoji = emoji != null && emoji!.isNotEmpty;
    final hasAsset = assetUrl != null && assetUrl!.isNotEmpty;

    if (isScreenOverlay) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
          if (hasAsset)
            Positioned.fill(
              child: Opacity(
                opacity: 0.85,
                child: Image.network(
                  assetUrl!,
                  key: ValueKey(assetUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          if (hasEmoji)
            Center(
              child: _emojiWidget(hasAsset ? 64 : 78),
            ),
          if (!hasEmoji && !hasAsset)
            Center(
              child: Icon(
                Icons.fullscreen_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
        ],
      );
    }

    final resolved = layout ??
        const EffectPlacementPreviewLayout(
          primaryAlignment: Alignment(0, -0.22),
          sizeFactor: 0.85,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        _placedContent(
          alignment: resolved.primaryAlignment,
          sizeFactor: resolved.sizeFactor,
          coverFace: resolved.coverFace,
        ),
        if (resolved.secondaryAlignment != null)
          _placedContent(
            alignment: resolved.secondaryAlignment!,
            sizeFactor: resolved.sizeFactor,
            coverFace: resolved.coverFace,
          ),
        if (requiresFaceDetection)
          Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.face_retouching_natural_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
      ],
    );
  }
}

class _EffectTypeBadge extends StatelessWidget {
  const _EffectTypeBadge({required this.isScreenOverlay});

  final bool isScreenOverlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = isScreenOverlay
        ? l10n.tOr('feEffectTypeScreenOverlay', 'Screen overlay')
        : l10n.tOr('feEffectTypeFaceAr', 'Face AR');

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
            Icon(
              isScreenOverlay
                  ? Icons.fullscreen_rounded
                  : Icons.face_retouching_natural_outlined,
              size: 14,
              color: Colors.white,
            ),
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
