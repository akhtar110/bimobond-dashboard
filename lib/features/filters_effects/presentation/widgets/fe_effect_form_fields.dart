import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';

/// Effect type picker — state-controlled dropdown (not a FormField).
class FeEffectTypeField extends StatelessWidget {
  const FeEffectTypeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  String _label(BuildContext context, String type) {
    final l10n = context.l10n;
    return switch (CameraEffectTypeApi.normalize(type)) {
      CameraEffectTypeApi.screenOverlay =>
        l10n.tOr('feEffectTypeScreenOverlay', 'Screen overlay'),
      _ => l10n.tOr('feEffectTypeFaceAr', 'Face AR'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final itemStyle = theme.textTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
    );
    final selected = CameraEffectTypeApi.normalize(value);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.tOr('feFieldEffectType', 'Effect type'),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
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
            for (final type in CameraEffectTypeApi.values)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  _label(context, type),
                  style: itemStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          items: [
            for (final type in CameraEffectTypeApi.values)
              DropdownMenuItem<String>(
                value: type,
                child: Text(
                  _label(context, type),
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
