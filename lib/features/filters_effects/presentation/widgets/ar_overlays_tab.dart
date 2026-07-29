import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../gifts/domain/enums/gifts_view_type.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../domain/entities/ar_overlay_entities.dart';
import '../bloc/ar_overlays_bloc.dart';
import '../bloc/ar_overlays_event.dart';
import '../bloc/ar_overlays_state.dart';
import '../dialogs/ar_overlay_form_dialog.dart';
import '../dialogs/ar_overlay_preview_dialog.dart';
import '../utils/filters_effects_responsive.dart';
import 'ar_overlay_card.dart';
import 'ar_overlay_table_row.dart';

/// Responsive grid sizing — more columns / taller aspect = smaller cards.
({int columns, double aspectRatio, double spacing}) _overlayGridMetrics(
  double width,
) {
  if (width > 1500) {
    return (columns: 7, aspectRatio: 0.9, spacing: 10);
  }
  if (width > 1200) {
    return (columns: 6, aspectRatio: 0.88, spacing: 10);
  }
  if (width > 980) {
    return (columns: 5, aspectRatio: 0.86, spacing: 10);
  }
  if (width > 760) {
    return (columns: 4, aspectRatio: 0.84, spacing: 10);
  }
  if (width > 560) {
    return (columns: 3, aspectRatio: 0.82, spacing: 8);
  }
  if (width > 360) {
    return (columns: 2, aspectRatio: 0.8, spacing: 8);
  }
  return (columns: 1, aspectRatio: 0.95, spacing: 8);
}

class ArOverlaysTab extends StatefulWidget {
  const ArOverlaysTab({
    super.key,
    required this.metrics,
  });

  final FiltersEffectsLayoutMetrics metrics;

  @override
  State<ArOverlaysTab> createState() => _ArOverlaysTabState();
}

