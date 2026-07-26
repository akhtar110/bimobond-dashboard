import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../utils/effect_anchor_form_data.dart';
import 'fe_editor_synced_text_field.dart';

/// Face pins, MediaPipe landmarks, and scale slider for sticker anchors.
class EffectAnchorFieldsForm extends StatelessWidget {
  const EffectAnchorFieldsForm({
    super.key,
    required this.anchor,
    required this.onChanged,
    this.errorText,
    this.dense = false,
    this.showPresetButton = true,
  });

  final EffectAnchorFormData anchor;
  final ValueChanged<EffectAnchorFormData> onChanged;
  final String? errorText;
  final bool dense;
  final bool showPresetButton;

  InputDecoration _decoration(BuildContext context, String label) {
    return InputDecoration(labelText: label, isDense: dense);
  }

  List<DropdownMenuItem<String>> _pinItems(
    BuildContext context,
    List<EffectAnchorPinOption> options,
    String? value,
  ) {
    final l10n = context.l10n;
    final values = <String>{...options.map((option) => option.value)};
    final current = value?.trim();
    if (current != null && current.isNotEmpty) {
      values.add(current);
    }

    return values
        .map((itemValue) {
          EffectAnchorPinOption? known;
          for (final option in options) {
            if (option.value == itemValue) {
              known = option;
              break;
            }
          }
          final label = known == null
              ? itemValue
              : l10n.tOr(known.labelKey, known.fallbackLabel);
          return DropdownMenuItem<String>(
            value: itemValue,
            child: Text(label, overflow: TextOverflow.ellipsis),
          );
        })
        .toList(growable: false);
  }

