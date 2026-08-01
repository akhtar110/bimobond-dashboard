import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_button.dart';
import '../bloc/users_bloc.dart';
import '../users_ui_filter.dart';
import '../utils/responsive.dart';
import 'users_filter_bar.dart';
import 'users_filter_popup.dart';
import 'users_sort_dropdown.dart';

/// Responsive users toolbar — matches posts layout.
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
  }) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    showUsersFilterPopup(
      context: context,
      statusFilter: statusFilter,
      locationQuery: locationQuery,
      anchorRect: Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        UsersBloc,
        UsersState,
        ({UsersUiFilter status, String location})>(
      selector: (state) {
        final bloc = context.read<UsersBloc>();
        return (
          status: state is UsersLoaded
              ? state.filter
              : bloc.activeFilter,
          location: state is UsersLoaded
              ? state.locationQuery
              : bloc.activeLocationQuery,
        );
      },
      builder: (context, filters) {
        final activeCount = usersAppliedFilterCount(
          filter: filters.status,
          locationQuery: filters.location,
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  ),
                );
              },
            ),
          ],
        );

        if (inline) {
          final actionsWidth = (controlHeight * 2) + gap;
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
                actions,
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
                child: actions,
              ),
            ),
          ],
        );
      },
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
