import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/effect_editor_bloc.dart';
import '../bloc/effect_editor_event.dart';
import '../bloc/effect_editor_state.dart';
import '../utils/effect_anchor_form_data.dart';
import 'effect_anchor_fields_form.dart';
import 'fe_editor_synced_text_field.dart';
import 'fe_effect_form_fields.dart';

/// Render-type specific composition editor: structured anchor for stickers,
/// sticker layers for composites, and preset info for distortions.
class EffectEditorCompositionSection extends StatelessWidget {
  const EffectEditorCompositionSection({
    super.key,
    required this.state,
    this.embedded = false,
  });

  final EffectEditorReady state;
  final bool embedded;

  String? _fieldError(BuildContext context, String key) {
    final message = state.fieldErrors[key];
    if (message == null) return null;
    if (message.startsWith('fe')) {
      return context.l10n.tOr(message, message);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final form = state.form;
    final renderType = CameraEffectRenderTypeApi.fromResponse(form.renderType);

    final children = <Widget>[
      if (!embedded)
        Text(
          l10n.tOr('feEffectSectionComposition', 'Effect composition'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      if (!embedded) const SizedBox(height: 12),
    ];

    switch (renderType) {
      case CameraEffectRenderTypeApi.sticker:
        children.addAll([
          _InfoCard(
            icon: Icons.emoji_emotions_outlined,
            text: l10n.tOr(
              'feStickerHint',
              'A sticker effect renders the asset at the face anchor '
                  'defined by the pins, landmarks, and scale below.',
            ),
          ),
          const SizedBox(height: 12),
          EffectAnchorFieldsForm(
            anchor: form.anchor,
            errorText:
                _fieldError(context, 'anchor') ??
                _fieldError(context, 'anchorJson'),
            onChanged: (anchor) => context.read<EffectEditorBloc>().add(
              EffectAnchorChanged(anchor),
            ),
          ),
        ]);
      case CameraEffectRenderTypeApi.composite:
        children.addAll([
          _InfoCard(
            icon: Icons.layers_outlined,
            text: l10n.tOr(
              'feCompositeHint',
              'A composite effect stacks several sticker layers, each with '
                  'its own asset and face anchor settings.',
            ),
          ),
          if (_fieldError(context, 'stickers') != null) ...[
            const SizedBox(height: 8),
            Text(
              _fieldError(context, 'stickers')!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          const SizedBox(height: 12),
          _StickerLayersEditor(stickers: form.stickers),
        ]);
      case CameraEffectRenderTypeApi.distortion:
        children.addAll([
          _InfoCard(
            icon: Icons.face_retouching_natural_outlined,
            text: l10n.tOr(
              'feDistortionHint',
              'A distortion effect warps the face using the selected preset. '
                  'Choose the preset in the basic information section.',
            ),
          ),
          const SizedBox(height: 12),
          _DistortionSummary(preset: form.distortionPreset),
        ]);
      default:
        children.add(
          _InfoCard(
            icon: Icons.info_outline_rounded,
            text: l10n.tOr(
              'feRenderTypeNoneHint',
              'This effect has no on-camera overlay. Only the metadata and '
                  'optional asset are stored.',
            ),
          ),
        );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
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

class _StickerLayersEditor extends StatelessWidget {
  const _StickerLayersEditor({required this.stickers});

  final List<CameraEffectStickerLayer> stickers;

  void _update(BuildContext context, List<CameraEffectStickerLayer> next) {
    context.read<EffectEditorBloc>().add(EffectStickersChanged(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stickers.isEmpty)
          Text(
            l10n.tOr('feNoStickerLayers', 'No sticker layers yet.'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          for (var i = 0; i < stickers.length; i++)
            _StickerLayerCard(
              key: ValueKey('sticker-layer-$i'),
              index: i,
              layer: stickers[i],
              onChanged: (layer) {
                final next = List<CameraEffectStickerLayer>.from(stickers);
                next[i] = layer;
                _update(context, next);
              },
              onRemoved: () {
                final next = List<CameraEffectStickerLayer>.from(stickers)
                  ..removeAt(i);
                _update(context, next);
              },
            ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: () => _update(context, [
              ...stickers,
              const CameraEffectStickerLayer(),
            ]),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.tOr('feAddStickerLayer', 'Add sticker layer')),
          ),
        ),
      ],
    );
  }
}

class _StickerLayerCard extends StatelessWidget {
  const _StickerLayerCard({
    super.key,
    required this.index,
    required this.layer,
    required this.onChanged,
    required this.onRemoved,
  });

  final int index;
  final CameraEffectStickerLayer layer;
  final ValueChanged<CameraEffectStickerLayer> onChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final anchor = EffectAnchorFormData.fromMap(layer.anchor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n
                          .tOr('feStickerLayer', 'Sticker layer')
                          .replaceAll('{index}', '${index + 1}'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.t('remove'),
                    visualDensity: VisualDensity.compact,
                    onPressed: onRemoved,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FeEditorSyncedTextField(
                value: layer.assetUrl ?? '',
                decoration: InputDecoration(
                  labelText: l10n.tOr('feFieldStickerAssetUrl', 'Asset URL'),
                  isDense: true,
                ),
                onChanged: (value) => onChanged(
                  CameraEffectStickerLayer(
                    assetUrl: value.trim().isEmpty ? null : value.trim(),
                    assetAsset: layer.assetAsset,
                    anchor: layer.anchor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FeEditorSyncedTextField(
                value: layer.assetAsset ?? '',
                decoration: InputDecoration(
                  labelText: l10n.tOr(
                    'feFieldStickerAssetAsset',
                    'Bundled asset',
                  ),
                  isDense: true,
                ),
                onChanged: (value) => onChanged(
                  CameraEffectStickerLayer(
                    assetUrl: layer.assetUrl,
                    assetAsset: value.trim().isEmpty ? null : value.trim(),
                    anchor: layer.anchor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              EffectAnchorFieldsForm(
                dense: true,
                showPresetButton: false,
                anchor: anchor,
                onChanged: (next) => onChanged(
                  CameraEffectStickerLayer(
                    assetUrl: layer.assetUrl,
                    assetAsset: layer.assetAsset,
                    anchor: next.toMap(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistortionSummary extends StatelessWidget {
  const _DistortionSummary({required this.preset});

  final String? preset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasPreset = preset != null && preset!.trim().isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              hasPreset
                  ? Icons.auto_fix_high_rounded
                  : Icons.warning_amber_rounded,
              size: 20,
              color: hasPreset ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPreset
                    ? feDistortionPresetLabel(context, preset!)
                    : l10n.tOr(
                        'feDistortionPresetRequired',
                        'Select a distortion preset to save this effect.',
                      ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: hasPreset ? scheme.onSurface : scheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
