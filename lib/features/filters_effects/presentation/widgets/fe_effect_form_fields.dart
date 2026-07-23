import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import 'fe_catalog_item_preview.dart' show feEffectRenderTypeLabel;

String feDistortionPresetLabel(BuildContext context, String preset) {
  final l10n = context.l10n;
  return switch (CameraDistortionPresetApi.fromResponse(preset)) {
    CameraDistortionPresetApi.bigEyes => l10n.tOr(
      'feDistortionBigEyes',
      'Big eyes',
    ),
    CameraDistortionPresetApi.bigLips => l10n.tOr(
      'feDistortionBigLips',
      'Big lips',
    ),
    CameraDistortionPresetApi.longNose => l10n.tOr(
      'feDistortionLongNose',
      'Long nose',
    ),
    _ => preset,
  };
}

/// Effect render type picker (NONE | STICKER | COMPOSITE | DISTORTION).
class FeEffectRenderTypeField extends StatelessWidget {
  const FeEffectRenderTypeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final itemStyle = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
    );
    final selected = CameraEffectRenderTypeApi.fromResponse(value);
    final options = CameraEffectRenderTypeApi.values.contains(selected)
        ? CameraEffectRenderTypeApi.values
        : [...CameraEffectRenderTypeApi.values, selected];

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.tOr('feFieldRenderType', 'Render type'),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: scheme.surface,
          focusColor: scheme.primary.withValues(alpha: 0.12),
          icon: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
          style: itemStyle,
          selectedItemBuilder: (context) => [
            for (final type in options)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  feEffectRenderTypeLabel(context, type),
                  style: itemStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final type in options)
              DropdownMenuItem<String>(
                value: type,
                child: Text(
                  feEffectRenderTypeLabel(context, type),
                  style: itemStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Distortion preset picker (BIG_EYES | BIG_LIPS | LONG_NOSE).
class FeDistortionPresetField extends StatelessWidget {
  const FeDistortionPresetField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final itemStyle = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
    );
    final normalized = value == null || value!.trim().isEmpty
        ? null
        : CameraDistortionPresetApi.fromResponse(value!);
    final options =
        normalized == null ||
            CameraDistortionPresetApi.values.contains(normalized)
        ? CameraDistortionPresetApi.values
        : [...CameraDistortionPresetApi.values, normalized];

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.tOr('feFieldDistortionPreset', 'Distortion preset'),
        errorText: errorText,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: normalized,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: scheme.surface,
          focusColor: scheme.primary.withValues(alpha: 0.12),
          hint: Text(
            l10n.tOr('feDistortionPresetNone', 'Not selected'),
            style: itemStyle?.copyWith(color: scheme.onSurfaceVariant),
          ),
          icon: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
          style: itemStyle,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                l10n.tOr('feDistortionPresetNone', 'Not selected'),
                style: itemStyle?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            for (final preset in options)
              DropdownMenuItem<String?>(
                value: preset,
                child: Text(
                  feDistortionPresetLabel(context, preset),
                  style: itemStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
