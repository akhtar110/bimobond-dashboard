import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/filter_editor_state.dart';
import 'fe_filter_form_fields.dart';
import 'fe_catalog_item_preview.dart';

class FilterEditorPreviewPanel extends StatelessWidget {
  const FilterEditorPreviewPanel({
    super.key,
    required this.state,
    this.embedded = false,
  });

  final FilterEditorReady state;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final form = state.form;
    final baseline = state.baseline;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          Text(
            l10n.tOr('feFilterSectionPreview', 'Preview'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        if (!embedded) const SizedBox(height: 12),
        FeCatalogItemPreview(
          mode: FeCatalogPreviewMode.filter,
          label: form.displayLabel,
          previewColorHex: form.previewColorHex,
          emoji: form.emoji,
          thumbnailUrl: form.thumbnailUrl,
          renderType: form.renderType,
          lutUrl: form.lutUrl,
          lutPreviewBytes: state.lutPreviewBytes,
          lutPreviewFilename: state.lutFileName,
          colorMatrix: form.colorMatrix,
          adjustments: form.adjustments,
          externalLoading: state.isUploadingLut,
        ),
        const SizedBox(height: 12),
        _SummaryCard(
          children: [
            _SummaryRow(
              label: l10n.tOr('feFieldRenderType', 'Render type'),
              value: feFilterRenderTypeLabel(context, form.renderType),
            ),
            _SummaryRow(
              label: l10n.tOr('feFieldSlug', 'Slug'),
              value: form.slug.trim().isEmpty ? '—' : form.slug.trim(),
            ),
            if (form.isLut) ...[
              _SummaryRow(
                label: l10n.tOr('feFieldLutUrl', 'LUT URL'),
                value: (form.lutUrl?.trim().isNotEmpty ?? false)
                    ? form.lutUrl!.trim()
                    : '—',
              ),
              _SummaryRow(
                label: l10n.tOr('feFieldLutAsset', 'LUT asset'),
                value: (form.lutAsset?.trim().isNotEmpty ?? false)
                    ? form.lutAsset!.trim()
                    : '—',
              ),
            ],
            if (form.isMatrix)
              _SummaryRow(
                label: l10n.tOr('feFilterSettingsSummary', 'Modified settings'),
                value: form.adjustments.isEmpty
                    ? l10n.tOr(
                        'feFilterSettingsAllDefault',
                        'All settings use defaults.',
                      )
                    : context.tr('feFilterSettingsCount', {
                        'count': '${form.adjustments.length}',
                      }),
              ),
            if (state.isEditing && form != baseline)
              _SummaryRow(
                label: l10n.tOr('feFilterCurrent', 'Modified'),
                value: l10n.t('yes'),
              ),
          ],
        ),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
