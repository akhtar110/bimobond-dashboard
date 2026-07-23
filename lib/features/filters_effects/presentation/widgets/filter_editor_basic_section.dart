import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../bloc/filter_editor_bloc.dart';
import '../bloc/filter_editor_event.dart';
import '../bloc/filter_editor_state.dart';
import '../utils/effect_asset_picker.dart';
import '../utils/filter_lut_picker.dart';
import 'filter_editor_matrix_section.dart';
import 'fe_editor_synced_text_field.dart';
import 'fe_filter_form_fields.dart';
import 'fe_form_preview_panel.dart';

class FilterEditorBasicSection extends StatelessWidget {
  const FilterEditorBasicSection({
    super.key,
    required this.state,
    this.embedded = false,
  });

  final FilterEditorReady state;
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
    final bloc = context.read<FilterEditorBloc>();

    final fields = FeFilterFormTheme(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded)
            Text(
              l10n.tOr('feFilterSectionBasic', 'Basic information'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          if (!embedded) const SizedBox(height: 12),
          FeFilterRenderTypeField(
            value: form.renderType,
            onChanged: (value) =>
                bloc.add(FilterBasicFieldChanged(renderType: value)),
          ),
          const SizedBox(height: 10),
          FeFormColorPicker(
            selectedHex: form.previewColorHex,
            allowClear: true,
            onSelected: (hex) => bloc.add(FilterPreviewColorChanged(hex)),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: form.previewColorHex ?? '',
            decoration: InputDecoration(
              labelText: l10n.tOr('fePreviewColorHexManual', 'Manual hex'),
              hintText: '#FF6B6B',
              errorText: _fieldError(context, 'previewColorHex'),
            ),
            onChanged: (value) => bloc.add(
              FilterPreviewColorChanged(value.trim().isEmpty ? null : value),
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
                bloc.add(FilterBasicFieldChanged(slug: value)),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: form.label,
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldLabel', 'Label'),
              errorText: _fieldError(context, 'label'),
            ),
            onChanged: (value) =>
                bloc.add(FilterBasicFieldChanged(label: value)),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: form.labelKey ?? '',
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldLabelKey', 'Label key'),
              errorText: _fieldError(context, 'labelKey'),
            ),
            onChanged: (value) => bloc.add(
              FilterBasicFieldChanged(
                labelKey: value,
                clearLabelKey: value.trim().isEmpty,
              ),
            ),
          ),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: form.emoji ?? '',
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldEmoji', 'Emoji'),
              hintText: l10n.tOr(
                'feFieldEmojiHint',
                'Unicode icon (max 16 chars)',
              ),
              errorText: _fieldError(context, 'emoji'),
            ),
            onChanged: (value) => bloc.add(
              FilterBasicFieldChanged(
                emoji: value,
                clearEmoji: value.trim().isEmpty,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (form.isLut) ...[
            _FilterLutUploadField(state: state),
            const SizedBox(height: 10),
            FeEditorSyncedTextField(
              value: form.lutAsset ?? '',
              decoration: InputDecoration(
                labelText: l10n.tOr('feFieldLutAsset', 'LUT asset'),
                hintText: l10n.tOr(
                  'feFieldLutAssetHint',
                  'Bundled asset path on the mobile client',
                ),
                errorText:
                    _fieldError(context, 'lutAsset') ??
                    _fieldError(context, 'lut'),
              ),
              onChanged: (value) => bloc.add(
                FilterBasicFieldChanged(
                  lutAsset: value,
                  clearLutAsset: value.trim().isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (form.isMatrix && state.settingsSchema != null) ...[
            FilterEditorMatrixSection(
              schema: state.settingsSchema!,
              adjustments: form.adjustments,
              colorMatrix: form.colorMatrix,
              onAdjustmentChanged: (key, value) =>
                  bloc.add(FilterAdjustmentChanged(key, value)),
            ),
            const SizedBox(height: 10),
          ],
          _FilterThumbnailUploadField(state: state),
          const SizedBox(height: 10),
          FeEditorSyncedTextField(
            value: '${form.sortOrder}',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.tOr('feFieldSortOrder', 'Sort order'),
            ),
            onChanged: (value) => bloc.add(
              FilterBasicFieldChanged(
                sortOrder: int.tryParse(value.trim()) ?? 0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            title: Text(l10n.tOr('feActive', 'Active')),
            value: form.isActive,
            onChanged: (value) =>
                bloc.add(FilterBasicFieldChanged(isActive: value)),
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
      child: Padding(padding: const EdgeInsets.all(16), child: fields),
    );
  }
}

class _FilterLutUploadField extends StatelessWidget {
  const _FilterLutUploadField({required this.state});

  final FilterEditorReady state;

  Future<void> _pickAndUpload(BuildContext context) async {
    final picked = await pickFilterLutFile();
    if (!context.mounted || picked == null) return;
    context.read<FilterEditorBloc>().add(
      UploadFilterLutEvent(bytes: picked.bytes, filename: picked.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<FilterEditorBloc>();
    final form = state.form;
    final trimmed = form.lutUrl?.trim();
    final previewUrl = trimmed != null && trimmed.isNotEmpty
        ? resolveMediaUrl(trimmed)
        : null;
    final hasLut = previewUrl != null && previewUrl.isNotEmpty;
    final isBusy =
        state.isUploadingLut || state.isUploadingThumbnail || state.isSaving;
    final error = state.fieldErrors['lutUrl'] ?? state.fieldErrors['lut'];
    final errorText = error == null
        ? null
        : (error.startsWith('fe') ? l10n.tOr(error, error) : error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feFieldLutUrl', 'LUT file'),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'feFieldLutUploadHint',
            'Upload a Lightroom/Photoshop .cube file or a 512×512 PNG LUT. '
            'The server converts .cube files and fills lutUrl automatically.',
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => _pickAndUpload(context),
          icon: state.isUploadingLut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            state.isUploadingLut
                ? l10n.t('uploadingMedia')
                : hasLut
                ? l10n.tOr('feChangeLut', 'Change LUT file')
                : l10n.tOr('feUploadLut', 'Upload LUT (.cube or PNG)'),
          ),
        ),
        if (hasLut) ...[
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
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Icon(
                        Icons.gradient_outlined,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.lutFileName != null)
                          Text(
                            state.lutFileName!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        Text(
                          form.lutUrl!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                            const FilterBasicFieldChanged(
                              clearLutUrl: true,
                              clearLutAsset: true,
                            ),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _FilterThumbnailUploadField extends StatelessWidget {
  const _FilterThumbnailUploadField({required this.state});

  final FilterEditorReady state;

  Future<void> _pickAndUpload(BuildContext context) async {
    final picked = await pickEffectAsset();
    if (!context.mounted || picked == null) return;
    context.read<FilterEditorBloc>().add(
      UploadFilterThumbnailEvent(bytes: picked.bytes, filename: picked.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<FilterEditorBloc>();
    final form = state.form;
    final trimmed = form.thumbnailUrl?.trim();
    final previewUrl = trimmed != null && trimmed.isNotEmpty
        ? resolveMediaUrl(trimmed)
        : null;
    final hasThumbnail = previewUrl != null && previewUrl.isNotEmpty;
    final isBusy = state.isUploadingThumbnail || state.isSaving;
    final error = state.fieldErrors['thumbnailUrl'];
    final errorText = error == null
        ? null
        : (error.startsWith('fe') ? l10n.tOr(error, error) : error);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feFieldThumbnailUrl', 'Thumbnail'),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isBusy ? null : () => _pickAndUpload(context),
          icon: state.isUploadingThumbnail
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(
            state.isUploadingThumbnail
                ? l10n.t('uploadingMedia')
                : hasThumbnail
                ? l10n.t('changeImage')
                : l10n.t('uploadImage'),
          ),
        ),
        if (hasThumbnail) ...[
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
                      previewUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.thumbnailFileName != null)
                          Text(
                            state.thumbnailFileName!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        Text(
                          form.thumbnailUrl!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
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
                            const FilterBasicFieldChanged(
                              clearThumbnailUrl: true,
                            ),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
