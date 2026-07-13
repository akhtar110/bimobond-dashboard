import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/effect_placement_entities.dart';
import '../bloc/effect_editor_bloc.dart';
import '../bloc/effect_editor_event.dart';
import '../bloc/effect_editor_state.dart';
import '../utils/effect_placement_visibility.dart';

class EffectEditorPlacementSection extends StatelessWidget {
  const EffectEditorPlacementSection({
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

  String _anchorLabel(AnchorTypeEntity type) {
    final label = type.label.trim();
    return label.isNotEmpty ? label : type.key;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<EffectEditorBloc>();
    final form = state.form;
    final placement = form.placement;
    final anchorType = placement.anchorType;
    final placementEnabled = EffectPlacementVisibility.placementEnabled(
      requiresFaceDetection: form.requiresFaceDetection,
      isScreenEffect: form.isScreenEffect,
    );
    final landmarks = state.schema.landmarks;
    final anchorTypes = state.schema.anchorTypes;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          Text(
            l10n.tOr('feEffectSectionPlacement', 'Effect placement & settings'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (!embedded) const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: state.hasSlugDefaults && placementEnabled
                  ? () => bloc.add(const ApplyPlacementDefaultsEvent())
                  : null,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
              label: Text(
                l10n.tOr('feApplyPlacementDefaults', 'Apply backend defaults'),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: placementEnabled
                  ? () => bloc.add(const ResetPlacementEvent())
                  : null,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(
                l10n.tOr('feResetPlacement', 'Reset placement'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.schema.faceDetection.description != null)
          _InfoCard(
            icon: Icons.face_retouching_natural_outlined,
            text: state.schema.faceDetection.description!,
          ),
        const SizedBox(height: 8),
        if (!placementEnabled)
          _InfoCard(
            icon: Icons.info_outline_rounded,
            text: form.isScreenEffect
                ? l10n.tOr(
                    'fePlacementDisabledScreen',
                    'Screen overlay effects use the screen anchor automatically.',
                  )
                : l10n.tOr(
                    'fePlacementDisabledNoFace',
                    'Enable face detection to configure placement.',
                  ),
          )
        else ...[
          _AnchorTypeDropdown(
            anchorTypes: anchorTypes,
            value: anchorType,
            enabled: placementEnabled,
            errorText: _fieldError(context, 'anchorType'),
            labelFor: _anchorLabel,
            onChanged: (value) =>
                bloc.add(EffectAnchorTypeChanged(value)),
          ),
          if (EffectPlacementVisibility.showLandmarkMultiSelect(anchorType) ||
              EffectPlacementVisibility.showLandmarkSingleSelect(anchorType)) ...[
            const SizedBox(height: 12),
            Text(
              l10n.tOr('feFieldAnchorLandmarks', 'Anchor landmarks'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (_fieldError(context, 'anchorLandmarks') != null) ...[
              const SizedBox(height: 4),
              Text(
                _fieldError(context, 'anchorLandmarks')!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            _LandmarkSelector(
              landmarks: landmarks,
              selected: placement.anchorLandmarks,
              singleSelect: EffectPlacementVisibility.isSingleLandmarkMode(
                anchorType,
              ),
              maxSelection: EffectPlacementVisibility.landmarkSelectionLimit(
                anchorType,
              ),
              onChanged: (selected) =>
                  bloc.add(EffectLandmarksChanged(selected)),
            ),
          ],
          if (EffectPlacementVisibility.showScaleFactor(anchorType))
            _PlacementSlider(
              key: ValueKey('scale-$anchorType'),
              label: l10n.tOr('feFieldScaleFactor', 'Scale factor'),
              value: placement.scaleFactor ?? 1.0,
              min: 0.1,
              max: 3.0,
              divisions: 290,
              onChanged: (value) => bloc.add(
                EffectPlacementNumericChanged(scaleFactor: value),
              ),
            ),
          if (EffectPlacementVisibility.showOffsetX(anchorType))
            _PlacementSlider(
              key: ValueKey('offsetX-$anchorType'),
              label: l10n.tOr('feFieldOffsetX', 'Offset X'),
              value: placement.offsetX ?? 0.0,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) => bloc.add(
                EffectPlacementNumericChanged(offsetX: value),
              ),
            ),
          if (EffectPlacementVisibility.showOffsetY(anchorType))
            _PlacementSlider(
              key: ValueKey('offsetY-$anchorType'),
              label: l10n.tOr('feFieldOffsetY', 'Offset Y'),
              value: placement.offsetY ?? 0.0,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) => bloc.add(
                EffectPlacementNumericChanged(offsetY: value),
              ),
            ),
          if (EffectPlacementVisibility.showLandmarkSize(anchorType))
            _PlacementSlider(
              key: ValueKey('landmarkSize-$anchorType'),
              label: l10n.tOr('feFieldLandmarkSize', 'Landmark size'),
              value: placement.landmarkSize ?? 0.2,
              min: 0.05,
              max: 1.0,
              divisions: 95,
              onChanged: (value) => bloc.add(
                EffectPlacementNumericChanged(landmarkSize: value),
              ),
            ),
          if (EffectPlacementVisibility.showFallbackFields(anchorType)) ...[
            const SizedBox(height: 8),
            Text(
              l10n.tOr('fePlacementFallback', 'Fallback placement'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _AnchorTypeDropdown(
              anchorTypes: anchorTypes,
              value: placement.fallbackAnchorType,
              enabled: placementEnabled,
              label: l10n.tOr('feFieldFallbackAnchorType', 'Fallback anchor'),
              labelFor: _anchorLabel,
              onChanged: (value) =>
                  bloc.add(EffectFallbackAnchorTypeChanged(value)),
            ),
            _PlacementSlider(
              key: ValueKey('fallbackOffsetY-$anchorType'),
              label: l10n.tOr('feFieldFallbackOffsetY', 'Fallback offset Y'),
              value: placement.fallbackOffsetY ?? 0.0,
              min: -1.0,
              max: 1.0,
              divisions: 200,
              onChanged: (value) => bloc.add(
                EffectPlacementNumericChanged(fallbackOffsetY: value),
              ),
            ),
            _PlacementSlider(
              key: ValueKey('fallbackScale-$anchorType'),
              label: l10n.tOr(
                'feFieldFallbackScaleFactor',
                'Fallback scale factor',
              ),
              value: placement.fallbackScaleFactor ?? 1.0,
              min: 0.1,
              max: 3.0,
              divisions: 290,
              onChanged: (value) => bloc.add(
                EffectPlacementNumericChanged(fallbackScaleFactor: value),
              ),
            ),
          ],
        ],
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnchorTypeDropdown extends StatelessWidget {
  const _AnchorTypeDropdown({
    required this.anchorTypes,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.labelFor,
    this.label,
    this.errorText,
  });

  final List<AnchorTypeEntity> anchorTypes;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final String Function(AnchorTypeEntity) labelFor;
  final String? label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final normalized = value == null || value!.isEmpty
        ? null
        : CameraEffectAnchorTypeApi.normalize(value!);
    final items = anchorTypes
        .where((type) => type.key.isNotEmpty)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label ?? l10n.tOr('feFieldAnchorType', 'Anchor type'),
          errorText: errorText,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: items.any((t) => t.key == normalized) ? normalized : null,
            isExpanded: true,
            isDense: true,
            hint: Text(l10n.tOr('feSelectAnchorType', 'Select anchor type')),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: scheme.surface,
            icon: Icon(
              Icons.expand_more_rounded,
              color: scheme.onSurfaceVariant,
            ),
            items: [
              for (final type in items)
                DropdownMenuItem<String?>(
                  value: type.key,
                  child: Text(labelFor(type)),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }
}

class _LandmarkSelector extends StatelessWidget {
  const _LandmarkSelector({
    required this.landmarks,
    required this.selected,
    required this.singleSelect,
    required this.maxSelection,
    required this.onChanged,
  });

  final List<LandmarkDefinitionEntity> landmarks;
  final List<String> selected;
  final bool singleSelect;
  final int maxSelection;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final landmark in landmarks)
          FilterChip(
            label: Text(
              landmark.label.trim().isNotEmpty
                  ? landmark.label
                  : landmark.key,
            ),
            selected: selected.contains(landmark.key),
            onSelected: (isSelected) {
              if (singleSelect) {
                onChanged(isSelected ? [landmark.key] : []);
                return;
              }
              final next = List<String>.from(selected);
              if (isSelected) {
                if (!next.contains(landmark.key) &&
                    next.length < maxSelection) {
                  next.add(landmark.key);
                }
              } else {
                next.remove(landmark.key);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _PlacementSlider extends StatefulWidget {
  const _PlacementSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  State<_PlacementSlider> createState() => _PlacementSliderState();
}

class _PlacementSliderState extends State<_PlacementSlider> {
  double? _dragValue;
  bool _isDragging = false;

  double _clamp(double value) => value.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final sliderValue =
        _isDragging ? _dragValue! : _clamp(widget.value);
    final display = sliderValue.toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                display,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
          Slider(
            value: sliderValue,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: display,
            onChangeStart: (_) => _isDragging = true,
            onChanged: (next) {
              final clamped = _clamp(next);
              _dragValue = clamped;
              widget.onChanged(clamped);
            },
            onChangeEnd: (_) {
              setState(() {
                _isDragging = false;
                _dragValue = null;
              });
            },
          ),
        ],
      ),
    );
  }
}