  List<DropdownMenuItem<int>> _landmarkItems(
    BuildContext context,
    List<EffectAnchorLandmarkOption> options,
  ) {
    final l10n = context.l10n;
    return options
        .map(
          (option) => DropdownMenuItem<int>(
            value: option.index,
            child: Text(
              '${option.index} — ${l10n.tOr(option.labelKey, option.fallbackLabel)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final sectionStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final hintStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPresetButton) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => onChanged(EffectAnchorFormData.glassesPreset),
              icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
              label: Text(
                l10n.tOr('feAnchorApplyGlassesPreset', 'Use glasses preset'),
              ),
            ),
          ),
          SizedBox(height: dense ? 8 : 12),
        ],
        Text(l10n.tOr('feAnchorSectionFace', 'Face'), style: sectionStyle),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'feAnchorFaceHint',
            'Choose where the sticker is pinned on the detected face.',
          ),
          style: hintStyle,
        ),
        SizedBox(height: dense ? 6 : 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 420;
            final children = [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('pinX-${anchor.pinX}'),
                  initialValue: anchor.pinX?.trim().isNotEmpty == true
                      ? anchor.pinX!.trim()
                      : null,
                  isExpanded: true,
                  decoration: _decoration(
                    context,
                    l10n.tOr('feFieldPinX', 'Horizontal pin'),
                  ),
                  hint: Text(l10n.tOr('feSelectPinX', 'Select horizontal pin')),
                  items: _pinItems(
                    context,
                    EffectAnchorPinOptions.pinX,
                    anchor.pinX,
                  ),
                  onChanged: (value) => onChanged(
                    anchor.copyWith(pinX: value, clearPinX: value == null),
                  ),
                ),
              ),
              SizedBox(width: stack ? 0 : 12, height: stack ? 8 : 0),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('pinY-${anchor.pinY}'),
                  initialValue: anchor.pinY?.trim().isNotEmpty == true
                      ? anchor.pinY!.trim()
                      : null,
                  isExpanded: true,
                  decoration: _decoration(
                    context,
                    l10n.tOr('feFieldPinY', 'Vertical pin'),
                  ),
                  hint: Text(l10n.tOr('feSelectPinY', 'Select vertical pin')),
                  items: _pinItems(
                    context,
                    EffectAnchorPinOptions.pinY,
                    anchor.pinY,
                  ),
                  onChanged: (value) => onChanged(
                    anchor.copyWith(pinY: value, clearPinY: value == null),
                  ),
                ),
              ),
            ];

            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              );
            }
            return Row(children: children);
          },
        ),
        SizedBox(height: dense ? 10 : 14),
        Text(
          l10n.tOr('feAnchorSectionLandmarks', 'Landmarks'),
          style: sectionStyle,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'feAnchorLandmarksHint',
            'MediaPipe face mesh point indices. Glasses use 33 (left eye), '
                '263 (right eye), and 168 (nose bridge).',
          ),
          style: hintStyle,
        ),
        SizedBox(height: dense ? 6 : 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 520;

            Widget field({
              required String label,
              required String helper,
              required int? value,
              required List<int> suggestions,
              required ValueChanged<int?> changed,
            }) {
              final items = _landmarkItems(
                context,
                EffectAnchorLandmarkOptions.optionsForField(
                  suggestions: suggestions,
                  selected: value,
                ),
              );
              return DropdownButtonFormField<int>(
                key: ValueKey('$label-$value'),
                initialValue: value,
                isExpanded: true,
                decoration: _decoration(
                  context,
                  label,
                ).copyWith(helperText: helper, helperMaxLines: 2),
                hint: Text(l10n.tOr('feSelectLandmark', 'Select landmark')),
                items: items,
                onChanged: changed,
              );
            }

            final left = field(
              label: l10n.tOr('feFieldLeftLandmark', 'Left landmark'),
              helper: l10n.tOr(
                'feFieldLeftLandmarkHint',
                'Left side reference point, usually the outer left eye.',
              ),
              value: anchor.parsedLeftLandmark,
              suggestions: EffectAnchorLandmarkOptions.leftSuggestions,
              changed: (value) => onChanged(
                anchor.copyWith(
                  leftLandmark: value?.toString(),
                  clearLeftLandmark: value == null,
                ),
              ),
            );
            final right = field(
              label: l10n.tOr('feFieldRightLandmark', 'Right landmark'),
              helper: l10n.tOr(
                'feFieldRightLandmarkHint',
                'Right side reference point, usually the outer right eye.',
              ),
              value: anchor.parsedRightLandmark,
              suggestions: EffectAnchorLandmarkOptions.rightSuggestions,
              changed: (value) => onChanged(
                anchor.copyWith(
                  rightLandmark: value?.toString(),
                  clearRightLandmark: value == null,
                ),
              ),
            );
            final anchorField = field(
              label: l10n.tOr('feFieldAnchorLandmark', 'Anchor landmark'),
              helper: l10n.tOr(
                'feFieldAnchorLandmarkHint',
                'Primary placement point, usually the nose bridge.',
              ),
              value: anchor.parsedAnchorLandmark,
              suggestions: EffectAnchorLandmarkOptions.anchorSuggestions,
              changed: (value) => onChanged(
                anchor.copyWith(
                  anchorLandmark: value?.toString(),
                  clearAnchorLandmark: value == null,
                ),
              ),
            );

            if (stack) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  left,
                  const SizedBox(height: 8),
                  right,
                  const SizedBox(height: 8),
                  anchorField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 8),
                Expanded(child: right),
                const SizedBox(width: 8),
                Expanded(child: anchorField),
              ],
            );
          },
        ),
        SizedBox(height: dense ? 10 : 14),
        Text(l10n.tOr('feAnchorSectionScale', 'Scale'), style: sectionStyle),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'feAnchorScaleHint',
            'Controls sticker width relative to the screen. '
                'The seed pack uses 3.5 for glasses.',
          ),
          style: hintStyle,
        ),
        SizedBox(height: dense ? 6 : 8),
        _AnchorScaleSlider(
          value: anchor.resolvedScale,
          onChanged: (value) => onChanged(
            anchor.copyWith(widthScreenMult: value.toStringAsFixed(1)),
          ),
        ),
        SizedBox(height: dense ? 10 : 14),
        Text(
          l10n.tOr('feAnchorSectionSizing', 'Width sizing'),
          style: sectionStyle,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'feAnchorSizingHint',
            'Use one or more width strategies. Composite layers often use widthFaceFrac.',
          ),
          style: hintStyle,
        ),
        SizedBox(height: dense ? 6 : 8),
        _AnchorFracSlider(
          label: l10n.tOr('feFieldWidthFaceFrac', 'Width face fraction'),
          value: anchor.parsedWidthFaceFrac ?? anchor.resolvedWidthFaceFrac,
          enabled: anchor.widthFaceFrac != null,
          onToggle: (enabled) => onChanged(
            enabled
                ? anchor.copyWith(widthFaceFrac: '1.0')
                : anchor.copyWith(clearWidthFaceFrac: true),
          ),
          onChanged: (value) => onChanged(
            anchor.copyWith(widthFaceFrac: value.toStringAsFixed(2)),
          ),
        ),
        const SizedBox(height: 8),
        _AnchorFracSlider(
          label: l10n.tOr('feFieldWidthMinFaceFrac', 'Width min face fraction'),
          value: anchor.parsedWidthMinFaceFrac ?? anchor.resolvedWidthMinFaceFrac,
          enabled: anchor.widthMinFaceFrac != null,
          onToggle: (enabled) => onChanged(
            enabled
                ? anchor.copyWith(widthMinFaceFrac: '0.7')
                : anchor.copyWith(clearWidthMinFaceFrac: true),
          ),
          onChanged: (value) => onChanged(
            anchor.copyWith(widthMinFaceFrac: value.toStringAsFixed(2)),
          ),
        ),
        const SizedBox(height: 8),
        _AnchorFracSlider(
          label: l10n.tOr('feFieldHeightSpanFrac', 'Height span fraction'),
          value: anchor.parsedHeightSpanFrac ?? anchor.resolvedHeightSpanFrac,
          enabled: anchor.heightSpanFrac != null,
          onToggle: (enabled) => onChanged(
            enabled
                ? anchor.copyWith(heightSpanFrac: '0.75')
                : anchor.copyWith(clearHeightSpanFrac: true),
          ),
          onChanged: (value) => onChanged(
            anchor.copyWith(heightSpanFrac: value.toStringAsFixed(2)),
          ),
        ),
        SizedBox(height: dense ? 10 : 14),
        Text(
          l10n.tOr('feAnchorSectionPivot', 'Pivot & flags'),
          style: sectionStyle,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tOr(
            'feAnchorPivotHint',
            'Texture pivot (0–1) and optional face averaging flags.',
          ),
          style: hintStyle,
        ),
        SizedBox(height: dense ? 6 : 8),
        _AnchorPivotSlider(
          label: l10n.tOr('feFieldPivotU', 'Pivot U'),
          value: anchor.resolvedPivotU,
          enabled: anchor.pivotU != null,
          onToggle: (enabled) => onChanged(
            enabled
                ? anchor.copyWith(pivotU: '0.5')
                : anchor.copyWith(clearPivotU: true),
          ),
          onChanged: (value) => onChanged(
            anchor.copyWith(pivotU: value.toStringAsFixed(2)),
          ),
        ),
        const SizedBox(height: 8),
        _AnchorPivotSlider(
          label: l10n.tOr('feFieldPivotV', 'Pivot V'),
          value: anchor.resolvedPivotV,
          enabled: anchor.pivotV != null,
          onToggle: (enabled) => onChanged(
            enabled
                ? anchor.copyWith(pivotV: '0.5')
                : anchor.copyWith(clearPivotV: true),
          ),
          onChanged: (value) => onChanged(
            anchor.copyWith(pivotV: value.toStringAsFixed(2)),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.tOr('feFieldUseAveragedEyes', 'Use averaged eyes')),
          subtitle: Text(
            l10n.tOr(
              'feFieldUseAveragedEyesHint',
              'Average left/right eye landmarks for placement.',
            ),
            style: hintStyle,
          ),
          value: anchor.useAveragedEyes ?? false,
          onChanged: (value) => onChanged(
            value
                ? anchor.copyWith(useAveragedEyes: true)
                : anchor.copyWith(clearUseAveragedEyes: true),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.tOr('feFieldScaleFromFaceBox', 'Scale from face box'),
          ),
          subtitle: Text(
            l10n.tOr(
              'feFieldScaleFromFaceBoxHint',
              'Scale sticker from the full detected face bounds.',
            ),
            style: hintStyle,
          ),
          value: anchor.scaleFromFaceBox ?? false,
          onChanged: (value) => onChanged(
            value
                ? anchor.copyWith(scaleFromFaceBox: true)
                : anchor.copyWith(clearScaleFromFaceBox: true),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}

class _AnchorScaleSlider extends StatelessWidget {
  const _AnchorScaleSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tOr(
                      'feFieldWidthScreenMult',
                      'Width screen multiplier',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FeSyncedNumberInput(
                  value: value,
                  min: EffectAnchorFormData.scaleMin,
                  max: EffectAnchorFormData.scaleMax,
                  isDouble: true,
                  decimals: 1,
                  width: 58,
                  height: 28,
                  onChanged: (v) => onChanged(v.toDouble()),
                ),
              ],
            ),
            Slider(
              value: value,
              min: EffectAnchorFormData.scaleMin,
              max: EffectAnchorFormData.scaleMax,
              divisions: 75,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${EffectAnchorFormData.scaleMin.toStringAsFixed(1)}×',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${EffectAnchorFormData.scaleDefault.toStringAsFixed(1)}×',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${EffectAnchorFormData.scaleMax.toStringAsFixed(1)}×',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnchorFracSlider extends StatelessWidget {
  const _AnchorFracSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onToggle,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (enabled) ...[
                  FeSyncedNumberInput(
                    value: value,
                    min: EffectAnchorFormData.fracMin,
                    max: EffectAnchorFormData.fracMax,
                    isDouble: true,
                    decimals: 2,
                    width: 62,
                    height: 28,
                    onChanged: (v) => onChanged(v.toDouble()),
                  ),
                  const SizedBox(width: 8),
                ],
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (enabled) ...[
              Slider(
                value: value.clamp(
                  EffectAnchorFormData.fracMin,
                  EffectAnchorFormData.fracMax,
                ),
                min: EffectAnchorFormData.fracMin,
                max: EffectAnchorFormData.fracMax,
                divisions: 39,
                label: value.toStringAsFixed(2),
                onChanged: onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnchorPivotSlider extends StatelessWidget {
  const _AnchorPivotSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onToggle,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onChanged;

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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (enabled) ...[
                  FeSyncedNumberInput(
                    value: value,
                    min: EffectAnchorFormData.pivotMin,
                    max: EffectAnchorFormData.pivotMax,
                    isDouble: true,
                    decimals: 2,
                    width: 62,
                    height: 28,
                    onChanged: (v) => onChanged(v.toDouble()),
                  ),
                  const SizedBox(width: 8),
                ],
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (enabled) ...[
              Slider(
                value: value.clamp(
                  EffectAnchorFormData.pivotMin,
                  EffectAnchorFormData.pivotMax,
                ),
                min: EffectAnchorFormData.pivotMin,
                max: EffectAnchorFormData.pivotMax,
                divisions: 20,
                label: value.toStringAsFixed(2),
                onChanged: onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String effectAnchorLandmarkSummary(
  BuildContext context,
  EffectAnchorFormData anchor,
) {
  final l10n = context.l10n;
  final parts = <String>[];
  final left = anchor.parsedLeftLandmark;
  final right = anchor.parsedRightLandmark;
  final anchorPoint = anchor.parsedAnchorLandmark;

  if (left != null) {
    parts.add('${l10n.tOr('feAnchorSummaryLeftShort', 'L')} $left');
  }
  if (right != null) {
    parts.add('${l10n.tOr('feAnchorSummaryRightShort', 'R')} $right');
  }
  if (anchorPoint != null) {
    parts.add('${l10n.tOr('feAnchorSummaryAnchorShort', 'A')} $anchorPoint');
  }

  return parts.isEmpty
      ? l10n.tOr('feAnchorSummaryLandmarks', 'Landmarks set')
      : parts.join(' · ');
}

String effectAnchorPinSummary(
  BuildContext context,
  EffectAnchorFormData anchor,
) {
  final l10n = context.l10n;
  final pinX = EffectAnchorPinOptions.findPinX(anchor.pinX);
  final pinY = EffectAnchorPinOptions.findPinY(anchor.pinY);
  final xLabel = pinX == null
      ? anchor.pinX
      : l10n.tOr(pinX.labelKey, pinX.fallbackLabel);
  final yLabel = pinY == null
      ? anchor.pinY
      : l10n.tOr(pinY.labelKey, pinY.fallbackLabel);

  if (xLabel != null &&
      xLabel.isNotEmpty &&
      yLabel != null &&
      yLabel.isNotEmpty) {
    return '$xLabel / $yLabel';
  }
  return xLabel ?? yLabel ?? '';
}
