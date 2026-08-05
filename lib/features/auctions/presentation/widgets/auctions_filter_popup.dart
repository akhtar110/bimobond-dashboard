import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../gifts/presentation/widgets/gifts_filter_footer.dart';
import '../../../posts/presentation/widgets/posts_filter_panel_ui.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../bloc/auctions_bloc.dart';
import 'auctions_sort_dropdown.dart';

/// Counts popup filters (excludes search, sort, date).
int auctionsAppliedFilterCount({
  String? statusFilter,
  AuctionTypeFilter typeFilter = AuctionTypeFilter.all,
  UserEntity? hostFilter,
  UserEntity? winnerFilter,
  String? postIdFilter,
  String? liveIdFilter,
  bool? hasWinnerFilter,
  bool? hasPostFilter,
  bool? hasLiveFilter,
}) {
  var count = 0;
  if (statusFilter != 'ACTIVE') count++;
  if (typeFilter != AuctionTypeFilter.all) count++;
  if (hostFilter != null) count++;
  if (winnerFilter != null) count++;
  if (hasWinnerFilter != null) count++;
  return count;
}

/// Opens the adaptive filter panel for auctions.
Future<void> showAuctionsFilterPopup({
  required BuildContext context,
  required String? statusFilter,
  required AuctionTypeFilter typeFilter,
  required Rect anchorRect,
}) {
  final auctionsBloc = context.read<AuctionsBloc>();
  final width = MediaQuery.sizeOf(context).width;

  Widget wrap(Widget child) => BlocProvider<AuctionsBloc>.value(
        value: auctionsBloc,
        child: child,
      );

  AuctionsFilterPopup popup({
    double? width,
    required double maxHeight,
    BorderRadius? borderRadius,
    bool showDragHandle = false,
  }) =>
      AuctionsFilterPopup(
        appliedStatus: statusFilter,
        appliedType: typeFilter,
        appliedSort: auctionsBloc.activeSortOption,
        appliedHost: auctionsBloc.activeHostFilter,
        appliedWinner: auctionsBloc.activeWinnerFilter,
        appliedHasWinner: auctionsBloc.activeHasWinnerFilter,
        width: width,
        maxHeight: maxHeight,
        borderRadius: borderRadius,
        showDragHandle: showDragHandle,
      );

  if (width < 600) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => wrap(
        popup(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          showDragHandle: true,
        ),
      ),
    );
  }

  if (width < 900) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Align(
          alignment: Alignment.center,
          child: wrap(
            popup(
              width: 420,
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
            ),
          ),
        ),
      ),
    );
  }

  const panelWidth = 400.0;
  final media = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  var left = isRtl ? anchorRect.right - panelWidth : anchorRect.left;
  left = left.clamp(12.0, media.width - panelWidth - 12);
  var top = anchorRect.bottom + 6;
  final maxPanelHeight = media.height * 0.72;
  if (top + 360 > media.height - padding.bottom) {
    top = (anchorRect.top - 6 - maxPanelHeight).clamp(
      padding.top + 12.0,
      media.height - 360.0,
    );
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.15),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.topCenter,
                child: wrap(
                  popup(
                    width: panelWidth,
                    maxHeight: maxPanelHeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Glass shell filter panel for auctions (matching posts design style).
class AuctionsFilterPopup extends StatefulWidget {
  const AuctionsFilterPopup({
    super.key,
    required this.appliedStatus,
    required this.appliedType,
    required this.appliedSort,
    this.appliedHost,
    this.appliedWinner,
    this.appliedHasWinner,
    this.width,
    this.maxHeight = 560,
    this.borderRadius,
    this.showDragHandle = false,
  });

  final String? appliedStatus;
  final AuctionTypeFilter appliedType;
  final AuctionSortOption appliedSort;
  final UserEntity? appliedHost;
  final UserEntity? appliedWinner;
  final bool? appliedHasWinner;
  final double? width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final bool showDragHandle;

  @override
  State<AuctionsFilterPopup> createState() => _AuctionsFilterPopupState();
}

class _AuctionsFilterPopupState extends State<AuctionsFilterPopup> {
  late String? _status;
  late AuctionTypeFilter _type;
  late AuctionSortOption _sort;
  UserEntity? _host;
  UserEntity? _winner;
  bool? _hasWinner;

  @override
  void initState() {
    super.initState();
    _status = widget.appliedStatus;
    _type = widget.appliedType;
    _sort = widget.appliedSort;
    _host = widget.appliedHost;
    _winner = widget.appliedWinner;
    _hasWinner = widget.appliedHasWinner;
  }

  void _close(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _updateFilter(VoidCallback update) {
    setState(update);
    _apply(context, close: false);
  }

  void _reset() {
    _updateFilter(() {
      _status = 'ACTIVE';
      _type = AuctionTypeFilter.all;
      _sort = AuctionsSortDropdown.defaultSort;
      _host = null;
      _winner = null;
      _hasWinner = null;
    });
  }

  bool _advancedFiltersChanged(AuctionsBloc bloc) {
    return bloc.activeHostFilter?.id != _host?.id ||
        bloc.activeWinnerFilter?.id != _winner?.id ||
        bloc.activeHasWinnerFilter != _hasWinner ||
        bloc.activePostIdFilter != null ||
        bloc.activeLiveIdFilter != null ||
        bloc.activeHasPostFilter != null ||
        bloc.activeHasLiveFilter != null;
  }

  void _apply(BuildContext context, {bool close = false}) {
    final bloc = context.read<AuctionsBloc>();
    if (bloc.activeStatusFilter != _status) {
      bloc.add(FilterAuctionsEvent(_status));
    }
    if (bloc.activeTypeFilter != _type) {
      bloc.add(UpdateAuctionTypeFilterEvent(_type));
    }
    if (bloc.activeSortOption != _sort) {
      bloc.add(UpdateAuctionSortEvent(_sort));
    }
    if (_advancedFiltersChanged(bloc)) {
      bloc.add(
        UpdateAuctionAdvancedFiltersEvent(
          host: _host,
          clearHost: _host == null,
          winner: _winner,
          clearWinner: _winner == null,
          hasWinner: _hasWinner,
          clearHasWinner: _hasWinner == null,
          clearPost: true,
          clearLive: true,
          clearHasPost: true,
          clearHasLive: true,
        ),
      );
    }
    if (close) {
      _close(context);
    }
  }

  String _boolFilterLabel(
    AppLocalizations l10n,
    String key,
    String fallback,
    bool value,
  ) {
    final base = l10n.tOr(key, fallback);
    final yn = value ? l10n.tOr('yes', 'Yes') : l10n.tOr('no', 'No');
    return '$base: $yn';
  }

  List<({String id, String label})> _activeTags(AppLocalizations l10n) {
    final tags = <({String id, String label})>[];
    if (_status != 'ACTIVE') {
      tags.add((
        id: 'status',
        label: _status == null
            ? l10n.t('all')
            : auctionStatusLabel(l10n, _status!),
      ));
    }
    if (_type != AuctionTypeFilter.all) {
      tags.add((id: 'type', label: auctionTypeLabel(l10n, _type)));
    }
    if (_sort != AuctionsSortDropdown.defaultSort) {
      tags.add((id: 'sort', label: auctionSortLabel(l10n, _sort)));
    }
    if (_host != null) {
      tags.add((id: 'host', label: '@${_host!.username}'));
    }
    if (_winner != null) {
      tags.add((id: 'winner', label: '@${_winner!.username}'));
    }
    if (_hasWinner != null) {
      tags.add((
        id: 'hasWinner',
        label: _boolFilterLabel(l10n, 'hasWinner', 'Has winner', _hasWinner!),
      ));
    }
    return tags;
  }

  void _removeTag(String id) {
    _updateFilter(() {
      switch (id) {
        case 'status':
          _status = 'ACTIVE';
        case 'type':
          _type = AuctionTypeFilter.all;
        case 'sort':
          _sort = AuctionsSortDropdown.defaultSort;
        case 'host':
          _host = null;
        case 'winner':
          _winner = null;
        case 'hasWinner':
          _hasWinner = null;
      }
    });
  }

  Widget _triStateChips({
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required AppLocalizations l10n,
  }) {
    return PostsFilterChipGrid(
      children: [
        PostsFilterChoiceChip(
          label: l10n.tOr('any', 'Any'),
          selected: value == null,
          onTap: () => onChanged(null),
        ),
        PostsFilterChoiceChip(
          label: l10n.tOr('yes', 'Yes'),
          selected: value == true,
          onTap: () => onChanged(true),
        ),
        PostsFilterChoiceChip(
          label: l10n.tOr('no', 'No'),
          selected: value == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    final statusOptions = <(String?, String)>[
      (null, l10n.t('all')),
      ('ACTIVE', l10n.t('active')),
      ('COMPLETED', l10n.t('completed')),
      ('SETTLED', l10n.tOr('settled', 'Settled')),
      ('DISPUTED', l10n.tOr('disputed', 'Disputed')),
      ('CANCELLED', l10n.t('cancelled')),
      ('BANNED', l10n.tOr('banned', 'Banned')),
    ];

    final sortOptions = <(AuctionSortOption, String)>[
      (AuctionSortOption.newestFirst, l10n.tOr('auctionSortNewest', 'Newest')),
      (
        AuctionSortOption.oldestFirst,
        l10n.tOr('auctionSortOldestShort', 'Oldest'),
      ),
      (
        AuctionSortOption.highestBid,
        l10n.tOr('auctionSortHighestTotal', 'Highest Total'),
      ),
      (
        AuctionSortOption.lowestBid,
        l10n.tOr('auctionSortLowestTotal', 'Lowest Total'),
      ),
      (
        AuctionSortOption.targetPrice,
        l10n.tOr('auctionSortHighestTarget', 'Highest Target'),
      ),
      (
        AuctionSortOption.endingSoon,
        l10n.tOr('auctionSortRecentlyEnded', 'Recently Ended'),
      ),
    ];

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: radius,
      child: PostsFilterGlassShell(
        borderRadius: radius,
        child: SizedBox(
          width: widget.width ?? 400,
          height: widget.maxHeight,
          child: Column(
            children: [
              if (widget.showDragHandle) const _AuctionsFilterDragHandle(),
              PostsFilterPanelHeader(onClose: () => _close(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                    bottom: PostsFilterPanelTokens.spacing,
                  ),
                  children: [
                    PostsFilterActiveTags(
                      labels: _activeTags(l10n),
                      onRemove: _removeTag,
                    ),
                    PostsFilterSection(
                      title: l10n.t('status'),
                      icon: Icons.shield_outlined,
                      showDivider: false,
                      child: PostsFilterChipGrid(
                        children: [
                          for (final (status, label) in statusOptions)
                            PostsFilterChoiceChip(
                              label: label,
                              selected: _status == status,
                              onTap: () =>
                                  _updateFilter(() => _status = status),
                            ),
                        ],
                      ),
                    ),
                    PostsFilterSection(
                      title: l10n.tOr('auctionType', 'Auction type'),
                      icon: Icons.category_outlined,
                      child: PostsFilterChipGrid(
                        children: [
                          PostsFilterChoiceChip(
                            label: l10n.t('all'),
                            selected: _type == AuctionTypeFilter.all,
                            onTap: () => _updateFilter(
                              () => _type = AuctionTypeFilter.all,
                            ),
                          ),
                          PostsFilterChoiceChip(
                            label: l10n.tOr('auctionTypeFixed', 'Fixed price'),
                            selected: _type == AuctionTypeFilter.fixed,
                            onTap: () => _updateFilter(
                              () => _type = AuctionTypeFilter.fixed,
                            ),
                          ),
                          PostsFilterChoiceChip(
                            label: l10n.tOr('auctionTypeTimed', 'Timed'),
                            selected: _type == AuctionTypeFilter.timed,
                            onTap: () => _updateFilter(
                              () => _type = AuctionTypeFilter.timed,
                            ),
                          ),
                          PostsFilterChoiceChip(
                            label: l10n.t('live'),
                            selected: _type == AuctionTypeFilter.live,
                            onTap: () => _updateFilter(
                              () => _type = AuctionTypeFilter.live,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PostsFilterSection(
                      title: l10n.tOr('sortBy', 'Sort'),
                      icon: Icons.sort_rounded,
                      child: PostsFilterChipGrid(
                        children: [
                          for (final (sort, label) in sortOptions)
                            PostsFilterChoiceChip(
                              label: label,
                              selected: _sort == sort,
                              onTap: () => _updateFilter(() => _sort = sort),
                            ),
                        ],
                      ),
                    ),
                    PostsFilterSection(
                      title: l10n.tOr('host', 'Host'),
                      icon: Icons.person_outline_rounded,
                      child: AdminUserSearchField(
                        key: ValueKey(
                          'auction-filter-host-${_host?.id ?? 'none'}',
                        ),
                        compact: true,
                        selectedUser: _host,
                        hintText: l10n.tOr('searchHost', 'Search host'),
                        onUserSelected: (user) =>
                            _updateFilter(() => _host = user),
                      ),
                    ),
                    PostsFilterSection(
                      title: l10n.tOr('winner', 'Winner'),
                      icon: Icons.emoji_events_outlined,
                      child: AdminUserSearchField(
                        key: ValueKey(
                          'auction-filter-winner-${_winner?.id ?? 'none'}',
                        ),
                        compact: true,
                        selectedUser: _winner,
                        hintText: l10n.tOr('searchWinner', 'Search winner'),
                        onUserSelected: (user) =>
                            _updateFilter(() => _winner = user),
                      ),
                    ),
                    PostsFilterSection(
                      title: l10n.tOr('hasWinner', 'Has winner'),
                      icon: Icons.check_circle_outline_rounded,
                      child: _triStateChips(
                        value: _hasWinner,
                        onChanged: (v) => _updateFilter(() => _hasWinner = v),
                        l10n: l10n,
                      ),
                    ),
                  ],
                ),
              ),
              GiftsFilterFooter(
                onReset: _reset,
                onCancel: () => _close(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuctionsFilterDragHandle extends StatelessWidget {
  const _AuctionsFilterDragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Center(
        child: Container(
          width: 32,
          height: 3,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

String auctionStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'ACTIVE' => l10n.t('active'),
    'COMPLETED' => l10n.t('completed'),
    'SETTLED' => l10n.tOr('settled', 'Settled'),
    'DISPUTED' => l10n.tOr('disputed', 'Disputed'),
    'CANCELLED' => l10n.t('cancelled'),
    'BANNED' => l10n.tOr('banned', 'Banned'),
    _ => status,
  };
}

String auctionTypeLabel(AppLocalizations l10n, AuctionTypeFilter type) {
  return switch (type) {
    AuctionTypeFilter.all => l10n.t('all'),
    AuctionTypeFilter.fixed => l10n.tOr('auctionTypeFixed', 'Fixed price'),
    AuctionTypeFilter.timed => l10n.tOr('auctionTypeTimed', 'Timed'),
    AuctionTypeFilter.live => l10n.t('live'),
  };
}