class _ArOverlaysTabState extends State<ArOverlaysTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ArOverlaysBloc>();
    if (bloc.state is ArOverlaysInitial) {
      bloc.add(const LoadArOverlaysEvent());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<ArOverlaysBloc>().add(SearchArOverlaysEvent(query));
      }
    });
  }

  Future<void> _handleCreateOverlay(BuildContext context) async {
    final result = await openArOverlayFormDialog(context);
    if (!context.mounted || result == null) return;
    context.read<ArOverlaysBloc>().add(CreateArOverlayEvent(result));
  }

  Future<void> _handlePreviewOverlay(
    BuildContext context,
    ArOverlayEntity overlay,
  ) {
    return openArOverlayPreviewDialog(context, overlay: overlay);
  }

  Future<void> _handleEditOverlay(
    BuildContext context,
    ArOverlayEntity overlay,
  ) async {
    final result = await openArOverlayFormDialog(context, overlay: overlay);
    if (!context.mounted || result == null) return;
    context.read<ArOverlaysBloc>().add(
          UpdateArOverlayEvent(overlay.id, result),
        );
  }

  Future<void> _handleDeleteOverlay(
    BuildContext context,
    ArOverlayEntity overlay,
  ) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: scheme.error),
            const SizedBox(width: 10),
            Text(l10n.tOr('deleteOverlay', 'Delete Overlay?')),
          ],
        ),
        content: Text(
          l10n.tOr(
            'deleteOverlayConfirm',
            'Are you sure you want to delete "${overlay.label}" (${overlay.id})? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ArOverlaysBloc>().add(DeleteArOverlayEvent(overlay.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canManage = PermissionManager.canManageCameraStudio(context);

    return BlocBuilder<ArOverlaysBloc, ArOverlaysState>(
      builder: (context, state) {
        if (state is ArOverlaysError) {
          return Center(
            child: ErrorView(
              message: state.message,
              retryLabel: l10n.t('retry'),
              onRetry: () => context.read<ArOverlaysBloc>().add(
                    const LoadArOverlaysEvent(),
                  ),
            ),
          );
        }

        final loaded = state is ArOverlaysLoaded ? state : null;
        final isLoading = state is ArOverlaysInitial || state is ArOverlaysLoading;
        final isActioning = loaded?.isActioning ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Toolbar: Search, View Mode Toggle, Create Button
            Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;

                    final searchField = SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: l10n.tOr('searchArOverlays', 'Search AR overlays...'),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    context.read<ArOverlaysBloc>().add(
                                          const SearchArOverlaysEvent(''),
                                        );
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          filled: true,
                          fillColor: scheme.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    );

                    final viewToggle = Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ViewIconButton(
                            icon: Icons.grid_view_rounded,
                            selected: loaded?.viewType != GiftsViewType.list,
                            onTap: () => context.read<ArOverlaysBloc>().add(
                                  const ChangeArOverlaysViewTypeEvent(GiftsViewType.grid),
                                ),
                            tooltip: 'Grid view',
                          ),
                          _ViewIconButton(
                            icon: Icons.view_list_rounded,
                            selected: loaded?.viewType == GiftsViewType.list,
                            onTap: () => context.read<ArOverlaysBloc>().add(
                                  const ChangeArOverlaysViewTypeEvent(GiftsViewType.list),
                                ),
                            tooltip: 'List view',
                          ),
                        ],
                      ),
                    );

                    final createBtn = canManage
                        ? FilledButton.icon(
                            onPressed: isActioning ? null : () => _handleCreateOverlay(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.tOr('createOverlay', 'Create Overlay')),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          )
                        : const SizedBox.shrink();

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          searchField,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              viewToggle,
                              const Spacer(),
                              createBtn,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        viewToggle,
                        if (canManage) ...[
                          const SizedBox(width: 12),
                          createBtn,
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (isActioning) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],

            // Content Area
            Expanded(
              child: isLoading
                  ? _buildSkeletonLoading(context, loaded?.viewType ?? GiftsViewType.grid)
                  : (loaded == null || loaded.filteredOverlays.isEmpty)
                      ? _buildEmptyState(context, canManage)
                      : loaded.viewType == GiftsViewType.list
                          ? _buildListView(context, loaded, canManage)
                          : _buildGridView(context, loaded, canManage),
            ),

            // Pagination Bar
            if (loaded != null && loaded.meta.totalPages > 1) ...[
              const SizedBox(height: 12),
              AppPaginationBar(
                currentPage: loaded.meta.page,
                lastPage: loaded.meta.totalPages,
                total: loaded.meta.total,
                pageSize: loaded.meta.limit,
                onPageChanged: (page) => context.read<ArOverlaysBloc>().add(
                      ChangeArOverlaysPageEvent(page),
                    ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canManage) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.layers_clear_outlined,
                size: 54,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.tOr('noArOverlaysFound', 'No AR Overlays Found'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tOr(
                'noArOverlaysFoundSub',
                'There are no camera studio overlays matching your criteria.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (canManage) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _handleCreateOverlay(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.tOr('createOverlay', 'Create Overlay')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context, GiftsViewType viewType) {
    if (viewType == GiftsViewType.list) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          height: 64,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _overlayGridMetrics(constraints.maxWidth);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: metrics.columns,
            crossAxisSpacing: metrics.spacing,
            mainAxisSpacing: metrics.spacing,
            childAspectRatio: metrics.aspectRatio,
          ),
          itemCount: 8,
          itemBuilder: (context, index) => const ArOverlaySkeletonCard(),
        );
      },
    );
  }

  Widget _buildGridView(
    BuildContext context,
    ArOverlaysLoaded state,
    bool canManage,
  ) {
    final items = state.filteredOverlays;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _overlayGridMetrics(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: metrics.columns,
            crossAxisSpacing: metrics.spacing,
            mainAxisSpacing: metrics.spacing,
            childAspectRatio: metrics.aspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final overlay = items[index];
            return ArOverlayCard(
              key: ValueKey(overlay.id),
              overlay: overlay,
              onPreview: () => _handlePreviewOverlay(context, overlay),
              onEdit:
                  canManage ? () => _handleEditOverlay(context, overlay) : null,
              onDelete: canManage
                  ? () => _handleDeleteOverlay(context, overlay)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildListView(
    BuildContext context,
    ArOverlaysLoaded state,
    bool canManage,
  ) {
    final items = state.filteredOverlays;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final overlay = items[index];
            return ArOverlayTableRow(
              key: ValueKey(overlay.id),
              overlay: overlay,
              onPreview: () => _handlePreviewOverlay(context, overlay),
              onEdit:
                  canManage ? () => _handleEditOverlay(context, overlay) : null,
              onDelete: canManage
                  ? () => _handleDeleteOverlay(context, overlay)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _ViewIconButton extends StatelessWidget {
  const _ViewIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
