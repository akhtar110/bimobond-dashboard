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
    super.key,
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
  String _search = '';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<FiltersEffectsBloc>();
      if (widget.isEffectCategory) {
        bloc.add(const LoadCameraEffects());
      } else {
        bloc.add(const LoadCameraFilters());
      }
    });
  }

  String _categoryId() {
    if (widget.isEffectCategory) {
      return (widget.category as CameraEffectCategoryEntity).id;
    }
    return (widget.category as CameraFilterCategoryEntity).id;
  }

  String _labelForId(FiltersEffectsLoaded loaded, String id) {
    if (widget.isEffectCategory) {
      final category = widget.category as CameraEffectCategoryEntity;
      for (final source in [
        loaded.allEffectsForPicker,
        loaded.effects,
        category.effects,
      ]) {
        for (final effect in source) {
          if (effect.id != id) continue;
          final emoji = effect.emoji?.trim();
          if (emoji != null && emoji.isNotEmpty) {
            return '$emoji ${effect.displayLabel}';
          }
          return effect.displayLabel;
        }
      }
      return id;
    }

    final category = widget.category as CameraFilterCategoryEntity;
    for (final source in [
      loaded.allFiltersForPicker,
      loaded.filters,
      category.filters,
    ]) {
      for (final filter in source) {
        if (filter.id == id) return filter.displayLabel;
      }
    }
    return id;
  }

  bool _matchesSearch({
    required String slug,
    required String displayLabel,
    String? labelKey,
  }) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    return slug.toLowerCase().contains(q) ||
        displayLabel.toLowerCase().contains(q) ||
        (labelKey?.toLowerCase().contains(q) ?? false);
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

  void _clearAll() {
    setState(() {
      _selectedIds.clear();
      _orderedIds.clear();
    });
  }

  void _selectAll(List<String> ids) {
    setState(() {
      for (final id in ids) {
        _selectedIds.add(id);
        if (!_orderedIds.contains(id)) {
          _orderedIds.add(id);
        }
      }
    });
  }

  void _submit(FiltersEffectsLoaded loaded) {
    final bloc = context.read<FiltersEffectsBloc>();
    final categoryId = _categoryId();

    if (widget.isEffectCategory) {
      final payload = <EffectAssignmentItem>[];
      for (var i = 0; i < _orderedIds.length; i++) {
        payload.add(
          EffectAssignmentItem(effectId: _orderedIds[i], sortOrder: i),
        );
      }
      bloc.add(AssignEffectsToCategoryEvent(categoryId, payload));
    } else {
      final payload = <FilterAssignmentItem>[];
      for (var i = 0; i < _orderedIds.length; i++) {
        payload.add(
          FilterAssignmentItem(filterId: _orderedIds[i], sortOrder: i),
        );
      }
      bloc.add(AssignFiltersToCategoryEvent(categoryId, payload));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.isEffectCategory
        ? l10n.tOr('feAssignEffects', 'Assign effects')
        : l10n.tOr('feAssignFilters', 'Assign filters');

    return BlocBuilder<FiltersEffectsBloc, FiltersEffectsState>(
      builder: (context, state) {
        if (state is! FiltersEffectsLoaded) {
          return AlertDialog(
            title: Text(title),
            content: const SizedBox(
              height: 120,
              width: 320,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return _buildDialog(context, l10n, state, title);
      },
    );
  }

  Widget _buildDialog(
    BuildContext context,
    AppLocalizations l10n,
    FiltersEffectsLoaded state,
    String title,
  ) {

    final visibleEffects = widget.isEffectCategory
        ? state.allEffectsForPicker
              .where(
                (e) => _matchesSearch(
                  slug: e.slug,
                  displayLabel: e.displayLabel,
                  labelKey: e.labelKey,
                ),
              )
              .toList()
        : const <CameraEffectEntity>[];
    final visibleFilters = !widget.isEffectCategory
        ? state.allFiltersForPicker
              .where(
                (f) => _matchesSearch(
                  slug: f.slug,
                  displayLabel: f.displayLabel,
                  labelKey: f.labelKey,
                ),
              )
              .toList()
        : const <CameraFilterEntity>[];

    final currentVisibleIds = widget.isEffectCategory
        ? visibleEffects.map((e) => e.id).toList()
        : visibleFilters.map((f) => f.id).toList();
    final isAllSelected = currentVisibleIds.isNotEmpty &&
        currentVisibleIds.every((id) => _selectedIds.contains(id));

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tOr(
                'feAssignSelectHint',
                'Select items, then drag to reorder.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.tOr('feAssignSearchHint', 'Search items…'),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: currentVisibleIds.isEmpty
                      ? null
                      : () {
                          if (isAllSelected) {
                            _clearAll();
                          } else {
                            _selectAll(currentVisibleIds);
                          }
                        },
                  icon: Icon(
                    isAllSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isAllSelected
                        ? l10n.tOr('feDeselectAll', 'Deselect all')
                        : l10n.tOr('feSelectAll', 'Select all'),
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectedIds.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: Text(l10n.tOr('feClearAll', 'Clear all')),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: [
                  if (widget.isEffectCategory)
                    for (final effect in visibleEffects)
                      CheckboxListTile(
                        value: _selectedIds.contains(effect.id),
                        onChanged: (v) => _toggle(effect.id, v ?? false),
                        title: Text(
                          effect.emoji != null &&
                                  effect.emoji!.trim().isNotEmpty
                              ? '${effect.emoji} ${effect.displayLabel}'
                              : effect.displayLabel,
                        ),
                        subtitle: Text(effect.slug),
                      )
                  else
                    for (final filter in visibleFilters)
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
