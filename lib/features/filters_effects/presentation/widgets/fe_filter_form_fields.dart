import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../data/datasources/filters_effects_remote_datasource.dart';

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

/// Engine key picker styled with the ambient [ColorScheme].
class FeFilterEngineKeyField extends StatelessWidget {
  const FeFilterEngineKeyField({
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

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.tOr('feFieldEngineKey', 'Engine key'),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: scheme.surface,
          focusColor: scheme.primary.withValues(alpha: 0.12),
          icon: Icon(
            Icons.expand_more_rounded,
            color: scheme.onSurfaceVariant,
          ),
          style: itemStyle,
          selectedItemBuilder: (context) => [
            for (final key in kCameraAwesomeEngineKeys)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  key,
                  style: itemStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final key in kCameraAwesomeEngineKeys)
              DropdownMenuItem<String>(
                value: key,
                child: Text(
                  key,
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
