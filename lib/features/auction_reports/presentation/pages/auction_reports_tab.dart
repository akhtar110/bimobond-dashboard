import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../analytics/presentation/utils/analytics_format.dart';
import '../../domain/entities/auction_report_entities.dart';
import '../../../reports/presentation/utils/reports_responsive.dart';
import '../../../reports/presentation/widgets/reports_pagination_bar.dart';
import '../bloc/auction_reports_bloc.dart';

class AuctionReportsTab extends StatefulWidget {
  const AuctionReportsTab({
    super.key,
    this.denseLayout = false,
    required this.onRowTap,
  });

  final bool denseLayout;
  final ValueChanged<AuctionReportListItem> onRowTap;

  @override
  State<AuctionReportsTab> createState() => _AuctionReportsTabState();
}

enum _AuctionStatusFilter { all, active, completed, cancelled }

_AuctionStatusFilter _statusFilterFromQuery(String? status) {
  return switch (status?.toUpperCase()) {
    'ACTIVE' => _AuctionStatusFilter.active,
    'COMPLETED' => _AuctionStatusFilter.completed,
    'CANCELLED' => _AuctionStatusFilter.cancelled,
    _ => _AuctionStatusFilter.all,
  };
}

String? _statusApiValue(_AuctionStatusFilter filter) {
  return switch (filter) {
    _AuctionStatusFilter.all => null,
    _AuctionStatusFilter.active => 'ACTIVE',
    _AuctionStatusFilter.completed => 'COMPLETED',
    _AuctionStatusFilter.cancelled => 'CANCELLED',
  };
}

class _AuctionReportsTabState extends State<AuctionReportsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    if (!reportsUseInfiniteScroll(MediaQuery.sizeOf(context).width)) return;
    if (!reportsShouldLoadMore(_scrollController)) return;
    context.read<AuctionReportsBloc>().add(LoadMoreAuctionReportsEvent());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<AuctionReportsBloc, AuctionReportsState>(
      builder: (context, state) {
        if (state is AuctionReportsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AuctionReportsError) {
          return _ErrorBody(
            message: state.message,
            onRetry: () => context
                .read<AuctionReportsBloc>()
                .add(LoadAuctionReportsEvent(refresh: true)),
          );
        }
        if (state is! AuctionReportsLoaded) {
          return const SizedBox.shrink();
        }

        final selectedStatus = _statusFilterFromQuery(state.query.status);

        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.denseLayout ? 0 : 12,
            widget.denseLayout ? 0 : 8,
            widget.denseLayout ? 0 : 12,
            widget.denseLayout ? 0 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FiltersBar(
                dense: widget.denseLayout,
                loaded: state,
                selectedStatus: selectedStatus,
                hideSearchBar: widget.denseLayout,
                searchController: _searchController,
                onSearchChanged: (q) => context
                    .read<AuctionReportsBloc>()
                    .add(UpdateAuctionReportsSearchEvent(q)),
                onStatusSelected: (filter) => context
                    .read<AuctionReportsBloc>()
                    .add(
                      UpdateAuctionReportsFiltersEvent(
                        state.query.copyWith(
                          status: _statusApiValue(filter),
                          clearStatus: filter == _AuctionStatusFilter.all,
                          clearHasWinner: true,
                        ),
                      ),
                    ),
              ),
              if (state.isFetching)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: state.auctions.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.t('no_results'),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : _AuctionsTable(
                        auctions: state.auctions,
                        scrollController: _scrollController,
                        isLoadingMore: state.isLoadingMore,
                        onRowTap: widget.onRowTap,
                      ),
              ),
              if (reportsUseDesktopPagination(MediaQuery.sizeOf(context).width))
                ReportsPaginationBar(
                  page: state.currentPage,
                  totalPages: state.lastPage,
                  total: state.total,
                  pageSize: 20,
                  itemCount: state.auctions.length,
                  itemLabel: 'auctions',
                  onPage: (page) => context
                      .read<AuctionReportsBloc>()
                      .add(GoToAuctionReportsPageEvent(page)),
                )
              else if (state.hasReachedMax && state.auctions.isNotEmpty)
                ReportsLoadMoreFooter(
                  hasReachedMax: true,
                  total: state.total,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.dense,
    required this.loaded,
    required this.selectedStatus,
    required this.hideSearchBar,
    required this.searchController,
    required this.onSearchChanged,
    required this.onStatusSelected,
  });

  final bool dense;
  final AuctionReportsLoaded loaded;
  final _AuctionStatusFilter selectedStatus;
  final bool hideSearchBar;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_AuctionStatusFilter> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pad = dense ? 0.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;

        return Padding(
          padding: EdgeInsets.fromLTRB(pad, dense ? 0 : 12, pad, dense ? 6 : 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!hideSearchBar)
                SizedBox(
                  width: narrow ? constraints.maxWidth : 260,
                  height: 34,
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.t('searchAuctions'),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              for (final filter in _AuctionStatusFilter.values)
                _StatusChip(
                  label: switch (filter) {
                    _AuctionStatusFilter.all => l10n.t('filterAll'),
                    _AuctionStatusFilter.active => l10n.t('active'),
                    _AuctionStatusFilter.completed => l10n.t('completed'),
                    _AuctionStatusFilter.cancelled => l10n.t('cancelled'),
                  },
                  selected: selectedStatus == filter,
                  onTap: () => onStatusSelected(filter),
                ),
              if (loaded.isFetching)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      ),
      selectedColor: scheme.primaryContainer,
      backgroundColor: scheme.surfaceContainerLow,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _AuctionsTable extends StatelessWidget {
  const _AuctionsTable({
    required this.auctions,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onRowTap,
  });

  final List<AuctionReportListItem> auctions;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final ValueChanged<AuctionReportListItem> onRowTap;

  static final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = reportsMetricsOf(context);
    final useInfinite = metrics.useInfiniteScroll;

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        metrics.pageHorizontalPadding,
        0,
        metrics.pageHorizontalPadding,
        8,
      ),
      itemCount: auctions.length + (useInfinite && isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) =>
          Divider(color: scheme.outlineVariant, height: 1),
      itemBuilder: (context, index) {
        if (index >= auctions.length) {
          return const ReportsLoadMoreFooter(isLoading: true);
        }
        final auction = auctions[index];
        final image = resolveMediaUrl(auction.itemImageUrl);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRowTap(auction),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: image != null
                          ? CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _imageFallback(scheme),
                            )
                          : _imageFallback(scheme),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${auction.host?.username ?? auction.hostId} · '
                          '${auction.status} · ${auction.progressPercent}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MetricChip(
                    icon: Icons.payments_outlined,
                    value: CoinFormat.coinsAmount(auction.currentTotalCoins),
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    icon: Icons.gavel_rounded,
                    value: '${auction.counts.bids}',
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    icon: Icons.card_giftcard_outlined,
                    value: '${auction.counts.giftTransactions}',
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: Text(
                      _dateFormat.format(auction.startedAt),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imageFallback(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.gavel_rounded, color: scheme.onSurfaceVariant),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.t('retry')),
          ),
        ],
      ),
    );
  }
}
