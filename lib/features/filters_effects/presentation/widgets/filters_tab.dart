import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../dialogs/fe_item_preview_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../dialogs/filter_form_dialog.dart';
import '../utils/fe_display_filters.dart';
import '../utils/filters_effects_responsive.dart';
import 'fe_filter_form_fields.dart';
import 'fe_selected_category_banner.dart';
import 'fe_tab_scaffold.dart';

Future<void> _openEditor(BuildContext context, {String? filterId}) async {
  final saved = await openFilterEditor(context, filterId: filterId);
  if (!context.mounted) return;
  if (saved == true) {
    context.read<FiltersEffectsBloc>().add(const LoadCameraFilters());
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            filterId == null
                ? l10n.t('feFilterCreatedSuccess')
                : l10n.t('feFilterUpdatedSuccess'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class FiltersTab extends StatelessWidget {
  const FiltersTab({
    super.key,
    required this.loaded,
    required this.metrics,
    this.selectedCategoryId,
    this.onClearCategory,
  });

  final FiltersEffectsLoaded loaded;
  final FiltersEffectsLayoutMetrics metrics;
  final String? selectedCategoryId;
  final VoidCallback? onClearCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canManage = _canManage(context);
    final items = filtersForDisplay(
      pagedFilters: loaded.pagedFilters,
      filterCategories: loaded.filterCategories,
      query: loaded.query,
      selectedCategoryId: selectedCategoryId,
    );
    final selectionEnabled = canManage && !loaded.isBulkDeleting;
    final categorySelected = selectedCategoryId != null;

    CameraFilterCategoryEntity? selectedCategory;
    if (categorySelected) {
      for (final c in loaded.filterCategories) {
        if (c.id == selectedCategoryId) {
          selectedCategory = c;
          break;
        }
      }
    }

    final allVisibleSelected = items.isNotEmpty &&
        items.every((f) => loaded.selectedFilterIds.contains(f.id));
    final someVisibleSelected = items.any(
          (f) => loaded.selectedFilterIds.contains(f.id),
        ) &&
        !allVisibleSelected;

    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedCategory != null) ...[
            FeSelectedCategoryBanner(
              label: selectedCategory.displayLabel,
              itemCount: 0,
              isEffectCategory: false,
              onClear: onClearCategory ?? () {},
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: Center(
              child: EmptyView(
                message: l10n.tOr(
                  'feNoFilters',
                  'No filters match your filters.',
                ),
              ),
            ),
          ),
        ],
      );
    }

    return FeTabScaffold(
      header: selectedCategory == null
          ? null
          : FeSelectedCategoryBanner(
              label: selectedCategory.displayLabel,
              itemCount: items.length,
              isEffectCategory: false,
              onClear: onClearCategory ?? () {},
            ),
      footer: categorySelected
          ? null
          : AppPaginationBar(
              currentPage: loaded.query.page,
              lastPage: loaded.filtersTotalPages,
              total: loaded.filtersTotalCount,
              pageSize: loaded.query.pageSize,
              itemCount: items.length,
              hideWhenSinglePage: false,
              borderRadius: BorderRadius.circular(12),
              onPageChanged: (page) => context.read<FiltersEffectsBloc>().add(
                FiltersEffectsFilterChanged(page: page),
              ),
            ),
      child: ResponsiveDataTable(
        mobileBreakpoint: 900,
        columns: [
          if (selectionEnabled)
            DataColumn(
              label: Checkbox(
                tristate: true,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: allVisibleSelected
                    ? true
                    : someVisibleSelected
                        ? null
                        : false,
                onChanged: (_) {
                  if (!categorySelected) {
                    context.read<FiltersEffectsBloc>().add(
                      const SelectAllVisibleFiltersEvent(),
                    );
                    return;
                  }
                  final bloc = context.read<FiltersEffectsBloc>();
                  for (final filter in items) {
                    final selected =
                        loaded.selectedFilterIds.contains(filter.id);
                    if (allVisibleSelected == selected) {
                      bloc.add(ToggleFilterSelectionEvent(filter.id));
                    }
                  }
                },
              ),
            ),
          DataColumn(label: Text(l10n.tOr('feColThumbnail', 'Thumb'))),
          DataColumn(label: Text(l10n.tOr('feColName', 'Name'))),
          DataColumn(label: Text(l10n.tOr('feColSlug', 'Slug'))),
          DataColumn(label: Text(l10n.tOr('feColRenderType', 'Render type'))),
          DataColumn(label: Text(l10n.tOr('feColStatus', 'Status'))),
          DataColumn(label: Text(l10n.tOr('feColDefaults', 'Defaults'))),
          DataColumn(label: Text(l10n.tOr('feColSortOrder', 'Order'))),
          DataColumn(label: Text(l10n.tOr('feColActions', 'Actions'))),
        ],
        rows: [
          for (final filter in items)
            DataRow(
              selected: loaded.selectedFilterIds.contains(filter.id),
              cells: [
                if (selectionEnabled)
                  DataCell(
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: loaded.selectedFilterIds.contains(filter.id),
                      onChanged: (_) => context.read<FiltersEffectsBloc>().add(
                        ToggleFilterSelectionEvent(filter.id),
                      ),
                    ),
                  ),
                DataCell(_FilterThumb(filter: filter)),
                DataCell(Text(filter.displayLabel)),
                DataCell(Text(filter.slug)),
                DataCell(
                  Text(feFilterRenderTypeLabel(context, filter.renderType)),
                ),
                DataCell(_statusChip(context, filter.isActive)),
                DataCell(Text(_defaultsLabel(context, filter))),
                DataCell(Text('${filter.sortOrder}')),
                DataCell(
                  _FilterActionsMenu(filter: filter, canManage: canManage),
                ),
              ],
            ),
        ],
        mobileCards: [
          for (final filter in items)
            _FilterMobileCard(
              filter: filter,
              canManage: canManage,
              selectionEnabled: selectionEnabled,
              isSelected: loaded.selectedFilterIds.contains(filter.id),
            ),
        ],
      ),
    );
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

  String _defaultsLabel(BuildContext context, CameraFilterEntity filter) {
    final l10n = context.l10n;
    final flags = <String>[];
    if (filter.isOriginal) {
      flags.add(l10n.tOr('feFlagOriginal', 'Original'));
    }
    if (filter.isBeautyDefault) {
      flags.add(l10n.tOr('feFlagBeautyDefault', 'Beauty default'));
    }
    return flags.isEmpty ? '—' : flags.join(', ');
  }
}

