import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_button.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';
import '../utils/responsive.dart';
import '../utils/users_export_service.dart';
import 'users_filter_bar.dart';
import 'users_filter_popup.dart';
import 'users_sort_dropdown.dart';

/// Responsive users toolbar — matches posts layout with PDF, Excel, CSV Export button.
class UsersPageToolbar extends StatelessWidget {
  const UsersPageToolbar({super.key, required this.metrics});

  final UsersLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final controlHeight = metrics.filterControlHeight;
    final gap = metrics.filterGap + 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final inline = metrics.toolbarInlineAt(width);

        return _UsersToolbarRow(
          metrics: metrics,
          controlHeight: controlHeight,
          gap: gap,
          availableWidth: width,
          inline: inline,
        );
      },
    );
  }
}

class _UsersToolbarRow extends StatelessWidget {
  const _UsersToolbarRow({
    required this.metrics,
    required this.controlHeight,
    required this.gap,
    required this.availableWidth,
    required this.inline,
  });

  final UsersLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final double availableWidth;
  final bool inline;

  Widget _searchField() {
    return UsersFilterBar(
      metrics: metrics,
      height: controlHeight,
    );
  }

  void _openFilters(
    BuildContext context, {
    required UsersUiFilter statusFilter,
    required String locationQuery,
    String? role,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    showUsersFilterPopup(
      context: context,
      statusFilter: statusFilter,
      locationQuery: locationQuery,
      roleFilter: role,
      createdFrom: createdFrom,
      createdTo: createdTo,
      anchorRect: Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersBloc, UsersState>(
      listenWhen: (prev, next) {
        if (next is UsersLoaded && next.exportMessage != null) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is UsersLoaded && state.exportMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.exportMessage!),
              backgroundColor: state.exportIsError
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 4),
            ),
          );
          context.read<UsersBloc>().add(ClearUsersExportFeedbackEvent());
        }
      },
      child: BlocSelector<
          UsersBloc,
          UsersState,
          ({
            UsersUiFilter status,
            String location,
            String? role,
            DateTime? createdFrom,
            DateTime? createdTo,
            bool isExporting,
          })>(
        selector: (state) {
          final bloc = context.read<UsersBloc>();
          if (state is UsersLoaded) {
            return (
              status: state.filter,
              location: state.locationQuery,
              role: state.role,
              createdFrom: state.createdFrom,
              createdTo: state.createdTo,
              isExporting: state.isExporting,
            );
          }
          return (
            status: bloc.activeFilter,
            location: bloc.activeLocationQuery,
            role: bloc.activeRole,
            createdFrom: bloc.activeCreatedFrom,
            createdTo: bloc.activeCreatedTo,
            isExporting: false,
          );
        },
        builder: (context, filters) {
          final l10n = context.l10n;
          final isSmallScreen = availableWidth < 520;
          final activeCount = usersAppliedFilterCount(
            filter: filters.status,
            locationQuery: filters.location,
            role: filters.role,
            createdFrom: filters.createdFrom,
            createdTo: filters.createdTo,
          );

          final actionsList = [
            UsersSortDropdown(height: controlHeight),
            SizedBox(width: gap),
            Builder(
              builder: (buttonContext) {
                return PostsFilterButton(
                  activeCount: activeCount,
                  height: controlHeight,
                  iconOnly: true,
                  onPressed: () => _openFilters(
                    buttonContext,
                    statusFilter: filters.status,
                    locationQuery: filters.location,
                    role: filters.role,
                    createdFrom: filters.createdFrom,
                    createdTo: filters.createdTo,
                  ),
                );
              },
            ),
            SizedBox(width: gap),
            UsersExportButton(
              height: controlHeight,
              isExporting: filters.isExporting,
            ),
            SizedBox(width: gap),
            SizedBox(
              height: controlHeight,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.tOr('addUserWorkflowInitiated', 'Add User workflow initiated'),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  isSmallScreen && availableWidth < 380
                      ? l10n.tOr('add', 'Add')
                      : l10n.tOr('addUser', 'Add User'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ];

          final actionsWidget = isSmallScreen
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actionsList,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actionsList,
                );

          if (inline) {
            final actionsWidth = (controlHeight * 3) + (gap * 2);
            final searchWidth = (availableWidth - actionsWidth)
                .clamp(120.0, metrics.inlineSearchWidthFor(availableWidth));
            return SizedBox(
              height: controlHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: searchWidth,
                        minWidth: 120,
                        minHeight: controlHeight,
                        maxHeight: controlHeight,
                      ),
                      child: _searchField(),
                    ),
                  ),
                  SizedBox(width: gap),
                  actionsWidget,
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: controlHeight, child: _searchField()),
              SizedBox(height: gap),
              SizedBox(
                height: controlHeight,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actionsWidget,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Export Button with PDF, Excel, and CSV options.
class UsersExportButton extends StatelessWidget {
  const UsersExportButton({
    super.key,
    required this.height,
    required this.isExporting,
  });

  final double height;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (isExporting) {
      return Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.tOr('exporting', 'Exporting...'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<UsersExportFormat>(
      tooltip: l10n.tOr('export', 'Export'),
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      onSelected: (format) {
        context.read<UsersBloc>().add(ExportUsersEvent(format: format));
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: UsersExportFormat.excel,
          child: Row(
            children: [
              const Icon(Icons.table_chart_rounded, size: 18, color: Colors.green),
              const SizedBox(width: 10),
              Text(l10n.tOr('exportToExcel', 'Export to Excel (.xlsx)')),
            ],
          ),
        ),
        PopupMenuItem(
          value: UsersExportFormat.csv,
          child: Row(
            children: [
              const Icon(Icons.description_rounded, size: 18, color: Colors.blue),
              const SizedBox(width: 10),
              Text(l10n.tOr('exportToCsv', 'Export to CSV (.csv)')),
            ],
          ),
        ),
        PopupMenuItem(
          value: UsersExportFormat.pdf,
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.red),
              const SizedBox(width: 10),
              Text(l10n.tOr('exportToPdf', 'Export to PDF (.pdf)')),
            ],
          ),
        ),
      ],
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.file_download_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.tOr('export', 'Export'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dismissible chips for active user filters (excludes search).
class UsersActiveFilterChips extends StatelessWidget {
  const UsersActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<UsersBloc, UsersState>(
      buildWhen: (prev, next) {
        if (prev is UsersLoaded && next is UsersLoaded) {
          return prev.filter != next.filter ||
              prev.locationQuery != next.locationQuery ||
              prev.role != next.role ||
              prev.createdFrom != next.createdFrom ||
              prev.createdTo != next.createdTo ||
              prev.locationSort != next.locationSort;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! UsersLoaded) return const SizedBox.shrink();

        final chips = <Widget>[];

        if (state.filter != UsersUiFilter.all) {
          chips.add(
            _ActiveFilterChip(
              label: usersStatusLabel(l10n, state.filter),
              onRemove: () => context
                  .read<UsersBloc>()
                  .add(FilterUsersEvent(UsersUiFilter.all)),
            ),
          );
        }

        if (state.role != null && state.role!.isNotEmpty) {
          chips.add(
            _ActiveFilterChip(
              label: 'Role: ${state.role!}',
              onRemove: () {
                final bloc = context.read<UsersBloc>();
                bloc.add(
                  ApplyUsersListFiltersEvent(
                    search: bloc.activeQuery,
                    location: bloc.activeLocationQuery,
                    role: null,
                    createdFrom: bloc.activeCreatedFrom,
                    createdTo: bloc.activeCreatedTo,
                  ),
                );
              },
            ),
          );
        }

        if (state.createdFrom != null || state.createdTo != null) {
          final df = DateFormat('yyyy-MM-dd');
          final label = state.createdFrom != null && state.createdTo != null
              ? '${df.format(state.createdFrom!)} - ${df.format(state.createdTo!)}'
              : state.createdFrom != null
                  ? 'From ${df.format(state.createdFrom!)}'
                  : 'Until ${df.format(state.createdTo!)}';
          chips.add(
            _ActiveFilterChip(
              label: label,
              onRemove: () {
                final bloc = context.read<UsersBloc>();
                bloc.add(
                  ApplyUsersListFiltersEvent(
                    search: bloc.activeQuery,
                    location: bloc.activeLocationQuery,
                    role: bloc.activeRole,
                    createdFrom: null,
                    createdTo: null,
                  ),
                );
              },
            ),
          );
        }

        if (state.locationQuery.isNotEmpty) {
          chips.add(
            _ActiveFilterChip(
              label: state.locationQuery,
              onRemove: () {
                final bloc = context.read<UsersBloc>();
                bloc.add(
                  ApplyUsersListFiltersEvent(
                    search: bloc.activeQuery,
                    location: '',
                    role: bloc.activeRole,
                    createdFrom: bloc.activeCreatedFrom,
                    createdTo: bloc.activeCreatedTo,
                  ),
                );
              },
            ),
          );
        }

        if (state.locationSort != UsersSortDropdown.defaultSort) {
          chips.add(
            _ActiveFilterChip(
              label: usersLocationSortLabel(l10n, state.locationSort),
              onRemove: () => context.read<UsersBloc>().add(
                    SetUsersLocationSortEvent(UsersSortDropdown.defaultSort),
                  ),
            ),
          );
        }

        if (chips.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...chips,
              TextButton(
                onPressed: () =>
                    context.read<UsersBloc>().add(ClearUsersListFiltersEvent()),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.t('clearAllFilters'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
