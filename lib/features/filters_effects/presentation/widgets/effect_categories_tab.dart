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
import '../dialogs/category_form_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../utils/filters_effects_responsive.dart';
import 'fe_tab_scaffold.dart';

class EffectCategoriesTab extends StatelessWidget {
  const EffectCategoriesTab({
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

    if (categories.isEmpty) {
      return Center(
        child: EmptyView(
          message: l10n.tOr(
            'feNoEffectCategories',
            'No effect categories found.',
          ),
        ),
      );
    }

    return FeTabScaffold(
      header: Row(
        children: [
          if (canManage)
            FilledButton.icon(
              onPressed: () => showCategoryFormDialog(
                context,
                isEffectCategory: true,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                l10n.tOr('feCreateEffectCategory', 'Create category'),
              ),
            ),
          const Spacer(),
          if (canManage)
            OutlinedButton.icon(
              onPressed: () => _showReorderDialog(context, categories),
              icon: const Icon(Icons.swap_vert_rounded, size: 18),
              label: Text(l10n.tOr('feReorderCategories', 'Reorder')),
            ),
        ],
      ),
      child: ResponsiveDataTable(
        mobileBreakpoint: 900,
        columns: [
          DataColumn(label: Text(l10n.tOr('feColSlug', 'Slug'))),
          DataColumn(label: Text(l10n.tOr('feColLabelKey', 'Label key'))),
          DataColumn(label: Text(l10n.tOr('feColEffectsCount', 'Effects'))),
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
                DataCell(Text('${category.effectsCount}')),
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
              countLabel: l10n.tOr('feColEffectsCount', 'Effects'),
              count: category.effectsCount,
              canManage: canManage,
              onEdit: () => showCategoryFormDialog(
                context,
                isEffectCategory: true,
                editing: category,
              ),
            ),
        ],
      ),
    );
  }

  List<CameraEffectCategoryEntity> _filteredCategories(
    FiltersEffectsLoaded loaded,
  ) {
    final search = loaded.query.search.trim().toLowerCase();
    var items = loaded.effectCategories;
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
    List<CameraEffectCategoryEntity> categories,
  ) async {
    final l10n = context.l10n;
    final sorted = [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final items = sorted.map((c) => c.labelKey).toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => _ReorderCategoriesDialog(
        title: l10n.tOr('feReorderEffectCategories', 'Reorder effect categories'),
        items: items,
        onSave: (reordered) {
          final bloc = context.read<FiltersEffectsBloc>();
          final payload = <CategoryReorderItem>[];
          for (var i = 0; i < reordered.length; i++) {
            final category = sorted.firstWhere((c) => c.labelKey == reordered[i]);
            payload.add(CategoryReorderItem(id: category.id, sortOrder: i));
          }
          bloc.add(ReorderCameraEffectCategoriesEvent(payload));
        },
      ),
    );
  }

  Widget _actionsMenu(
    BuildContext context,
    CameraEffectCategoryEntity category,
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
              isEffectCategory: true,
              editing: category,
            );
          case 'assign':
            showAssignItemsDialog(
              context,
              isEffectCategory: true,
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
                  bloc.add(DeleteCameraEffectCategoryEvent(category.id)),
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
          child: Text(l10n.tOr('feAssignEffects', 'Assign effects')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.tOr('feDelete', 'Delete')),
        ),
      ],
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
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final int count;
  final bool canManage;
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
