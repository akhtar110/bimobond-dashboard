import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filter_settings_entities.dart';
import '../bloc/filter_editor_bloc.dart';
import '../bloc/filter_editor_event.dart';
import '../bloc/filter_editor_state.dart';
import 'fe_editor_synced_text_field.dart';

class FilterBeautySettingsSection extends StatelessWidget {
  const FilterBeautySettingsSection({
    super.key,
    required this.state,
  });

  final FilterEditorReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<FilterEditorBloc>();
    final settings = state.form.filterSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.face_retouching_natural_rounded, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.tOr('feBeautySettingsTitle', 'Beauty Settings'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Group 1: Skin & Face Enhancements
        _BeautyGroupCard(
          title: l10n.tOr('feGroupSkinFace', 'Skin & Face Enhancements'),
          icon: Icons.auto_awesome_rounded,
          children: [
            _BeautySliderTile(
              label: l10n.tOr('feSmooth', 'Smooth'),
              value: settings.smooth ?? FilterSettingsEntity.defaultSmooth,
              defaultValue: FilterSettingsEntity.defaultSmooth,
              onChanged: (v) => bloc.add(FilterSettingChanged(smooth: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feWhiten', 'Whiten'),
              value: settings.whiten ?? FilterSettingsEntity.defaultWhiten,
              defaultValue: FilterSettingsEntity.defaultWhiten,
              onChanged: (v) => bloc.add(FilterSettingChanged(whiten: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feBrighten', 'Brighten'),
              value: settings.brighten ?? FilterSettingsEntity.defaultBrighten,
              defaultValue: FilterSettingsEntity.defaultBrighten,
              onChanged: (v) => bloc.add(FilterSettingChanged(brighten: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feBlush', 'Blush'),
              value: settings.blush ?? FilterSettingsEntity.defaultBlush,
              defaultValue: FilterSettingsEntity.defaultBlush,
              onChanged: (v) => bloc.add(FilterSettingChanged(blush: v.toInt())),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Group 2: Lip Tint & Opacity
        _BeautyGroupCard(
          title: l10n.tOr('feGroupLips', 'Lip Color & Opacity'),
          icon: Icons.brush_rounded,
          children: [
            _BeautySliderTile(
              label: l10n.tOr('feLipStrength', 'Lip Opacity (Strength)'),
              value: settings.lipStrength ?? FilterSettingsEntity.defaultLipStrength,
              defaultValue: FilterSettingsEntity.defaultLipStrength,
              onChanged: (v) => bloc.add(FilterSettingChanged(lipStrength: v.toInt())),
            ),
            const SizedBox(height: 8),
            _LipTintPicker(
              lipTint: settings.lipTint ?? FilterSettingsEntity.defaultLipTint,
              errorText: state.fieldErrors['lipTint'],
              onChanged: (hex) => bloc.add(FilterSettingChanged(lipTint: hex)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Group 3: Color & Intensity Adjustments
        _BeautyGroupCard(
          title: l10n.tOr('feGroupColorTone', 'Color & Tone Adjustments'),
          icon: Icons.tune_rounded,
          children: [
            _BeautySliderTile(
              label: l10n.tOr('feDefaultIntensity', 'Default Intensity'),
              value: settings.defaultIntensity ?? FilterSettingsEntity.defaultIntensityVal,
              defaultValue: FilterSettingsEntity.defaultIntensityVal,
              onChanged: (v) => bloc.add(FilterSettingChanged(defaultIntensity: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feBrightness', 'Brightness'),
              value: settings.brightness ?? FilterSettingsEntity.defaultBrightness,
              defaultValue: FilterSettingsEntity.defaultBrightness,
              onChanged: (v) => bloc.add(FilterSettingChanged(brightness: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feContrast', 'Contrast'),
              value: settings.contrast ?? FilterSettingsEntity.defaultContrast,
              defaultValue: FilterSettingsEntity.defaultContrast,
              onChanged: (v) => bloc.add(FilterSettingChanged(contrast: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feSaturation', 'Saturation'),
              value: settings.saturation ?? FilterSettingsEntity.defaultSaturation,
              defaultValue: FilterSettingsEntity.defaultSaturation,
              onChanged: (v) => bloc.add(FilterSettingChanged(saturation: v.toInt())),
            ),
            _BeautySliderTile(
              label: l10n.tOr('feWarmth', 'Warmth'),
              value: settings.warmth ?? FilterSettingsEntity.defaultWarmth,
              defaultValue: FilterSettingsEntity.defaultWarmth,
              onChanged: (v) => bloc.add(FilterSettingChanged(warmth: v.toInt())),
            ),
          ],
        ),
      ],
    );
  }
}

class _BeautyGroupCard extends StatelessWidget {
  const _BeautyGroupCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.secondary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BeautySliderTile extends StatelessWidget {
  const _BeautySliderTile({
    required this.label,
    required this.value,
    required this.defaultValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int defaultValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                  ),
                  Text(
                    ' / 100',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (value != defaultValue) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => onChanged(defaultValue.toDouble()),
                      child: Tooltip(
                        message: 'Reset to default ($defaultValue)',
                        child: Icon(Icons.refresh_rounded, size: 14, color: scheme.secondary),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.surfaceContainerHighest,
            ),
            child: Slider(
              value: value.toDouble().clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$value',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _LipTintPicker extends StatelessWidget {
  const _LipTintPicker({
    required this.lipTint,
    required this.onChanged,
    this.errorText,
  });

  final String lipTint;
  final ValueChanged<String> onChanged;
  final String? errorText;

  static const _presetColors = [
    '#E8527A',
    '#D81B60',
    '#E91E63',
    '#C2185B',
    '#B71C1C',
    '#FF4081',
    '#FF80AB',
    '#FF1744',
  ];

  Color _parseColor(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    final parsed = int.tryParse(cleaned, radix: 16);
    return Color(parsed ?? 0xFFE8527A);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final currentColor = _parseColor(lipTint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tOr('feLipTintLabel', 'Lip Color Hex (#RRGGBB)'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outlineVariant, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FeEditorSyncedTextField(
                value: lipTint,
                decoration: InputDecoration(
                  hintText: '#E8527A',
                  errorText: errorText,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) {
                  var text = val.trim();
                  if (!text.startsWith('#') && text.isNotEmpty) text = '#$text';
                  onChanged(text);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final hex in _presetColors)
              InkWell(
                onTap: () => onChanged(hex),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseColor(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lipTint.toUpperCase() == hex.toUpperCase()
                          ? scheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
