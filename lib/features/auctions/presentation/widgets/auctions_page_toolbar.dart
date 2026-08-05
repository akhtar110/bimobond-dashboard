import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_button.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../bloc/auctions_bloc.dart';
import '../utils/auctions_responsive.dart';
import 'auctions_date_filter_button.dart';
import 'auctions_filter_bar.dart';
import 'auctions_filter_popup.dart';
import 'auctions_sort_dropdown.dart';

/// Responsive auctions toolbar — adapts search and actions by available width.
class AuctionsPageToolbar extends StatelessWidget {
  const AuctionsPageToolbar({super.key, required this.metrics});

  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final controlHeight = metrics.filterControlHeight;
    final gap = metrics.filterGap + 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final inline = metrics.toolbarInlineAt(width);

        return _AuctionsToolbarRow(
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

class _AuctionsToolbarRow extends StatelessWidget {
  const _AuctionsToolbarRow({
    required this.metrics,
    required this.controlHeight,
    required this.gap,
    required this.availableWidth,
    required this.inline,
  });

  final AuctionsLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final double availableWidth;
  final bool inline;

  void _openFilters(
    BuildContext context, {
    required String? statusFilter,
    required AuctionTypeFilter typeFilter,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    showAuctionsFilterPopup(
      context: context,
      statusFilter: statusFilter,
      typeFilter: typeFilter,
      anchorRect: Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height),
    );
  }

  Widget _searchField() {
    return AuctionsFilterBar(
      compact: true,
      metrics: metrics,
      height: controlHeight,
    );
  }

  Widget _actionButtons(
    BuildContext context, {
    required String? statusFilter,
    required AuctionTypeFilter typeFilter,
    required int activeCount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuctionsDateFilterButton(height: controlHeight),
        SizedBox(width: gap),
        AuctionsSortDropdown(height: controlHeight),
        SizedBox(width: gap),
        Builder(
          builder: (buttonContext) {
            return PostsFilterButton(
              activeCount: activeCount,
              height: controlHeight,
              iconOnly: true,
              onPressed: () => _openFilters(
                buttonContext,
                statusFilter: statusFilter,
                typeFilter: typeFilter,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _actionWrap(
    BuildContext context, {
    required String? statusFilter,
    required AuctionTypeFilter typeFilter,
    required int activeCount,
  }) {
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AuctionsDateFilterButton(height: controlHeight),
        AuctionsSortDropdown(height: controlHeight),
        Builder(
          builder: (buttonContext) {
            return PostsFilterButton(
              activeCount: activeCount,
              height: controlHeight,
              iconOnly: true,
              onPressed: () => _openFilters(
                buttonContext,
                statusFilter: statusFilter,
                typeFilter: typeFilter,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        AuctionsBloc,
        AuctionsState,
        ({
          String? status,
          AuctionTypeFilter type,
          UserEntity? host,
          UserEntity? winner,
          String? postId,
          String? liveId,
          bool? hasWinner,
          bool? hasPost,
          bool? hasLive,
        })>(
      selector: (state) {
        final bloc = context.read<AuctionsBloc>();
        if (state is AuctionsLoaded) {
          return (
            status: state.statusFilter,
            type: state.typeFilter,
            host: state.hostFilter,
            winner: state.winnerFilter,
            postId: state.postIdFilter,
            liveId: state.liveIdFilter,
            hasWinner: state.hasWinnerFilter,
            hasPost: state.hasPostFilter,
            hasLive: state.hasLiveFilter,
          );
        }
        return (
          status: bloc.activeStatusFilter,
          type: bloc.activeTypeFilter,
          host: bloc.activeHostFilter,
          winner: bloc.activeWinnerFilter,
          postId: bloc.activePostIdFilter,
          liveId: bloc.activeLiveIdFilter,
          hasWinner: bloc.activeHasWinnerFilter,
          hasPost: bloc.activeHasPostFilter,
          hasLive: bloc.activeHasLiveFilter,
        );
      },
      builder: (context, filters) {
        final activeCount = auctionsAppliedFilterCount(
          statusFilter: filters.status,
          typeFilter: filters.type,
          hostFilter: filters.host,
          winnerFilter: filters.winner,
          postIdFilter: filters.postId,
          liveIdFilter: filters.liveId,
          hasWinnerFilter: filters.hasWinner,
          hasPostFilter: filters.hasPost,
          hasLiveFilter: filters.hasLive,
        );
        final useWrap = availableWidth < 360;
        final actions = useWrap
            ? _actionWrap(
                context,
                statusFilter: filters.status,
                typeFilter: filters.type,
                activeCount: activeCount,
              )
            : _actionButtons(
                context,
                statusFilter: filters.status,
                typeFilter: filters.type,
                activeCount: activeCount,
              );

        if (inline) {
          final searchWidth = metrics.inlineSearchWidthFor(availableWidth);
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

/// Dismissible chips for active auction filters (not search).
class AuctionsActiveFilterChips extends StatelessWidget {
  const AuctionsActiveFilterChips({super.key});

  void _clearAll(BuildContext context) {
    final bloc = context.read<AuctionsBloc>();
    bloc.add(FilterAuctionsEvent('ACTIVE'));
    bloc.add(UpdateAuctionTypeFilterEvent(AuctionTypeFilter.all));
    bloc.add(UpdateAuctionSortEvent(AuctionsSortDropdown.defaultSort));
    bloc.add(UpdateAuctionDateRangeEvent(null));
    bloc.add(UpdateAuctionSearchEvent(''));
    bloc.add(ClearAuctionAdvancedFiltersEvent());
  }

  String _boolChipLabel(
    AppLocalizations l10n,
    String key,
    String fallback,
    bool value,
  ) {
    final base = l10n.tOr(key, fallback);
    final yn = value ? l10n.tOr('yes', 'Yes') : l10n.tOr('no', 'No');
    return '$base: $yn';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuctionsBloc, AuctionsState>(
      buildWhen: (prev, next) {
        if (prev is AuctionsLoaded && next is AuctionsLoaded) {
          return prev.statusFilter != next.statusFilter ||
              prev.typeFilter != next.typeFilter ||
              prev.sortOption != next.sortOption ||
              prev.dateRange != next.dateRange ||
              prev.hostFilter?.id != next.hostFilter?.id ||
              prev.winnerFilter?.id != next.winnerFilter?.id ||
              prev.postIdFilter != next.postIdFilter ||
              prev.liveIdFilter != next.liveIdFilter ||
              prev.hasWinnerFilter != next.hasWinnerFilter ||
              prev.hasPostFilter != next.hasPostFilter ||
              prev.hasLiveFilter != next.hasLiveFilter;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! AuctionsLoaded) return const SizedBox.shrink();

        final chips = <Widget>[];

        if (state.statusFilter != 'ACTIVE') {
          chips.add(
            _ActiveFilterChip(
              label: state.statusFilter == null
                  ? l10n.t('all')
                  : auctionStatusLabel(l10n, state.statusFilter!),
              onRemove: () => context
                  .read<AuctionsBloc>()
                  .add(FilterAuctionsEvent('ACTIVE')),
            ),
          );
        }

        if (state.typeFilter != AuctionTypeFilter.all) {
          chips.add(
            _ActiveFilterChip(
              label: auctionTypeLabel(l10n, state.typeFilter),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionTypeFilterEvent(AuctionTypeFilter.all),
                  ),
            ),
          );
        }

        if (state.dateRange != null) {
          chips.add(
            _ActiveFilterChip(
              label: l10n.t('customRange'),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionDateRangeEvent(null),
                  ),
            ),
          );
        }

        if (state.sortOption != AuctionsSortDropdown.defaultSort) {
          chips.add(
            _ActiveFilterChip(
              label: auctionSortLabel(l10n, state.sortOption),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionSortEvent(AuctionsSortDropdown.defaultSort),
                  ),
            ),
          );
        }

        if (state.hostFilter != null) {
          chips.add(
            _ActiveFilterChip(
              label: '@${state.hostFilter!.username}',
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearHost: true),
                  ),
            ),
          );
        }

        if (state.winnerFilter != null) {
          chips.add(
            _ActiveFilterChip(
              label: '@${state.winnerFilter!.username}',
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearWinner: true),
                  ),
            ),
          );
        }

        if (state.postIdFilter != null && state.postIdFilter!.isNotEmpty) {
          chips.add(
            _ActiveFilterChip(
              label: state.postLabelFilter?.trim().isNotEmpty == true
                  ? state.postLabelFilter!
                  : l10n.tOr('linkedPost', 'Linked post'),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearPost: true),
                  ),
            ),
          );
        }

        if (state.liveIdFilter != null && state.liveIdFilter!.isNotEmpty) {
          chips.add(
            _ActiveFilterChip(
              label: state.liveLabelFilter?.trim().isNotEmpty == true
                  ? state.liveLabelFilter!
                  : l10n.tOr('linkedLiveSession', 'Linked live session'),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearLive: true),
                  ),
            ),
          );
        }

        if (state.hasWinnerFilter != null) {
          chips.add(
            _ActiveFilterChip(
              label: _boolChipLabel(
                l10n,
                'hasWinner',
                'Has winner',
                state.hasWinnerFilter!,
              ),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearHasWinner: true),
                  ),
            ),
          );
        }

        if (state.hasPostFilter != null) {
          chips.add(
            _ActiveFilterChip(
              label: _boolChipLabel(
                l10n,
                'hasPost',
                'Has post',
                state.hasPostFilter!,
              ),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearHasPost: true),
                  ),
            ),
          );
        }

        if (state.hasLiveFilter != null) {
          chips.add(
            _ActiveFilterChip(
              label: _boolChipLabel(
                l10n,
                'hasLive',
                'Has live',
                state.hasLiveFilter!,
              ),
              onRemove: () => context.read<AuctionsBloc>().add(
                    UpdateAuctionAdvancedFiltersEvent(clearHasLive: true),
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
                onPressed: () => _clearAll(context),
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
