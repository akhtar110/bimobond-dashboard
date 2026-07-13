import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/toolbar_filter_dropdown.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/promotion_entities.dart';
import '../bloc/packages_bloc.dart';
import '../utils/promotions_responsive.dart';
import '../widgets/package_dialog.dart';
import '../widgets/packages_table.dart';
import '../widgets/promotions_dashboard_widgets.dart';
import '../widgets/promotions_data_display_widgets.dart';
import '../widgets/promotions_shared_widgets.dart';

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<PackagesBloc, PackagesState>(
      listenWhen: (previous, current) {
        if (current is! PackagesLoaded || current.message == null) return false;
        if (previous is! PackagesLoaded) return true;
        return previous.message != current.message;
      },
      listener: (context, state) {
        if (state is! PackagesLoaded || state.message == null) return;
        final raw = state.message!;
        final text = raw.startsWith('promo')
            ? context.l10n.tOr(raw, raw)
            : raw;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            backgroundColor:
                state.isError ? Theme.of(context).colorScheme.error : null,
          ),
        );
      },
      builder: (context, state) {
        final isLoading = state is PackagesLoading;
        final isInitial = state is PackagesInitial;
        final errorMessage = switch (state) {
          PackagesError(:final message) => message,
          _ => null,
        };
        final loaded = state is PackagesLoaded ? state : null;
        final showProgress = isLoading ||
            isInitial ||
            (loaded != null && (loaded.isSaving || loaded.isRefreshing));
        final visible = loaded?.visiblePackages ?? const <PromotionPackageEntity>[];
        final isEmpty = loaded != null && visible.isEmpty;
        final dateFmt = DateFormat.yMMMd();
        final canWrite = context.select<AuthBloc, bool>((b) {
          final auth = b.state;
          if (auth is Authenticated) return canWritePromotions(auth.user.roles);
          return false;
        });

        return PromotionsDashboardShell(
          child: Builder(
            builder: (context) {
              final metrics = promotionsMetricsOf(context);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PackagesHeader(
                    canWrite: canWrite,
                    isSaving: loaded?.isSaving == true,
                    onCreate: () => _openDialog(context, null),
                    onRefresh: () =>
                        context.read<PackagesBloc>().add(LoadPackagesEvent()),
                  ),
                  SizedBox(height: metrics.sectionGap),
                  if (loaded != null) ...[
                    _PackagesSummaryStrip(state: loaded),
                    SizedBox(height: metrics.sectionGap),
                  ],
                  _PackagesToolbar(canWrite: canWrite),
                  if (showProgress) ...[
                    SizedBox(height: metrics.sectionGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(
                    height: metrics.isMobile
                        ? PromotionsSpace.md
                        : PromotionsSpace.lg,
                  ),
                  if (canWrite && loaded != null && loaded.selectedCount > 0) ...[
                    BulkActionToolbar(
                      selectedCount: loaded.selectedCount,
                      allVisibleSelected: loaded.allVisibleSelected,
                      someVisibleSelected: loaded.someVisibleSelected,
                      onSelectAll: () => context
                          .read<PackagesBloc>()
                          .add(SelectAllVisiblePackagesEvent()),
                      onClear: () => context
                          .read<PackagesBloc>()
                          .add(ClearPackageSelectionEvent()),
                      actions: [
                        FilledButton.tonal(
                          onPressed: loaded.isSaving
                              ? null
                              : () => context
                                  .read<PackagesBloc>()
                                  .add(BulkActivatePackagesEvent()),
                          child: Text(
                            l10n.tOr(
                              'promoBulkActivatePackages',
                              'Activate selected',
                            ),
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: loaded.isSaving
                              ? null
                              : () => context
                                  .read<PackagesBloc>()
                                  .add(BulkDeactivatePackagesEvent()),
                          child: Text(
                            l10n.tOr(
                              'promoBulkDeactivatePackages',
                              'Deactivate selected',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.sectionGap),
                  ],
                  PromotionsDataSection(
                    child: PromotionsDataBody(
                      isLoading: isLoading || isInitial,
                      errorMessage: errorMessage,
                      onRetry: () =>
                          context.read<PackagesBloc>().add(LoadPackagesEvent()),
                      isEmpty: isEmpty,
                      emptyMessage: loaded?.hasActiveFilters == true
                          ? l10n.tOr(
                              'promoPackagesNoSearchResults',
                              'No packages match your search or filters.',
                            )
                          : l10n.t('noData'),
                      child: loaded == null
                          ? const SizedBox.shrink()
                          : PackagesTable(
                              packages: visible,
                              dateFmt: dateFmt,
                              selectedIds: loaded.selectedIds,
                              isSaving: loaded.isSaving,
                              canWrite: canWrite,
                              onEdit: (pkg) => _openDialog(context, pkg),
                              onToggleActive: (pkg, {required activate}) =>
                                  _confirmToggle(
                                    context,
                                    pkg,
                                    activate: activate,
                                  ),
                              onDelete: (pkg) => _confirmDelete(context, pkg),
                              onToggleSelect: (id) => context
                                  .read<PackagesBloc>()
                                  .add(TogglePackageSelectionEvent(id)),
                              onSelectAllVisible: () => context
                                  .read<PackagesBloc>()
                                  .add(SelectAllVisiblePackagesEvent()),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    PromotionPackageEntity pkg, {
    required bool activate,
  }) async {
    final l10n = context.l10n;
    if (!activate) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.t('deactivate')),
          content: Text(
            l10n.tOr(
              'promoPackageDeactivateConfirm',
              'Deactivate "${pkg.name}"? It will no longer be available for new campaigns.',
            ).replaceAll('{name}', pkg.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.t('deactivate')),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    context.read<PackagesBloc>().add(
          TogglePackageActiveEvent(pkg.id, activate: activate),
        );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PromotionPackageEntity pkg,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('delete')),
        content: Text(
          l10n.tOr(
            'promoPackageDeleteConfirm',
            'Delete "{name}"? This cannot be undone.',
          ).replaceAll('{name}', pkg.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<PackagesBloc>().add(DeletePackageEvent(pkg.id));
  }

  Future<void> _openDialog(
    BuildContext context,
    PromotionPackageEntity? existing,
  ) async {
    final data = await showPackageDialog(context, existing: existing);
    if (data == null || !context.mounted) return;
    final bloc = context.read<PackagesBloc>();
    if (existing == null) {
      bloc.add(CreatePackageEvent(data.createData));
    } else {
      bloc.add(UpdatePackageEvent(existing.id, data.updateData));
    }
  }
}

class _PackagesHeader extends StatelessWidget {
  const _PackagesHeader({
    required this.canWrite,
    required this.isSaving,
    required this.onCreate,
    required this.onRefresh,
  });

  final bool canWrite;
  final bool isSaving;
  final VoidCallback onCreate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = promotionsMetricsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final title = Text(
          l10n.t('promoPackagesTitle'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: metrics.isMobile ? 20 : null,
              ),
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.t('refresh'),
              onPressed: isSaving ? null : onRefresh,
              icon: Icon(
                Icons.refresh_rounded,
                size: metrics.isMobile ? 20 : 22,
              ),
            ),
            if (canWrite) ...[
              SizedBox(width: metrics.toolbarFilterGap),
              FilledButton.icon(
                onPressed: isSaving ? null : onCreate,
                icon: Icon(Icons.add, size: metrics.isMobile ? 18 : 22),
                label: metrics.isMobile && stacked
                    ? const SizedBox.shrink()
                    : Text(l10n.t('create')),
                style: FilledButton.styleFrom(
                  minimumSize: Size(
                    metrics.isMobile ? 44 : 120,
                    metrics.isMobile ? 40 : 44,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.isMobile && stacked ? 0 : 16,
                  ),
                ),
              ),
            ],
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            actions,
          ],
        );
      },
    );
  }
}

class _PackagesSummaryStrip extends StatelessWidget {
  const _PackagesSummaryStrip({required this.state});

  final PackagesLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = promotionsMetricsOf(context);
    final number = NumberFormat.compact();

    return Wrap(
      spacing: metrics.toolbarFilterGap,
      runSpacing: metrics.toolbarFilterGap,
      children: [
        _SummaryChip(
          icon: Icons.inventory_2_outlined,
          label: l10n.tOr('promoPackagesTotal', 'Total'),
          value: number.format(state.totalCount),
        ),
        _SummaryChip(
          icon: Icons.check_circle_outline,
          label: l10n.t('active'),
          value: number.format(state.activeCount),
        ),
        _SummaryChip(
          icon: Icons.pause_circle_outline,
          label: l10n.t('inactive'),
          value: number.format(state.inactiveCount),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PackagesToolbar extends StatelessWidget {
  const _PackagesToolbar({required this.canWrite});

  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<PackagesBloc, PackagesState,
        ({String search, PackageStatusFilter status, bool hasFilters})>(
      selector: (state) {
        if (state is! PackagesLoaded) {
          return (
            search: '',
            status: PackageStatusFilter.all,
            hasFilters: false,
          );
        }
        return (
          search: state.search,
          status: state.statusFilter,
          hasFilters: state.hasActiveFilters,
        );
      },
      builder: (context, toolbar) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final metrics = PromotionsLayoutMetrics(
              getPromotionsDeviceType(constraints.maxWidth),
            );
            final narrow = constraints.maxWidth < 720;
            final controlHeight = metrics.filterControlHeight;
            final gap = metrics.toolbarFilterGap;

            final search = PromotionsToolbarSearchField(
              hint: l10n.tOr(
                'promoSearchPackages',
                'Search package name…',
              ),
              initialValue: toolbar.search,
              height: controlHeight,
              compact: metrics.isMobile,
              onChanged: (q) =>
                  context.read<PackagesBloc>().add(SearchPackagesEvent(q)),
            );

            final status = ToolbarFilterDropdown<PackageStatusFilter>(
              hint: l10n.t('status'),
              value: toolbar.status,
              height: controlHeight,
              items: PackageStatusFilter.values,
              itemLabel: (v) => switch (v) {
                PackageStatusFilter.all => l10n.t('all'),
                PackageStatusFilter.active => l10n.t('active'),
                PackageStatusFilter.inactive => l10n.t('inactive'),
              },
              onChanged: (v) {
                if (v == null) return;
                context
                    .read<PackagesBloc>()
                    .add(FilterPackageStatusEvent(v));
              },
            );

            final clearButton = toolbar.hasFilters
                ? IconButton(
                    tooltip: l10n.t('clearFilters'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context
                        .read<PackagesBloc>()
                        .add(ClearPackageFiltersEvent()),
                    icon: Icon(
                      Icons.filter_alt_off_outlined,
                      size: metrics.isMobile ? 16 : 18,
                      color: scheme.error,
                    ),
                  )
                : null;

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  SizedBox(height: gap),
                  Row(
                    children: [
                      Expanded(child: status),
                      if (clearButton != null) ...[
                        SizedBox(width: gap),
                        clearButton,
                      ],
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: search),
                SizedBox(width: gap),
                SizedBox(width: 160, child: status),
                if (clearButton != null) ...[
                  SizedBox(width: gap),
                  clearButton,
                ],
                if (!canWrite) const SizedBox.shrink(),
              ],
            );
          },
        );
      },
    );
  }
}
