import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filter_settings_entities.dart';
import '../bloc/filter_editor_bloc.dart';
import '../bloc/filter_editor_event.dart';
import '../bloc/filter_editor_state.dart';

class FilterEditorSettingsSection extends StatelessWidget {
  const FilterEditorSettingsSection({
    super.key,
    required this.state,
    this.embedded = false,
  });

  final FilterEditorReady state;
  final bool embedded;

  bool _matchesSearch(FilterSettingDefinitionEntity definition, String query) {
    if (query.isEmpty) return true;
    final normalized = query.toLowerCase();
    return definition.key.toLowerCase().contains(normalized) ||
        definition.label.toLowerCase().contains(normalized) ||
        (definition.description?.toLowerCase().contains(normalized) ?? false);
  }

  List<FilterSettingDefinitionEntity> _settingsForGroup(String groupKey) {
    return state.schema.settings
        .where((setting) => setting.group == groupKey)
        .where((setting) => _matchesSearch(setting, state.settingsSearchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<FilterEditorBloc>();
    final visibleGroups = state.schema.groups
        .where((group) => _settingsForGroup(group.key).isNotEmpty)
        .toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          Text(
            l10n.tOr('feFilterSectionSettings', 'Filter settings'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        if (!embedded) const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            hintText: l10n.tOr('feFilterSettingsSearch', 'Search settings'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          onChanged: (query) => bloc.add(FilterSettingsSearchChanged(query)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () =>
                  bloc.add(const FilterToggleAllGroupsEvent(expand: true)),
              icon: const Icon(Icons.unfold_more_rounded, size: 16),
              label: Text(l10n.tOr('feExpandAll', 'Expand all')),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () =>
                  bloc.add(const FilterToggleAllGroupsEvent(expand: false)),
              icon: const Icon(Icons.unfold_less_rounded, size: 16),
              label: Text(l10n.tOr('feCollapseAll', 'Collapse all')),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () => bloc.add(const ResetFilterSettingsEvent()),
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: Text(l10n.tOr('feResetFilterDefaults', 'Reset defaults')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleGroups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.tOr('feNoSettingsMatch', 'No settings match your search.'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          for (final group in visibleGroups)
            _FilterSettingsGroupTile(
              key: ValueKey('group-${group.key}'),
              group: group,
              settings: _settingsForGroup(group.key),
              expanded: state.isGroupExpanded(group.key),
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

class _FilterSettingsGroupTile extends StatelessWidget {
  const _FilterSettingsGroupTile({
    super.key,
    required this.group,
    required this.settings,
    required this.expanded,
  });

  final FilterSettingGroupEntity group;
  final List<FilterSettingDefinitionEntity> settings;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FilterEditorBloc>();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (_) =>
              bloc.add(FilterGroupExpansionToggled(group.key)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            group.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          children: [
            for (final setting in settings)
              _FilterSettingSlider(
                key: ValueKey(setting.key),
                definition: setting,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSettingSlider extends StatefulWidget {
  const _FilterSettingSlider({
    super.key,
    required this.definition,
  });

  final FilterSettingDefinitionEntity definition;

  @override
  State<_FilterSettingSlider> createState() => _FilterSettingSliderState();
}

class _FilterSettingSliderState extends State<_FilterSettingSlider> {
  double? _dragValue;
  bool _isDragging = false;

  double get _min => widget.definition.isBipolar ? -100.0 : 0.0;
  double get _max => 100.0;
  int get _divisions => widget.definition.isBipolar ? 200 : 100;

  double _clamp(double value) => value.clamp(_min, _max);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FilterEditorBloc, FilterEditorState, int>(
      selector: (state) {
        if (state is! FilterEditorReady) {
          return widget.definition.defaultValue;
        }
        return state.form.filterSettings.valueFor(widget.definition);
      },
      builder: (context, blocValue) {
        final sliderValue = _isDragging
            ? _dragValue!
            : _clamp(blocValue.toDouble());
        final displayValue = sliderValue.round();

        return _FilterSettingSliderContent(
          definition: widget.definition,
          sliderValue: sliderValue,
          displayValue: displayValue,
          min: _min,
          max: _max,
          divisions: _divisions,
          onChangeStart: () => _isDragging = true,
          onChanged: (next) {
            final clamped = _clamp(next);
            _dragValue = clamped;
            context.read<FilterEditorBloc>().add(
                  FilterSliderChanged(
                    key: widget.definition.key,
                    value: clamped.round(),
                  ),
                );
          },
          onChangeEnd: () {
            setState(() {
              _isDragging = false;
              _dragValue = null;
            });
          },
        );
      },
    );
  }
}

class _FilterSettingSliderContent extends StatelessWidget {
  const _FilterSettingSliderContent({
    required this.definition,
    required this.sliderValue,
    required this.displayValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final FilterSettingDefinitionEntity definition;
  final double sliderValue;
  final int displayValue;
  final double min;
  final double max;
  final int divisions;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  definition.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '$displayValue',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: sliderValue,
            min: min,
            max: max,
            divisions: divisions,
            label: '$displayValue',
            onChangeStart: (_) => onChangeStart(),
            onChanged: onChanged,
            onChangeEnd: (_) => onChangeEnd(),
          ),
        ],
      ),
    );
  }
}
