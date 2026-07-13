import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/filter_editor_state.dart';
import '../utils/fe_filter_settings_preview.dart';
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
    final modifiedEntries =
        form.filterSettings.nonDefaultEntries(state.schema);
    final baselineEntries =
        baseline.filterSettings.nonDefaultEntries(state.schema);
    final previewLook = filterSettingsPreviewLook(
      filterSettings: form.filterSettings,
      schema: state.schema,
      engineKey: form.engineKey,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          Text(
            l10n.tOr('feFilterSectionPreview', 'Preview'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (!embedded) const SizedBox(height: 12),
        FeCatalogItemPreview(
          mode: FeCatalogPreviewMode.filter,
          label: form.displayLabel,
          previewColorHex: form.previewColorHex,
          engineKey: form.engineKey,
          thumbnailUrl: form.thumbnailUrl,
          filterPreviewLook: previewLook,
        ),
        const SizedBox(height: 12),
        _ComparisonCard(
          title: l10n.tOr('feFilterComparison', 'Original vs modified'),
          baselineLabel: baseline.displayLabel,
          currentLabel: form.displayLabel,
          baselineCount: baselineEntries.length,
          currentCount: modifiedEntries.length,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.tOr('feFilterSettingsSummary', 'Modified settings'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        if (modifiedEntries.isEmpty)
          Text(
            l10n.tOr(
              'feFilterSettingsAllDefault',
              'All settings use defaults.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in modifiedEntries)
                    _SettingChip(
                      label: entry.definition.label,
                      value: entry.value,
                      defaultValue: entry.definition.defaultValue,
                    ),
                ],
              ),
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  const _SettingChip({
    required this.label,
    required this.value,
    required this.defaultValue,
  });

  final String label;
  final int value;
  final int defaultValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delta = value - defaultValue;
    final deltaLabel = delta > 0 ? '+$delta' : '$delta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(width: 4),
          Text(
            '($deltaLabel)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.title,
    required this.baselineLabel,
    required this.currentLabel,
    required this.baselineCount,
    required this.currentCount,
  });

  final String title;
  final String baselineLabel;
  final String currentLabel;
  final int baselineCount;
  final int currentCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasChanges = baselineLabel != currentLabel ||
        baselineCount != currentCount;

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
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _ComparisonRow(
              label: l10n.tOr('feFilterBaseline', 'Original'),
              displayLabel: baselineLabel,
              settingsCount: baselineCount,
            ),
            const SizedBox(height: 6),
            _ComparisonRow(
              label: l10n.tOr('feFilterCurrent', 'Modified'),
              displayLabel: currentLabel,
              settingsCount: currentCount,
              emphasize: hasChanges,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.displayLabel,
    required this.settingsCount,
    this.emphasize = false,
  });

  final String label;
  final String displayLabel;
  final int settingsCount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                displayLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                      color: emphasize ? scheme.primary : scheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.tArgs('feFilterSettingsCount', {'count': '$settingsCount'}),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
