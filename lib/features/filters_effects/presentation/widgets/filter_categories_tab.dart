import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/assign_items_dialog.dart';
import '../dialogs/category_filters_dialog.dart';
import '../dialogs/category_form_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../utils/filters_effects_responsive.dart';
import 'fe_tab_scaffold.dart';

class FilterCategoriesTab extends StatelessWidget {
  const FilterCategoriesTab({
    super.key,
    required this.loaded,
    required this.metrics,
  });

  final FiltersEffectsLoaded loaded;
  final FiltersEffectsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canManage = _canManage(context);
    final categories = _filteredCategories(loaded);
    final dateFmt = DateFormat.yMMMd();

    return FeTabScaffold(
      header: _CategoryTabHeader(
        canManage: canManage,
        showReorder: categories.length > 1,
        createLabel: l10n.tOr('feCreateFilterCategory', 'Create filter category'),
        onCreate: () => showCategoryFormDialog(
          context,
          isEffectCategory: false,
        ),
        onReorder: categories.isEmpty
            ? null
            : () => _showReorderDialog(context, categories),
      ),
      child: categories.isEmpty
          ? Center(
              child: EmptyView(
                message: l10n.tOr(
                  'feNoFilterCategories',
                  'No filter categories found.',
                ),
              ),
            )
          : ResponsiveDataTable(
        mobileBreakpoint: 900,
        columns: [
          DataColumn(label: Text(l10n.tOr('feColSlug', 'Slug'))),
          DataColumn(label: Text(l10n.tOr('feColLabelKey', 'Label key'))),
          DataColumn(label: Text(l10n.tOr('feColFiltersCount', 'Filters'))),
          DataColumn(label: Text(l10n.tOr('feColSortOrder', 'Order'))),
          DataColumn(label: Text(l10n.tOr('feColStatus', 'Status'))),
          DataColumn(label: Text(l10n.tOr('feColUpdated', 'Updated'))),
          DataColumn(label: Text(l10n.tOr('feColActions', 'Actions'))),
        ],
        rows: [
          for (final category in categories)
            DataRow(
              cells: [
                DataCell(Text(category.slug)),
                DataCell(Text(category.labelKey)),
                DataCell(
                  _FiltersCountCell(
                    count: category.filtersCount,
                    onTap: () => showCategoryFiltersDialog(context, category),
                  ),
                ),
                DataCell(Text('${category.sortOrder}')),
                DataCell(_statusChip(context, category.isActive)),
                DataCell(Text(
                  category.updatedAt != null
                      ? dateFmt.format(category.updatedAt!.toLocal())
                      : '—',
                )),
                DataCell(_actionsMenu(context, category, canManage)),
              ],
            ),
        ],
        mobileCards: [
          for (final category in categories)
            _CategoryMobileCard(
              title: category.labelKey,
              subtitle: category.slug,
              countLabel: l10n.tOr('feColFiltersCount', 'Filters'),
              count: category.filtersCount,
              canManage: canManage,
              onTap: () => showCategoryFiltersDialog(context, category),
              onEdit: () => showCategoryFormDialog(
                context,
                isEffectCategory: false,
                editing: category,
              ),
            ),
        ],
      ),
    );
  }

  List<CameraFilterCategoryEntity> _filteredCategories(
    FiltersEffectsLoaded loaded,
  ) {
    final search = loaded.query.search.trim().toLowerCase();
    var items = loaded.filterCategories;
    if (search.isNotEmpty) {
      items = items
          .where(
            (c) =>
                c.slug.toLowerCase().contains(search) ||
                c.labelKey.toLowerCase().contains(search),
          )
          .toList();
    }
    return items;
  }

  bool _canManage(BuildContext context) {
    final roles = context.select<AuthBloc, List<UserRole>>((b) {
      final state = b.state;
      if (state is Authenticated) return state.user.roles;
      return const <UserRole>[];
    });
    return canManageFiltersEffects(roles);
  }

  Widget _statusChip(BuildContext context, bool isActive) {
    final l10n = context.l10n;
    return DashboardStatusChip(
      label: isActive
          ? l10n.tOr('feActive', 'Active')
          : l10n.tOr('feInactive', 'Inactive'),
      tone: isActive ? DashboardStatusTone.success : DashboardStatusTone.neutral,
    );
  }

  Future<void> _showReorderDialog(
    BuildContext context,
    List<CameraFilterCategoryEntity> categories,
  ) async {
    final l10n = context.l10n;
    final sorted = [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final items = sorted.map((c) => c.labelKey).toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => _ReorderCategoriesDialog(
        title: l10n.tOr('feReorderFilterCategories', 'Reorder filter categories'),
        items: items,
        onSave: (reordered) {
          final bloc = context.read<FiltersEffectsBloc>();
          final payload = <CategoryReorderItem>[];
          for (var i = 0; i < reordered.length; i++) {
            final category = sorted.firstWhere((c) => c.labelKey == reordered[i]);
            payload.add(CategoryReorderItem(id: category.id, sortOrder: i));
          }
          bloc.add(ReorderCameraFilterCategoriesEvent(payload));
        },
      ),
    );
  }

  Widget _actionsMenu(
    BuildContext context,
    CameraFilterCategoryEntity category,
    bool canManage,
  ) {
    if (!canManage) return const SizedBox.shrink();
    final l10n = context.l10n;
    final bloc = context.read<FiltersEffectsBloc>();

    return PopupMenuButton<String>(
      onSelected: (action) {
        switch (action) {
          case 'edit':
            showCategoryFormDialog(
              context,
              isEffectCategory: false,
              editing: category,
            );
          case 'assign':
            showAssignItemsDialog(
              context,
              isEffectCategory: false,
              category: category,
            );
          case 'delete':
            showFeConfirmDialog(
              context,
              title: l10n.tOr('feDeleteCategoryTitle', 'Delete category'),
              message: l10n.tOr(
                'feDeleteCategoryMessage',
                'Delete this category?',
              ),
              onConfirm: () =>
                  bloc.add(DeleteCameraFilterCategoryEvent(category.id)),
            );
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Text(l10n.tOr('feEdit', 'Edit')),
        ),
        PopupMenuItem(
          value: 'assign',
          child: Text(l10n.tOr('feAssignFilters', 'Assign filters')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.tOr('feDelete', 'Delete')),
        ),
      ],
    );
  }
}

class _CategoryTabHeader extends StatelessWidget {
  const _CategoryTabHeader({
    required this.canManage,
    required this.showReorder,
    required this.createLabel,
    required this.onCreate,
    this.onReorder,
  });

  final bool canManage;
  final bool showReorder;
  final String createLabel;
  final VoidCallback onCreate;
  final VoidCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    if (!canManage) return const SizedBox.shrink();
    final l10n = context.l10n;

    return Row(
      children: [
        const Spacer(),
        if (showReorder && onReorder != null) ...[
          OutlinedButton.icon(
            onPressed: onReorder,
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label: Text(l10n.tOr('feReorderCategories', 'Reorder')),
          ),
          const SizedBox(width: 8),
        ],
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(createLabel),
        ),
      ],
    );
  }
}

class _FiltersCountCell extends StatelessWidget {
  const _FiltersCountCell({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryMobileCard extends StatelessWidget {
  const _CategoryMobileCard({
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.count,
    required this.canManage,
    required this.onTap,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final int count;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: Text('$subtitle · $countLabel: $count'),
        trailing: canManage
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              )
            : null,
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
                key: ValueKey(_items[i]),
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
