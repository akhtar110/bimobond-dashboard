import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
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
                DataColumn(label: Text(l10n.tOr('feColName', 'Name'))),
                DataColumn(label: Text(l10n.tOr('feColLabelKey', 'Label key'))),
                DataColumn(
                  label: Text(l10n.tOr('feColFiltersCount', 'Filters')),
                ),
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
                      DataCell(Text(category.displayLabel)),
                      DataCell(
                        Text(
                          category.labelKey?.trim().isNotEmpty == true
                              ? category.labelKey!
                              : '—',
                        ),
                      ),
                      DataCell(
                        _FiltersCountCell(
                          count: category.filtersCount,
                          onTap: () =>
                              showCategoryFiltersDialog(context, category),
                        ),
                      ),
                      DataCell(Text('${category.sortOrder}')),
                      DataCell(_statusChip(context, category.isActive)),
                      DataCell(
                        Text(
                          category.updatedAt != null
                              ? dateFmt.format(category.updatedAt!.toLocal())
                              : '—',
                        ),
                      ),
                      DataCell(_actionsMenu(context, category, canManage)),
                    ],
                  ),
              ],
              mobileCards: [
                for (final category in categories)
                  _CategoryMobileCard(
                    title: category.displayLabel,
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
                c.displayLabel.toLowerCase().contains(search) ||
                (c.labelKey?.toLowerCase().contains(search) ?? false),
          )
          .toList();
    }
    return items;
  }

  bool _canManage(BuildContext context) {
    context.select<RbacBloc, Set<String>?>(
      (b) => b.state.authContext?.permissionKeys,
    );
    return PermissionManager.canManageCameraStudio(context);
  }

  Widget _statusChip(BuildContext context, bool isActive) {
    final l10n = context.l10n;
    return DashboardStatusChip(
      label: isActive
          ? l10n.tOr('feActive', 'Active')
          : l10n.tOr('feInactive', 'Inactive'),
      tone: isActive
          ? DashboardStatusTone.success
          : DashboardStatusTone.neutral,
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
        PopupMenuItem(value: 'edit', child: Text(l10n.tOr('feEdit', 'Edit'))),
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

class _FiltersCountCell extends StatelessWidget {
  const _FiltersCountCell({required this.count, required this.onTap});

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
            Icon(Icons.open_in_new_rounded, size: 16, color: scheme.primary),
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
