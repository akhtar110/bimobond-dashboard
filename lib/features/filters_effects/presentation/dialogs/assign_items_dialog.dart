import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';

void showAssignItemsDialog(
  BuildContext context, {
  required bool isEffectCategory,
  required Object category,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<FiltersEffectsBloc>(),
      child: AssignItemsDialog(
        isEffectCategory: isEffectCategory,
        category: category,
      ),
    ),
  );
}

class AssignItemsDialog extends StatefulWidget {
  const AssignItemsDialog({
    required this.isEffectCategory,
    required this.category,
  });

  final bool isEffectCategory;
  final Object category;

  @override
  State<AssignItemsDialog> createState() => _AssignItemsDialogState();
}

class _AssignItemsDialogState extends State<AssignItemsDialog> {
  late final Set<String> _selectedIds;
  late List<String> _orderedIds;

  @override
  void initState() {
    super.initState();
    if (widget.isEffectCategory) {
      final category = widget.category as CameraEffectCategoryEntity;
      _selectedIds = category.effects.map((e) => e.id).toSet();
      _orderedIds = category.effects.map((e) => e.id).toList();
    } else {
      final category = widget.category as CameraFilterCategoryEntity;
      _selectedIds = category.filters.map((f) => f.id).toSet();
      _orderedIds = category.filters.map((f) => f.id).toList();
    }
  }

  String _categoryId() {
    if (widget.isEffectCategory) {
      return (widget.category as CameraEffectCategoryEntity).id;
    }
    return (widget.category as CameraFilterCategoryEntity).id;
  }

  String _labelForId(FiltersEffectsLoaded loaded, String id) {
    if (widget.isEffectCategory) {
      final effect = loaded.effects.firstWhere((e) => e.id == id);
      return effect.emoji != null ? '${effect.emoji} ${effect.labelKey}' : effect.labelKey;
    }
    final filter = loaded.filters.firstWhere((f) => f.id == id);
    return filter.displayLabel;
  }

  void _toggle(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
        if (!_orderedIds.contains(id)) _orderedIds.add(id);
      } else {
        _selectedIds.remove(id);
        _orderedIds.remove(id);
      }
    });
  }

  void _submit(FiltersEffectsLoaded loaded) {
    final bloc = context.read<FiltersEffectsBloc>();
    final categoryId = _categoryId();

    if (widget.isEffectCategory) {
      final payload = <EffectAssignmentItem>[];
      for (var i = 0; i < _orderedIds.length; i++) {
        payload.add(EffectAssignmentItem(effectId: _orderedIds[i], sortOrder: i));
      }
      bloc.add(AssignEffectsToCategoryEvent(categoryId, payload));
    } else {
      final payload = <FilterAssignmentItem>[];
      for (var i = 0; i < _orderedIds.length; i++) {
        payload.add(FilterAssignmentItem(filterId: _orderedIds[i], sortOrder: i));
      }
      bloc.add(AssignFiltersToCategoryEvent(categoryId, payload));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<FiltersEffectsBloc>().state;
    if (state is! FiltersEffectsLoaded) {
      return const SizedBox.shrink();
    }

    final title = widget.isEffectCategory
        ? l10n.tOr('feAssignEffects', 'Assign effects')
        : l10n.tOr('feAssignFilters', 'Assign filters');

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tOr('feAssignSelectHint', 'Select items, then drag to reorder.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  if (widget.isEffectCategory)
                    for (final effect in state.effects)
                      CheckboxListTile(
                        value: _selectedIds.contains(effect.id),
                        onChanged: (v) => _toggle(effect.id, v ?? false),
                        title: Text(
                          effect.emoji != null
                              ? '${effect.emoji} ${effect.labelKey}'
                              : effect.labelKey,
                        ),
                        subtitle: Text(effect.slug),
                      )
                  else
                    for (final filter in state.filters)
                      CheckboxListTile(
                        value: _selectedIds.contains(filter.id),
                        onChanged: (v) => _toggle(filter.id, v ?? false),
                        title: Text(filter.displayLabel),
                        subtitle: Text(filter.slug),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tOr('feAssignedOrder', 'Assigned order'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 180,
              child: _orderedIds.isEmpty
                  ? Center(
                      child: Text(
                        l10n.tOr('feNoAssignedItems', 'No items assigned yet.'),
                      ),
                    )
                  : ReorderableListView(
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final id = _orderedIds.removeAt(oldIndex);
                          _orderedIds.insert(newIndex, id);
                        });
                      },
                      children: [
                        for (final id in _orderedIds)
                          ListTile(
                            key: ValueKey(id),
                            leading: const Icon(Icons.drag_handle_rounded),
                            title: Text(_labelForId(state, id)),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => _submit(state),
          child: Text(l10n.tOr('feSave', 'Save')),
        ),
      ],
    );
  }
}
