import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/effect_editor_bloc.dart';
import '../bloc/effect_editor_event.dart';
import '../bloc/effect_editor_state.dart';
import '../utils/effect_asset_picker.dart';
import '../utils/fe_effect_emoji_display.dart';
import 'fe_editor_synced_text_field.dart';
import 'fe_effect_form_fields.dart';
import 'fe_filter_form_fields.dart';
import 'fe_form_preview_panel.dart';

class EffectEditorBasicSection extends StatelessWidget {
  const EffectEditorBasicSection({
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
    final bloc = context.read<EffectEditorBloc>();
    final isScreenOverlay =
        CameraEffectTypeApi.isScreenOverlay(form.effectType);

    final fields = FeFilterFormTheme(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded)
            Text(
              l10n.tOr('feEffectSectionBasic', 'Basic information'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          if (!embedded) const SizedBox(height: 12),
          FeFormColorPicker(
            selectedHex: form.previewColorHex,
            onSelected: (hex) =>
                bloc.add(EffectPreviewColorChanged(hex)),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: form.previewColorHex ?? '',
            decoration: InputDecoration(
              labelText: l10n.tOr('fePreviewColorHexManual', 'Preview color hex'),
              hintText: '#FF6B6B',
              errorText: _fieldError(context, 'previewColorHex'),
            ),
            onChanged: (value) => bloc.add(
              EffectPreviewColorChanged(
                value.trim().isEmpty ? null : value,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FeEditorSyncedTextField(
            value: form.slug,
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldSlug', 'Slug'),
              errorText: _fieldError(context, 'slug'),
            ),
            onChanged: (value) =>
                bloc.add(EffectBasicFieldChanged(slug: value)),
          ),
          const SizedBox(height: 10),
          FeEffectTypeField(
            value: form.effectType,
            onChanged: (value) =>
                bloc.add(EffectBasicFieldChanged(effectType: value)),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: form.labelKey,
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldLabelKey', 'Label key'),
              errorText: _fieldError(context, 'labelKey'),
            ),
            onChanged: (value) =>
                bloc.add(EffectBasicFieldChanged(labelKey: value)),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: FeEffectEmojiDisplay.textEmoji(form.emoji) ?? '',
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldEmoji', 'Emoji'),
              hintText: l10n.tOr('feFieldEmojiHint', 'Unicode icon (max 16 chars)'),
              errorText: _fieldError(context, 'emoji'),
            ),
            onChanged: (value) => bloc.add(
              EffectBasicFieldChanged(
                emoji: value,
                clearEmoji: value.trim().isEmpty,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _EffectAssetUploadField(state: state),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: '${form.sortOrder}',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldSortOrder', 'Sort order'),
            ),
            onChanged: (value) => bloc.add(
              EffectBasicFieldChanged(
                sortOrder: int.tryParse(value.trim()) ?? 0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.tOr('feFlagFaceDetection', 'Face detection')),
            value: form.requiresFaceDetection,
            onChanged: isScreenOverlay
                ? null
                : (value) => bloc.add(
                      EffectBasicFieldChanged(requiresFaceDetection: value),
                    ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.tOr('feFlagScreenEffect', 'Screen effect')),
            value: form.isScreenEffect,
            onChanged: !isScreenOverlay
                ? null
                : (value) => bloc.add(
                      EffectBasicFieldChanged(isScreenEffect: value),
                    ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.tOr('feActive', 'Active')),
            value: form.isActive,
            onChanged: (value) =>
                bloc.add(EffectBasicFieldChanged(isActive: value)),
          ),
        ],
      ),
    );

    if (embedded) return fields;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: fields,
      ),
    );
  }
}

class _EffectAssetUploadField extends StatelessWidget {
  const _EffectAssetUploadField({required this.state});

  final EffectEditorReady state;

  Future<void> _pickAndUpload(BuildContext context) async {
    final picked = await pickEffectAsset();
    if (!context.mounted || picked == null) return;
    context.read<EffectEditorBloc>().add(
          UploadEffectAssetEvent(
            bytes: picked.bytes,
            filename: picked.name,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<EffectEditorBloc>();
    final form = state.form;
    final assetImageUrl =
        FeEffectEmojiDisplay.resolvedImageUrl(form.assetUrl);
    final hasAsset = assetImageUrl != null;
    final isBusy = state.isUploadingAsset || state.isSaving;
    final error = state.fieldErrors['assetUrl'];
    final errorText = error == null
        ? null
        : (error.startsWith('fe')
            ? l10n.tOr(error, error)
            : error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feFieldAssetUrl', 'Asset'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => _pickAndUpload(context),
          icon: state.isUploadingAsset
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            state.isUploadingAsset
                ? l10n.t('uploadingMedia')
                : hasAsset
                    ? l10n.t('changeImage')
                    : l10n.t('uploadImage'),
          ),
        ),
        if (hasAsset) ...[
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      assetImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.assetFileName != null)
                          Text(
                            state.assetFileName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        Text(
                          form.assetUrl!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => bloc.add(
                              const EffectBasicFieldChanged(clearAssetUrl: true),
                            ),
                    child: Text(l10n.t('remove')),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
          ),
        ],
      ],
    );
  }
}
