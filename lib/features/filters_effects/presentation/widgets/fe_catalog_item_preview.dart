import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../constants/fe_preview_assets.dart';
import '../utils/fe_engine_filter_preview.dart';
import '../utils/fe_preview_color_utils.dart';

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
  });

  final FeCatalogPreviewMode mode;
  final String label;
  final String? previewColorHex;
  final String? emoji;
  final String? thumbnailUrl;
  final String? engineKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final gradient = previewGradientForHex(previewColorHex);
    final hasColor = previewColorHex != null && previewColorHex!.trim().isNotEmpty;

    return Column(
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
                        _PreviewSceneBackground(engineKey: engineKey),
                        if (hasColor)
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
                        if (mode == FeCatalogPreviewMode.effect &&
                            emoji != null &&
                            emoji!.trim().isNotEmpty)
                          Center(
                            child: Text(
                              emoji!,
                              style: const TextStyle(fontSize: 56),
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
                            emoji: mode == FeCatalogPreviewMode.effect ? emoji : null,
                          ),
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
                      : l10n.tOr(
                          'fePreviewEffectHint',
                          'How this effect tile appears in the app camera strip.',
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
  const _PreviewSceneBackground({this.engineKey});

  final String? engineKey;

  @override
  Widget build(BuildContext context) {
    return applyEnginePreviewLook(
      engineKey: engineKey,
      child: Image.asset(
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
      ),
    );
  }
}

class _PickerStripHighlight extends StatelessWidget {
  const _PickerStripHighlight({
    required this.label,
    required this.gradient,
    required this.hasColor,
    this.emoji,
  });

  final String label;
  final List<Color> gradient;
  final bool hasColor;
  final String? emoji;

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
          child: emoji != null && emoji!.trim().isNotEmpty
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
