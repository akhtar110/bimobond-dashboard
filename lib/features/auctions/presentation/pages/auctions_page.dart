import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/auction_entity.dart';
import '../bloc/auctions_bloc.dart';
import '../services/auction_image_lookup.dart';
import '../utils/auctions_responsive.dart';
import '../widgets/auction_card.dart';

/// Responsive column count for admin catalog grids.
/// Matches [giftsGridColumnCount] so auction cards share the same card width.
int adminGridColumnCount(double width) {
  if (width > 1500) return 7;
  if (width > 1200) return 6;
  if (width > 980) return 5;
  if (width > 760) return 4;
  if (width > 520) return 3;
  if (width > 360) return 2;
  return 1;
}

class AuctionsPage extends StatelessWidget {
  const AuctionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('AuctionsPage rebuilt');
    return PersistentBlocProvider<AuctionsBloc>(
      debugLabel: 'AuctionsPage',
      create: () =>
          sl<AuctionsBloc>()..add(LoadAllAuctionsEvent(refresh: true)),
      child: const _AuctionsPageView(),
    );
  }
}

class _AuctionsPageView extends StatefulWidget {
  const _AuctionsPageView();

  @override
  State<_AuctionsPageView> createState() => _AuctionsPageViewState();
}

class _AuctionsPageViewState extends State<_AuctionsPageView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final width = MediaQuery.sizeOf(context).width;
    final metrics = AuctionsLayoutMetrics(getAuctionsDeviceType(width));
    if (!metrics.useInfiniteScroll) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<AuctionsBloc>().add(LoadMoreAuctionsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final windowWidth = MediaQuery.sizeOf(context).width;
        final metrics = AuctionsLayoutMetrics(
          getAuctionsDeviceType(windowWidth),
        );

        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          body: BlocConsumer<AuctionsBloc, AuctionsState>(
            listener: (context, state) {},
            builder: (context, state) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _SliverHeader(
                    theme: theme,
                    state: state,
                    metrics: metrics,
                  ),
                  if (state is AuctionsLoaded) ...[
                    _SliverFilters(
                      key: const ValueKey('auctions_filter_bar'),
                      loaded: state,
                      theme: theme,
                      metrics: metrics,
                    ),
                    _SliverGrid(loaded: state, metrics: metrics),
                    if (metrics.useDesktopPagination && state.total > 0)
                      _SliverPagination(loaded: state, metrics: metrics),
                    if (metrics.useInfiniteScroll && state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ] else if (state is AuctionsLoading) ...[
                    _SliverSkeletons(metrics: metrics),
                  ] else if (state is AuctionsError) ...[
                    _SliverError(message: state.message),
                  ],
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: metrics.isMobile ? 16 : 24,
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
}

// ─── Sliver Header ────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({
    required this.theme,
    required this.state,
    required this.metrics,
  });

  final ThemeData theme;
  final AuctionsState state;
  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final isLoading = state is AuctionsLoading;
    final AuctionsLoaded? loaded =
        state is AuctionsLoaded ? state as AuctionsLoaded : null;

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.pageHorizontalPadding,
              metrics.pageTopPadding,
              metrics.pageHorizontalPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('auctions'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: scheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor and manage all auction activities',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          if (loaded != null) ...[
                            SizedBox(height: metrics.isMobile ? 8 : 12),
                            Wrap(
                              spacing: metrics.isMobile ? 6 : 8,
                              runSpacing: metrics.isMobile ? 6 : 8,
                              alignment: WrapAlignment.start,
                              children: [
                                _StatChip(
                                  label: l10n.t('total'),
                                  value: loaded.total.toString(),
                                  icon: Icons.gavel_rounded,
                                  color: scheme.primary,
                                  compact: metrics.isMobile,
                                ),
                                _StatChip(
                                  label: l10n.t('active'),
                                  value: loaded.activeCount.toString(),
                                  icon: Icons.play_circle_rounded,
                                  color: scheme.primary,
                                  compact: metrics.isMobile,
                                ),
                                _StatChip(
                                  label: l10n.t('completed'),
                                  value: loaded.completedCount.toString(),
                                  icon: Icons.check_circle_rounded,
                                  color: scheme.secondary,
                                  compact: metrics.isMobile,
                                ),
                                _StatChip(
                                  label: l10n.t('cancelled'),
                                  value: loaded.cancelledCount.toString(),
                                  icon: Icons.cancel_rounded,
                                  color: scheme.error,
                                  compact: metrics.isMobile,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Material(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () => context
                                .read<AuctionsBloc>()
                                .add(LoadAllAuctionsEvent(refresh: true)),
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: scheme.onSurfaceVariant,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: metrics.sectionGap),
                Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
              color: color,
            ),
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter section ───────────────────────────────────────────────────────────

class _SliverFilters extends StatefulWidget {
  const _SliverFilters({
    super.key,
    required this.loaded,
    required this.theme,
    required this.metrics,
  });

  final AuctionsLoaded loaded;
  final ThemeData theme;
  final AuctionsLayoutMetrics metrics;

  @override
  State<_SliverFilters> createState() => _SliverFiltersState();
}

class _SliverFiltersState extends State<_SliverFilters> {
  late final TextEditingController _searchCtrl;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController(text: widget.loaded.searchQuery);
  }

  @override
  void didUpdateWidget(_SliverFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loaded.searchQuery.isEmpty &&
        oldWidget.loaded.searchQuery.isNotEmpty &&
        _searchCtrl.text.isNotEmpty &&
        !_searchFocus.hasFocus) {
      _searchCtrl.clear();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    context.read<AuctionsBloc>().add(UpdateAuctionSearchEvent(value));
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {});
    context.read<AuctionsBloc>().add(UpdateAuctionSearchEvent(''));
  }

  String _resultsCountLabel(AppLocalizations l10n, int shown, int total) {
    final template =
        l10n.tOr('showingResultsCount', 'Showing {shown} of {total}');
    return template
        .replaceAll('{shown}', '$shown')
        .replaceAll('{total}', '$total');
  }

  @override
  Widget build(BuildContext context) {
    final loaded = widget.loaded;
    final theme = widget.theme;
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final bloc = context.read<AuctionsBloc>();
    final filters = [
      (null, l10n.t('all')),
      ('ACTIVE', l10n.t('active')),
      ('COMPLETED', l10n.t('completed')),
      ('CANCELLED', l10n.t('cancelled')),
    ];

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = widget.metrics;
              final gap = metrics.toolbarFilterGap;
              final controlHeight = metrics.filterControlHeight;
              final veryNarrow = constraints.maxWidth < 520;
              final useStackedFilters = metrics.isMobile || veryNarrow;

              Widget statusChips() {
                return SizedBox(
                  height: controlHeight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        Builder(builder: (context) {
                          final (status, label) = filters[i];
                          final selected = loaded.statusFilter == status;
                          return FilterChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                fontSize: metrics.isMobile ? 11 : 12,
                              ),
                            ),
                            selected: selected,
                            showCheckmark: false,
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.isMobile ? 2 : 4,
                            ),
                            visualDensity: VisualDensity.compact,
                            onSelected: (v) => bloc.add(
                              FilterAuctionsEvent(v ? status : null),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                metrics.isMobile ? 10 : 12,
                              ),
                            ),
                            backgroundColor: scheme.surface,
                            side: BorderSide(
                              color: selected
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              }

              final sortMenu = _AuctionFilterMenu<AuctionSortOption>(
                label: l10n.t('sortBy'),
                value: loaded.sortOption,
                height: controlHeight,
                items: AuctionSortOption.values,
                itemLabel: (option) => switch (option) {
                  AuctionSortOption.newestFirst =>
                    l10n.tOr('auctionSortMostRecent', 'Most recent'),
                  AuctionSortOption.oldestFirst =>
                    l10n.tOr('auctionSortOldest', 'Oldest auctions'),
                  AuctionSortOption.highestBid => l10n.t('sortHighestBid'),
                  AuctionSortOption.lowestBid => l10n.t('sortLowestBid'),
                  AuctionSortOption.mostViewed => l10n.t('sortMostViewed'),
                  AuctionSortOption.endingSoon => l10n.t('sortEndingSoon'),
                },
                onSelected: (value) =>
                    bloc.add(UpdateAuctionSortEvent(value)),
              );

              final dateMenu = _AuctionDateFilterMenu(
                dateRange: loaded.dateRange,
                height: controlHeight,
                onSelected: (range) => bloc.add(
                  UpdateAuctionDateRangeEvent(range),
                ),
              );

              Widget filterToolbar() {
                if (useStackedFilters) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      statusChips(),
                      SizedBox(height: gap),
                      Row(
                        children: [
                          Expanded(child: sortMenu),
                          SizedBox(width: gap),
                          Expanded(child: dateMenu),
                        ],
                      ),
                    ],
                  );
                }

                return SizedBox(
                  height: controlHeight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        Builder(builder: (context) {
                          final (status, label) = filters[i];
                          final selected = loaded.statusFilter == status;
                          return FilterChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 12)),
                            selected: selected,
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            onSelected: (v) => bloc.add(
                              FilterAuctionsEvent(v ? status : null),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: scheme.surface,
                            side: BorderSide(
                              color: selected
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          );
                        }),
                      ],
                      SizedBox(width: gap),
                      sortMenu,
                      SizedBox(width: gap),
                      dateMenu,
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.pageHorizontalPadding,
                  metrics.isMobile ? 4 : 8,
                  metrics.pageHorizontalPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        fontSize: metrics.isMobile ? 13 : 14,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            l10n.tOr('searchAuctions', 'Search auctions…'),
                        hintStyle: TextStyle(
                          fontSize: metrics.isMobile ? 13 : 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: metrics.isMobile ? 16 : 18,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: metrics.isMobile ? 14 : 16,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: metrics.isMobile ? 10 : 12,
                          vertical: metrics.isMobile ? 8 : 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            metrics.isMobile ? 8 : 10,
                          ),
                          borderSide:
                              BorderSide(color: scheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            metrics.isMobile ? 8 : 10,
                          ),
                          borderSide:
                              BorderSide(color: scheme.outlineVariant),
                        ),
                        filled: true,
                        fillColor: scheme.surface,
                      ),
                    ),
                    SizedBox(height: metrics.filterGap),
                    filterToolbar(),
                    SizedBox(height: metrics.toolbarFilterGap),
                    if (loaded.isFetching)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: metrics.toolbarFilterGap,
                        ),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: scheme.primary,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    Text(
                      _resultsCountLabel(
                        l10n,
                        loaded.displayedCount,
                        loaded.totalCount,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: metrics.isMobile ? 11 : 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuctionFilterMenu<T> extends StatelessWidget {
  const _AuctionFilterMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.height = 32,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<T>(
              value: item,
              child: Text(itemLabel(item),
                  style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: height <= 28 ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              itemLabel(value),
              style: TextStyle(fontSize: height <= 28 ? 11 : 12),
              overflow: TextOverflow.ellipsis,
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: height <= 28 ? 16 : 18,
                color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _AuctionDateFilterMenu extends StatelessWidget {
  const _AuctionDateFilterMenu({
    required this.dateRange,
    required this.onSelected,
    this.height = 32,
  });

  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final label = dateRange == null
        ? l10n.t('dateRange')
        : l10n.t('customRange');

    return PopupMenuButton<String>(
      onSelected: (value) async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        switch (value) {
          case 'all':
            onSelected(null);
          case 'today':
            onSelected(DateTimeRange(
              start: today,
              end: today.add(const Duration(days: 1)),
            ));
          case '7d':
            onSelected(DateTimeRange(
              start: today.subtract(const Duration(days: 6)),
              end: today.add(const Duration(days: 1)),
            ));
          case '30d':
            onSelected(DateTimeRange(
              start: today.subtract(const Duration(days: 29)),
              end: today.add(const Duration(days: 1)),
            ));
          case 'custom':
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDateRange: dateRange,
            );
            if (picked != null) onSelected(picked);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'all', child: Text(l10n.t('filterAll'))),
        PopupMenuItem(value: 'today', child: Text(l10n.t('dateToday'))),
        PopupMenuItem(value: '7d', child: Text(l10n.t('last7Days'))),
        PopupMenuItem(value: '30d', child: Text(l10n.t('last30Days'))),
        PopupMenuItem(value: 'custom', child: Text(l10n.t('customRange'))),
      ],
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(
          horizontal: height <= 28 ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: height <= 28 ? 11 : 12),
              overflow: TextOverflow.ellipsis,
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: height <= 28 ? 16 : 18,
                color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────

class _SliverPagination extends StatelessWidget {
  const _SliverPagination({
    required this.loaded,
    required this.metrics,
  });

  final AuctionsLoaded loaded;
  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.pageHorizontalPadding,
              metrics.sectionGap,
              metrics.pageHorizontalPadding,
              0,
            ),
            child: AppPaginationBar(
              currentPage: loaded.currentPage,
              lastPage: loaded.lastPage,
              total: loaded.total,
              pageSize: AuctionsBloc.pageLimit,
              itemCount: loaded.auctions.length,
              hideWhenSinglePage: false,
              borderRadius: BorderRadius.circular(12),
              onPageChanged: (page) =>
                  context.read<AuctionsBloc>().add(GoToAuctionsPageEvent(page)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid card with linked-post image fallback ────────────────────────────────

class _AuctionCardWithImage extends StatefulWidget {
  const _AuctionCardWithImage({
    required this.auction,
    this.onViewDetails,
    this.onCancel,
  });

  final AuctionEntity auction;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;

  @override
  State<_AuctionCardWithImage> createState() => _AuctionCardWithImageState();
}

class _AuctionCardWithImageState extends State<_AuctionCardWithImage> {
  String? _previewImageUrl;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _AuctionCardWithImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.auction.id != widget.auction.id ||
        oldWidget.auction.postId != widget.auction.postId) {
      _previewImageUrl = null;
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    final url = await sl<AuctionImageLookup>().previewUrlFor(widget.auction);
    if (!mounted) return;
    if (_previewImageUrl != url) {
      setState(() => _previewImageUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuctionCard(
      auction: widget.auction,
      previewImageUrl: _previewImageUrl,
      onViewDetails: widget.onViewDetails,
      onCancel: widget.onCancel,
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _SliverGrid extends StatelessWidget {
  const _SliverGrid({
    required this.loaded,
    required this.metrics,
  });
  final AuctionsLoaded loaded;
  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final auctions = loaded.displayed;

    if (auctions.isEmpty) {
      return const _SliverEmptyState(
        icon: Icons.gavel_rounded,
        titleKey: 'noAuctionsFound',
        subtitleKey: 'tryDifferentFilter',
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        final rowCount = (auctions.length / columns).ceil();
        final gap = metrics.gridGap;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.pageHorizontalPadding,
            metrics.gridTopPadding,
            metrics.pageHorizontalPadding,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                final start = rowIndex * columns;
                final end = (start + columns).clamp(0, auctions.length);
                final rowAuctions = auctions.sublist(start, end);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: rowIndex < rowCount - 1 ? gap : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < columns; i++) ...[
                        if (i > 0) SizedBox(width: gap),
                        Expanded(
                          child: i < rowAuctions.length
                              ? _AuctionCardWithImage(
                                    auction: rowAuctions[i],
                                    onViewDetails: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.auctionDetail,
                                        arguments: rowAuctions[i],
                                      );
                                    },
                                    onCancel: rowAuctions[i].isActive
                                        ? () {
                                            _confirmCancel(
                                              context,
                                              rowAuctions[i].id,
                                              rowAuctions[i].itemName,
                                            );
                                          }
                                        : null,
                                  )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                );
              },
              childCount: rowCount,
            ),
          ),
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, String id, String? name) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.t('forceCancelAuctionTitle')),
        content: Text(
          'Cancel "${name ?? 'this auction'}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('keep')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<AuctionsBloc>()
                  .add(AdminCancelAuctionFromListEvent(id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            child: Text(l10n.t('cancelAuction')),
          ),
        ],
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _SliverSkeletons extends StatelessWidget {
  const _SliverSkeletons({required this.metrics});

  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        final gap = metrics.gridGap;
        const rows = 2;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            metrics.pageHorizontalPadding,
            metrics.gridTopPadding,
            metrics.pageHorizontalPadding,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, rowIndex) {
                return Padding(
                  padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? gap : 0),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          const Expanded(child: AuctionCardSkeleton()),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: rows,
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty / Error ────────────────────────────────────────────────────────────

class _SliverEmptyState extends StatelessWidget {
  const _SliverEmptyState({
    required this.icon,
    required this.titleKey,
    this.subtitleKey,
  });

  final IconData icon;
  final String titleKey;
  final String? subtitleKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                l10n.t(titleKey),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (subtitleKey != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.t(subtitleKey!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverError extends StatelessWidget {
  const _SliverError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: scheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('failedToLoadAuction'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuctionsBloc>().add(LoadAllAuctionsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(l10n.t('retry')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