class _FilterThumb extends StatelessWidget {
  const _FilterThumb({required this.filter});

  final CameraFilterEntity filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = filter.thumbnailUrl?.trim();
    final resolved = url != null && url.isNotEmpty
        ? resolveMediaUrl(url)
        : null;
    final emoji = filter.emoji?.trim();

    return SizedBox(
      width: 40,
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: resolved != null
            ? Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Center(
                  child: Text(
                    (emoji != null && emoji.isNotEmpty) ? emoji : '•',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
      ),
    );
  }
}

class _FilterActionsMenu extends StatelessWidget {
  const _FilterActionsMenu({required this.filter, required this.canManage});

  final CameraFilterEntity filter;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    if (!canManage) return const SizedBox.shrink();
    final l10n = context.l10n;
    final bloc = context.read<FiltersEffectsBloc>();

    return PopupMenuButton<String>(
      tooltip: l10n.tOr('feActions', 'Actions'),
      onSelected: (action) {
        switch (action) {
          case 'preview':
            showFilterPreviewDialog(context, filter);
          case 'edit':
            _openEditor(context, filterId: filter.id);
          case 'activate':
            bloc.add(ActivateCameraFilterEvent(filter.id));
          case 'deactivate':
            bloc.add(DeactivateCameraFilterEvent(filter.id));
          case 'delete':
            showFeConfirmDialog(
              context,
              title: l10n.tOr('feDeleteFilterTitle', 'Delete filter'),
              message: l10n.tOr(
                'feDeleteFilterMessage',
                'Delete this filter permanently?',
              ),
              onConfirm: () => bloc.add(DeleteCameraFilterEvent(filter.id)),
            );
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'preview',
          child: Text(l10n.tOr('fePreview', 'Preview')),
        ),
        PopupMenuItem(value: 'edit', child: Text(l10n.tOr('feEdit', 'Edit'))),
        PopupMenuItem(
          value: filter.isActive ? 'deactivate' : 'activate',
          child: Text(
            filter.isActive
                ? l10n.tOr('feDeactivate', 'Deactivate')
                : l10n.tOr('feActivate', 'Activate'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(l10n.tOr('feDelete', 'Delete')),
        ),
      ],
    );
  }
}

class _FilterMobileCard extends StatelessWidget {
  const _FilterMobileCard({
    required this.filter,
    required this.canManage,
    required this.selectionEnabled,
    required this.isSelected,
  });

  final CameraFilterEntity filter;
  final bool canManage;
  final bool selectionEnabled;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final defaults = <String>[
      if (filter.isOriginal) l10n.tOr('feFlagOriginal', 'Original'),
      if (filter.isBeautyDefault)
        l10n.tOr('feFlagBeautyDefault', 'Beauty default'),
    ].join(', ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.22)
            : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (selectionEnabled) ...[
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: isSelected,
                    onChanged: (_) => context.read<FiltersEffectsBloc>().add(
                      ToggleFilterSelectionEvent(filter.id),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                _FilterThumb(filter: filter),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        filter.displayLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${filter.slug} · ${feFilterRenderTypeLabel(context, filter.renderType)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _FilterActionsMenu(filter: filter, canManage: canManage),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                DashboardStatusChip(
                  label: filter.isActive
                      ? l10n.tOr('feActive', 'Active')
                      : l10n.tOr('feInactive', 'Inactive'),
                  tone: filter.isActive
                      ? DashboardStatusTone.success
                      : DashboardStatusTone.neutral,
                ),
                if (defaults.isNotEmpty)
                  Text(defaults, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${l10n.tOr('feColSortOrder', 'Order')}: ${filter.sortOrder}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
