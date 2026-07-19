import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
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
import '../dialogs/fe_item_preview_dialog.dart';
import '../dialogs/fe_confirm_dialog.dart';
import '../dialogs/filter_form_dialog.dart';
import '../utils/filters_effects_responsive.dart';
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
  });

  final FiltersEffectsLoaded loaded;
  final FiltersEffectsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canManage = _canManage(context);
    final items = loaded.pagedFilters;
    final dateFmt = DateFormat.yMMMd();

    if (loaded.filteredFilters.isEmpty) {
      return Center(
        child: EmptyView(
          message: l10n.tOr('feNoFilters', 'No filters match your filters.'),
        ),
      );
    }

    return FeTabScaffold(
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canManage)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.tOr('feCreateFilter', 'Create filter')),
              ),
            ),
          if (canManage) SizedBox(height: metrics.filterGap),
        ],
      ),
      footer: AppPaginationBar(
        currentPage: loaded.query.page,
        lastPage: loaded.filtersTotalPages,
        total: loaded.filteredFilters.length,
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
          DataColumn(label: Text(l10n.tOr('feColSlug', 'Slug'))),
          DataColumn(label: Text(l10n.tOr('feColEngineKey', 'Engine key'))),
          DataColumn(label: Text(l10n.tOr('feColLabel', 'Label'))),
          DataColumn(label: Text(l10n.tOr('feColStatus', 'Status'))),
          DataColumn(label: Text(l10n.tOr('feColFlags', 'Flags'))),
          DataColumn(label: Text(l10n.tOr('feColSortOrder', 'Order'))),
          DataColumn(label: Text(l10n.tOr('feColUpdated', 'Updated'))),
          DataColumn(label: Text(l10n.tOr('feColActions', 'Actions'))),
        ],
        rows: [
          for (final filter in items)
            DataRow(
              cells: [
                DataCell(Text(filter.slug)),
                DataCell(Text(filter.engineKey)),
                DataCell(Text(filter.displayLabel)),
                DataCell(_statusChip(context, filter.isActive)),
                DataCell(Text(_flagsLabel(context, filter))),
                DataCell(Text('${filter.sortOrder}')),
                DataCell(Text(
                  filter.updatedAt != null
                      ? dateFmt.format(filter.updatedAt!.toLocal())
                      : '—',
                )),
                DataCell(_actionsMenu(context, filter, canManage)),
              ],
            ),
        ],
        mobileCards: [
          for (final filter in items)
            _FilterMobileCard(
              filter: filter,
              canManage: canManage,
              dateFmt: dateFmt,
            ),
        ],
      ),
    );
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

  String _flagsLabel(BuildContext context, CameraFilterEntity filter) {
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

  Widget _actionsMenu(
    BuildContext context,
    CameraFilterEntity filter,
    bool canManage,
  ) {
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
        PopupMenuItem(
          value: 'edit',
          child: Text(l10n.tOr('feEdit', 'Edit')),
        ),
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
    required this.dateFmt,
  });

  final CameraFilterEntity filter;
  final bool canManage;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              filter.displayLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text('${filter.slug} · ${filter.engineKey}'),
            if (filter.updatedAt != null)
              Text(
                dateFmt.format(filter.updatedAt!.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (canManage) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => _openEditor(context, filterId: filter.id),
                  child: Text(l10n.tOr('feEdit', 'Edit')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
