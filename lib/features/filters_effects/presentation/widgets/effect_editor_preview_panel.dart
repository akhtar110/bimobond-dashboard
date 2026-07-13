import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/effect_editor_bloc.dart';
import '../bloc/effect_editor_state.dart';
import '../utils/effect_placement_visibility.dart';
import '../utils/fe_effect_emoji_display.dart';
import 'fe_catalog_item_preview.dart';

class EffectEditorPreviewPanel extends StatelessWidget {
  const EffectEditorPreviewPanel({
    super.key,
    this.state,
    this.embedded = false,
  });

  /// When null, reads live state from [EffectEditorBloc] (preferred in dialog).
  final EffectEditorReady? state;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (state != null) {
      return _EffectEditorPreviewContent(
        state: state!,
        embedded: embedded,
      );
    }

    return BlocSelector<EffectEditorBloc, EffectEditorState, EffectEditorReady?>(
      selector: (current) => current is EffectEditorReady ? current : null,
      builder: (context, ready) {
        if (ready == null) return const SizedBox.shrink();
        return _EffectEditorPreviewContent(
          state: ready,
          embedded: embedded,
        );
      },
    );
  }
}

class _EffectEditorPreviewContent extends StatelessWidget {
  const _EffectEditorPreviewContent({
    required this.state,
    required this.embedded,
  });

  final EffectEditorReady state;
  final bool embedded;

  String _anchorLabel(String? key) {
    if (key == null || key.isEmpty) return '—';
    final fromSchema = state.schema.anchorTypeFor(key);
    if (fromSchema != null && fromSchema.label.trim().isNotEmpty) {
      return fromSchema.label;
    }
    return key;
  }

  String _landmarkLabels(List<String> keys) {
    if (keys.isEmpty) return '—';
    return keys.map((key) {
      for (final landmark in state.schema.landmarks) {
        if (landmark.key == key) {
          return landmark.label.trim().isNotEmpty ? landmark.label : key;
        }
      }
      return key;
    }).join(', ');
  }

  String _effectTypeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (CameraEffectTypeApi.normalize(type)) {
      CameraEffectTypeApi.screenOverlay =>
        l10n.tOr('feEffectTypeScreenOverlay', 'Screen overlay'),
      _ => l10n.tOr('feEffectTypeFaceAr', 'Face AR'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final form = state.form;
    final placement = form.placement;
    final anchorType = placement.anchorType;
    final showPlacement = EffectPlacementVisibility.placementEnabled(
      requiresFaceDetection: form.requiresFaceDetection,
      isScreenEffect: form.isScreenEffect,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          Text(
            l10n.tOr('feEffectSectionPreview', 'Live preview'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (!embedded) const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: FeCatalogItemPreview(
              mode: FeCatalogPreviewMode.effect,
              label: form.displayLabel,
              previewColorHex: form.previewColorHex,
              emoji: form.emoji,
              thumbnailUrl: form.assetUrl,
              effectType: form.effectType,
              requiresFaceDetection: form.requiresFaceDetection,
              isScreenEffect: form.isScreenEffect,
              anchorType: placement.anchorType,
              scaleFactor: placement.scaleFactor,
              offsetX: placement.offsetX,
              offsetY: placement.offsetY,
              landmarkSize: placement.landmarkSize,
              anchorLandmarks: placement.anchorLandmarks,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.tOr('feEffectPlacementSummary', 'Placement summary'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        _SummaryCard(
          children: [
            _SummaryRow(
              label: l10n.tOr('feFieldEffectType', 'Effect type'),
              value: _effectTypeLabel(context, form.effectType),
            ),
            _SummaryRow(
              label: l10n.tOr('feFieldAnchorType', 'Anchor type'),
              value: showPlacement
                  ? _anchorLabel(anchorType)
                  : l10n.tOr('fePlacementNotApplicable', 'N/A'),
            ),
            _SummaryRow(
              label: l10n.tOr('feFlagFaceDetection', 'Face detection'),
              value: form.requiresFaceDetection
                  ? l10n.t('yes')
                  : l10n.t('no'),
            ),
            _SummaryRow(
              label: l10n.tOr('feFlagScreenEffect', 'Screen effect'),
              value: form.isScreenEffect
                  ? l10n.t('yes')
                  : l10n.t('no'),
            ),
            if (showPlacement &&
                (EffectPlacementVisibility.showLandmarkMultiSelect(
                      anchorType,
                    ) ||
                    EffectPlacementVisibility.showLandmarkSingleSelect(
                      anchorType,
                    )))
              _SummaryRow(
                label: l10n.tOr('feFieldAnchorLandmarks', 'Anchor landmarks'),
                value: _landmarkLabels(placement.anchorLandmarks),
              ),
            if (showPlacement &&
                EffectPlacementVisibility.showScaleFactor(anchorType) &&
                placement.scaleFactor != null)
              _SummaryRow(
                label: l10n.tOr('feFieldScaleFactor', 'Scale factor'),
                value: placement.scaleFactor!.toStringAsFixed(2),
              ),
            if (showPlacement &&
                EffectPlacementVisibility.showOffsetX(anchorType) &&
                placement.offsetX != null)
              _SummaryRow(
                label: l10n.tOr('feFieldOffsetX', 'Offset X'),
                value: placement.offsetX!.toStringAsFixed(2),
              ),
            if (showPlacement &&
                EffectPlacementVisibility.showOffsetY(anchorType) &&
                placement.offsetY != null)
              _SummaryRow(
                label: l10n.tOr('feFieldOffsetY', 'Offset Y'),
                value: placement.offsetY!.toStringAsFixed(2),
              ),
            if (showPlacement &&
                EffectPlacementVisibility.showLandmarkSize(anchorType) &&
                placement.landmarkSize != null)
              _SummaryRow(
                label: l10n.tOr('feFieldLandmarkSize', 'Landmark size'),
                value: placement.landmarkSize!.toStringAsFixed(2),
              ),
          ],
        ),
        if (FeEffectEmojiDisplay.resolvedImageUrl(form.assetUrl) != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.tOr('feAssetPreview', 'Asset preview'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Image.network(
                  FeEffectEmojiDisplay.resolvedImageUrl(form.assetUrl)!,
                  key: ValueKey(form.assetUrl!.trim()),
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    l10n.tOr('feAssetLoadFailed', 'Could not load asset'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    if (embedded) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
