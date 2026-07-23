import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/effect_editor_bloc.dart';
import '../bloc/effect_editor_state.dart';
import '../utils/effect_anchor_form_data.dart';
import '../utils/fe_effect_emoji_display.dart';
import 'effect_anchor_fields_form.dart';
import 'fe_catalog_item_preview.dart';
import 'fe_effect_form_fields.dart';

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
      return _EffectEditorPreviewContent(state: state!, embedded: embedded);
    }

    return BlocSelector<
      EffectEditorBloc,
      EffectEditorState,
      EffectEditorReady?
    >(
      selector: (current) => current is EffectEditorReady ? current : null,
      builder: (context, ready) {
        if (ready == null) return const SizedBox.shrink();
        return _EffectEditorPreviewContent(state: ready, embedded: embedded);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final form = state.form;
    final isComposite = CameraEffectRenderTypeApi.isComposite(form.renderType);
    final isSticker = CameraEffectRenderTypeApi.isSticker(form.renderType);
    final isDistortion = CameraEffectRenderTypeApi.isDistortion(form.renderType);
    final assetImageUrl = FeEffectEmojiDisplay.resolvedImageUrl(form.assetUrl);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          Text(
            l10n.tOr('feEffectSectionPreview', 'Live preview'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
              renderType: form.renderType,
              effectAnchor: form.anchor.toMap(),
              effectStickers: form.stickers,
              distortionPreset: form.distortionPreset,
              stickersCount: form.stickers.length,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.tOr('feEffectSummary', 'Summary'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _SummaryCard(
          children: [
            _SummaryRow(
              label: l10n.tOr('feFieldRenderType', 'Render type'),
              value: feEffectRenderTypeLabel(context, form.renderType),
            ),
            _SummaryRow(
              label: l10n.tOr('feFieldSlug', 'Slug'),
              value: form.slug.trim().isEmpty ? '—' : form.slug.trim(),
            ),
            if (isDistortion)
              _SummaryRow(
                label: l10n.tOr('feFieldDistortionPreset', 'Distortion preset'),
                value: (form.distortionPreset?.trim().isNotEmpty ?? false)
                    ? feDistortionPresetLabel(context, form.distortionPreset!)
                    : '—',
              ),
            if (isComposite)
              _SummaryRow(
                label: l10n.tOr('feStickerLayers', 'Sticker layers'),
                value: '${form.stickers.length}',
              ),
            if (isSticker)
              _SummaryRow(
                label: l10n.tOr('feFieldAnchor', 'Anchor'),
                value: form.anchor.isEmpty
                    ? l10n.t('no')
                    : _formatAnchorSummary(context, form.anchor),
              ),
            if (state.isEditing && state.hasUnsavedChanges)
              _SummaryRow(
                label: l10n.tOr('feFilterCurrent', 'Modified'),
                value: l10n.t('yes'),
              ),
          ],
        ),
        if (assetImageUrl != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.tOr('feAssetPreview', 'Asset preview'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
                  assetImageUrl,
                  key: ValueKey(form.assetUrl!.trim()),
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Text(
                    l10n.tOr('feAssetLoadFailed', 'Could not load asset'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.error),
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
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }
}

String _formatAnchorSummary(BuildContext context, EffectAnchorFormData anchor) {
  final l10n = context.l10n;
  final parts = <String>[];
  final pinSummary = effectAnchorPinSummary(context, anchor);
  if (pinSummary.isNotEmpty) parts.add(pinSummary);

  if (anchor.parsedLeftLandmark != null ||
      anchor.parsedRightLandmark != null ||
      anchor.parsedAnchorLandmark != null) {
    parts.add(effectAnchorLandmarkSummary(context, anchor));
  }

  if (anchor.parsedWidthScreenMult != null) {
    parts.add('×${anchor.parsedWidthScreenMult!.toStringAsFixed(1)}');
  }

  return parts.isEmpty ? l10n.t('yes') : parts.join(' · ');
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
