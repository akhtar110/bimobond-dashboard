import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';

/// Form chrome for the filter create/edit dialog — colors from [ColorScheme] only.
class FeFilterFormTheme extends StatelessWidget {
  const FeFilterFormTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(12);

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: scheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: scheme.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: scheme.error, width: 2),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurface,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

String feFilterRenderTypeLabel(BuildContext context, String type) {
  final l10n = context.l10n;
  return switch (CameraFilterRenderTypeApi.fromResponse(type)) {
    CameraFilterRenderTypeApi.matrix => l10n.tOr('feRenderTypeMatrix', 'Matrix'),
    CameraFilterRenderTypeApi.lut => l10n.tOr('feRenderTypeLut', 'LUT'),
    _ => type,
  };
}

/// Filter render type picker (MATRIX | LUT).
class FeFilterRenderTypeField extends StatelessWidget {
  const FeFilterRenderTypeField({
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
    final selected = CameraFilterRenderTypeApi.fromResponse(value);
    final options = CameraFilterRenderTypeApi.values.contains(selected)
        ? CameraFilterRenderTypeApi.values
        : [...CameraFilterRenderTypeApi.values, selected];

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
          icon: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
          style: itemStyle,
          items: [
            for (final type in options)
              DropdownMenuItem<String>(
                value: type,
                child: Text(feFilterRenderTypeLabel(context, type)),
              ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}
