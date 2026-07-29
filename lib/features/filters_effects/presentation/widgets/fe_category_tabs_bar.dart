import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../dialogs/assign_items_dialog.dart';
import '../dialogs/category_form_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';

/// Horizontal All + category chips for Filters or Effects lists.
class FeCategoryTabsBar extends StatefulWidget {
  const FeCategoryTabsBar({
    super.key,
    required this.isEffectCategory,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final bool isEffectCategory;
  final List<Object> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  @override
  State<FeCategoryTabsBar> createState() => _FeCategoryTabsBarState();
}

class _FeCategoryTabsBarState extends State<FeCategoryTabsBar> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPointerScroll(PointerScrollEvent event) {
    if (!_scrollController.hasClients) return;
    final next = (_scrollController.offset + event.scrollDelta.dy)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.jumpTo(next);
  }

  String _label(Object category) {
    if (widget.isEffectCategory) {
      return (category as CameraEffectCategoryEntity).displayLabel;
    }
    return (category as CameraFilterCategoryEntity).displayLabel;
  }

  /// Category chip label with item count (All tab stays without a count).
  String _chipLabel(Object category) {
    final name = _label(category);
    final count = widget.isEffectCategory
        ? (category as CameraEffectCategoryEntity).effectsCount
        : (category as CameraFilterCategoryEntity).filtersCount;
    return '$name ($count)';
  }

  String _id(Object category) {
    if (widget.isEffectCategory) {
      return (category as CameraEffectCategoryEntity).id;
    }
    return (category as CameraFilterCategoryEntity).id;
  }

  Future<void> _createCategory() async {
    showCategoryFormDialog(
      context,
      isEffectCategory: widget.isEffectCategory,
    );
  }

  Future<void> _reorderCategories() async {
    final l10n = context.l10n;
    final sorted = [...widget.categories]..sort((a, b) {
        final aOrder = widget.isEffectCategory
            ? (a as CameraEffectCategoryEntity).sortOrder
            : (a as CameraFilterCategoryEntity).sortOrder;
        final bOrder = widget.isEffectCategory
            ? (b as CameraEffectCategoryEntity).sortOrder
            : (b as CameraFilterCategoryEntity).sortOrder;
        return aOrder.compareTo(bOrder);
      });
    final labels = sorted.map(_label).toList();
    final ids = sorted.map(_id).toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => _ReorderCategoriesDialog(
        title: widget.isEffectCategory
            ? l10n.tOr(
                'feReorderEffectCategories',
                'Reorder effect categories',
              )
            : l10n.tOr(
                'feReorderFilterCategories',
                'Reorder filter categories',
              ),
        items: labels,
        onSave: (reordered) {
          final payload = <CategoryReorderItem>[];
          final mutableLabels = [...labels];
          for (var i = 0; i < reordered.length; i++) {
            final originalIndex = mutableLabels.indexOf(reordered[i]);
            final id =
                originalIndex >= 0 ? ids[originalIndex] : ids[i.clamp(0, ids.length - 1)];
            if (originalIndex >= 0) mutableLabels[originalIndex] = '\u0000$i';
            payload.add(CategoryReorderItem(id: id, sortOrder: i));
          }
          final bloc = context.read<FiltersEffectsBloc>();
          if (widget.isEffectCategory) {
            bloc.add(ReorderCameraEffectCategoriesEvent(payload));
          } else {
            bloc.add(ReorderCameraFilterCategoriesEvent(payload));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final allLabel = widget.isEffectCategory
        ? l10n.tOr('feAllEffects', 'All Effects')
        : l10n.tOr('feAllFilters', 'All Filters');

    final sorted = [...widget.categories]..sort((a, b) {
        final aOrder = widget.isEffectCategory
            ? (a as CameraEffectCategoryEntity).sortOrder
            : (a as CameraFilterCategoryEntity).sortOrder;
        final bOrder = widget.isEffectCategory
            ? (b as CameraEffectCategoryEntity).sortOrder
            : (b as CameraFilterCategoryEntity).sortOrder;
        return aOrder.compareTo(bOrder);
      });

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Listener(
        onPointerSignal: (signal) {
          if (signal is PointerScrollEvent) _onPointerScroll(signal);
        },
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(
                      label: allLabel,
                      selected: widget.selectedCategoryId == null,
                      onTap: () => widget.onCategorySelected(null),
                    ),
                    if (sorted.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 22,
                        color: scheme.outline.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                    ],
                    for (var i = 0; i < sorted.length; i++) ...[
                      _CategoryChip(
                        label: _chipLabel(sorted[i]),
                        category: sorted[i],
                        isEffectCategory: widget.isEffectCategory,
                        selected:
                            widget.selectedCategoryId == _id(sorted[i]),
                        onTap: () {
                          final id = _id(sorted[i]);
                          if (widget.selectedCategoryId == id) {
                            widget.onCategorySelected(null);
                          } else {
                            widget.onCategorySelected(id);
                          }
                        },
                      ),
                      if (i < sorted.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (sorted.length > 1)
              Tooltip(
                message: l10n.tOr('feReorderCategories', 'Reorder'),
                child: Material(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _reorderCategories,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.swap_vert_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            if (sorted.length > 1) const SizedBox(width: 6),
            Tooltip(
              message: widget.isEffectCategory
                  ? l10n.tOr(
                      'feCreateEffectCategory',
                      'Create effect category',
                    )
                  : l10n.tOr(
                      'feCreateFilterCategory',
                      'Create filter category',
                    ),
              child: Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _createCategory,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatefulWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : _hovered
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.category,
    required this.isEffectCategory,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Object category;
  final bool isEffectCategory;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  String get _id => widget.isEffectCategory
      ? (widget.category as CameraEffectCategoryEntity).id
      : (widget.category as CameraFilterCategoryEntity).id;

  Future<void> _onMenu(String action) async {
    final bloc = context.read<FiltersEffectsBloc>();
    final l10n = context.l10n;

    switch (action) {
      case 'edit':
      case 'rename':
        showCategoryFormDialog(
          context,
          isEffectCategory: widget.isEffectCategory,
          editing: widget.category,
        );
      case 'manage':
        showAssignItemsDialog(
          context,
          isEffectCategory: widget.isEffectCategory,
          category: widget.category,
        );
      case 'duplicate':
        final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
        if (widget.isEffectCategory) {
          final c = widget.category as CameraEffectCategoryEntity;
          bloc.add(
            CreateCameraEffectCategoryEvent(
              CreateCategoryRequest(
                slug: '${c.slug}_copy_$stamp',
                label:
                    '${c.label} ${l10n.tOr('feCategoryCopySuffix', 'Copy')}',
                labelKey: c.labelKey,
                sortOrder: c.sortOrder + 1,
                isActive: c.isActive,
              ),
            ),
          );
        } else {
          final c = widget.category as CameraFilterCategoryEntity;
          bloc.add(
            CreateCameraFilterCategoryEvent(
              CreateCategoryRequest(
                slug: '${c.slug}_copy_$stamp',
                label:
                    '${c.label} ${l10n.tOr('feCategoryCopySuffix', 'Copy')}',
                labelKey: c.labelKey,
                sortOrder: c.sortOrder + 1,
                isActive: c.isActive,
              ),
            ),
          );
        }
      case 'delete':
        await showFeConfirmDialog(
          context,
          title: l10n.tOr('feDeleteCategoryTitle', 'Delete category?'),
          message: l10n.tOr(
            'feDeleteCategoryMessage',
            'Memberships are removed; items stay available under All.',
          ),
          onConfirm: () {
            if (widget.isEffectCategory) {
              bloc.add(DeleteCameraEffectCategoryEvent(_id));
            } else {
              bloc.add(DeleteCameraFilterCategoryEvent(_id));
            }
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : _hovered
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 6, 7),
                child: Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.tOr('feCategoryMenu', 'Category actions'),
              padding: EdgeInsets.zero,
              onSelected: _onMenu,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(l10n.tOr('feRenameCategory', 'Rename')),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text(l10n.t('edit')),
                ),
                PopupMenuItem(
                  value: 'manage',
                  child: Text(
                    widget.isEffectCategory
                        ? l10n.tOr('feManageEffects', 'Manage effects')
                        : l10n.tOr('feManageFilters', 'Manage filters'),
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text(l10n.tOr('feDuplicateCategory', 'Duplicate')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.t('delete'),
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(2, 6, 10, 6),
                child: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: selected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderCategoriesDialog extends StatefulWidget {
  const _ReorderCategoriesDialog({
    required this.title,
    required this.items,
    required this.onSave,
  });

  final String title;
  final List<String> items;
  final void Function(List<String> reordered) onSave;

  @override
  State<_ReorderCategoriesDialog> createState() =>
      _ReorderCategoriesDialogState();
}

class _ReorderCategoriesDialogState extends State<_ReorderCategoriesDialog> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: ReorderableListView(
          shrinkWrap: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
          },
          children: [
            for (var i = 0; i < _items.length; i++)
              ListTile(
                key: ValueKey('${_items[i]}-$i'),
                leading: const Icon(Icons.drag_handle_rounded),
                title: Text(_items[i]),
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
          onPressed: () {
            widget.onSave(_items);
            Navigator.of(context).pop();
          },
          child: Text(l10n.tOr('feSaveOrder', 'Save order')),
        ),
      ],
    );
  }
}
