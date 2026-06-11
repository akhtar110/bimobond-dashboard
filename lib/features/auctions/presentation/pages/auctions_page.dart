import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/auction_entity.dart';
import '../bloc/auctions_bloc.dart';
import '../services/auction_image_lookup.dart';
import '../widgets/auction_card.dart';

/// Responsive column count for admin catalog grids.
int adminGridColumnCount(double width) {
  if (width > 1600) return 6;
  if (width > 1300) return 5;
  if (width > 1000) return 4;
  if (width > 700) return 3;
  if (width > 500) return 2;
  return 1;
}

class AuctionsPage extends StatefulWidget {
  const AuctionsPage({super.key});

  @override
  State<AuctionsPage> createState() => _AuctionsPageState();
}

class _AuctionsPageState extends State<AuctionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuctionsBloc>().add(LoadAllAuctionsEvent(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: BlocConsumer<AuctionsBloc, AuctionsState>(
        listener: (context, state) {},
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              _SliverHeader(theme: theme, state: state),
              if (state is AuctionsLoaded) ...[
                _SliverFilters(
                  key: const ValueKey('auctions_filter_bar'),
                  loaded: state,
                  theme: theme,
                ),
                _SliverGrid(loaded: state),
                if (state.lastPage > 1)
                  _SliverPagination(loaded: state),
              ] else if (state is AuctionsLoading) ...[
                const _SliverSkeletons(),
              ] else if (state is AuctionsError) ...[
                _SliverError(message: state.message),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sliver Header ────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  const _SliverHeader({
    required this.theme,
    required this.state,
  });

  final ThemeData theme;
  final AuctionsState state;

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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.start,
                              children: [
                                _StatChip(
                                  label: l10n.t('total'),
                                  value: loaded.total.toString(),
                                  icon: Icons.gavel_rounded,
                                  color: scheme.primary,
                                ),
                                _StatChip(
                                  label: l10n.t('active'),
                                  value: loaded.activeCount.toString(),
                                  icon: Icons.play_circle_rounded,
                                  color: scheme.primary,
                                ),
                                _StatChip(
                                  label: l10n.t('completed'),
                                  value: loaded.completedCount.toString(),
                                  icon: Icons.check_circle_rounded,
                                  color: scheme.secondary,
                                ),
                                _StatChip(
                                  label: l10n.t('cancelled'),
                                  value: loaded.cancelledCount.toString(),
                                  icon: Icons.cancel_rounded,
                                  color: scheme.error,
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
                const SizedBox(height: 12),
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
  const _SliverFilters({super.key, required this.loaded, required this.theme});

  final AuctionsLoaded loaded;
  final ThemeData theme;

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.tOr('searchAuctions', 'Search auctions…'),
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: _clearSearch,
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    ),
                    filled: true,
                    fillColor: scheme.surface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < filters.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
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
                      const SizedBox(width: 8),
                      _AuctionFilterMenu<AuctionSortOption>(
                        label: l10n.t('sortBy'),
                        value: loaded.sortOption,
                        items: AuctionSortOption.values,
                        itemLabel: (option) => switch (option) {
                          AuctionSortOption.newestFirst =>
                            l10n.t('sortNewestFirst'),
                          AuctionSortOption.oldestFirst =>
                            l10n.t('sortOldestFirst'),
                          AuctionSortOption.highestBid =>
                            l10n.t('sortHighestBid'),
                          AuctionSortOption.lowestBid =>
                            l10n.t('sortLowestBid'),
                          AuctionSortOption.mostViewed =>
                            l10n.t('sortMostViewed'),
                          AuctionSortOption.endingSoon =>
                            l10n.t('sortEndingSoon'),
                        },
                        onSelected: (value) =>
                            bloc.add(UpdateAuctionSortEvent(value)),
                      ),
                      const SizedBox(width: 8),
                      _AuctionFilterMenu<AuctionTypeFilter>(
                        label: l10n.t('auctionType'),
                        value: loaded.typeFilter,
                        items: AuctionTypeFilter.values,
                        itemLabel: (option) => switch (option) {
                          AuctionTypeFilter.all => l10n.t('allTypes'),
                          AuctionTypeFilter.fixed =>
                            l10n.t('auctionTypeFixed'),
                          AuctionTypeFilter.timed =>
                            l10n.t('auctionTypeTimed'),
                          AuctionTypeFilter.live =>
                            l10n.t('auctionTypeLive'),
                        },
                        onSelected: (value) => bloc
                            .add(UpdateAuctionTypeFilterEvent(value)),
                      ),
                      const SizedBox(width: 8),
                      _AuctionDateFilterMenu(
                        dateRange: loaded.dateRange,
                        onSelected: (range) => bloc.add(
                          UpdateAuctionDateRangeEvent(range),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (loaded.isFetching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
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
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

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
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
              style: const TextStyle(fontSize: 12),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: scheme.onSurfaceVariant),
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
  });

  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onSelected;

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
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────

class _SliverPagination extends StatelessWidget {
  const _SliverPagination({required this.loaded});

  final AuctionsLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AuctionsBloc>();
    final scheme = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: loaded.currentPage > 1
                      ? () => bloc.add(
                            GoToAuctionsPageEvent(loaded.currentPage - 1),
                          )
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: scheme.onSurfaceVariant,
                ),
                Text(
                  '${loaded.currentPage} / ${loaded.lastPage}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: loaded.currentPage < loaded.lastPage
                      ? () => bloc.add(
                            GoToAuctionsPageEvent(loaded.currentPage + 1),
                          )
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: scheme.onSurfaceVariant,
                ),
              ],
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
  const _SliverGrid({required this.loaded});
  final AuctionsLoaded loaded;

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
        const gap = 12.0;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
  const _SliverSkeletons();

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = adminGridColumnCount(constraints.crossAxisExtent);
        const gap = 12.0;
        const rows = 2;

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
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
                          if (i > 0) const SizedBox(width: gap),
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
