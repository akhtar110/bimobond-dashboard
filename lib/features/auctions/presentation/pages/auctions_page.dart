import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../rbac/presentation/widgets/access_denied_view.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/auction_entity.dart';
import '../bloc/auctions_bloc.dart';
import '../services/auction_image_lookup.dart';
import '../utils/auctions_page_tab.dart';
import '../utils/auctions_responsive.dart';
import '../widgets/auction_card.dart';
import '../widgets/auctions_page_header_tabs.dart';
import '../widgets/auctions_page_toolbar.dart';
import '../../../seller_verification/presentation/bloc/seller_verification_bloc.dart';
import '../../../seller_verification/presentation/widgets/seller_verification_panel.dart';
import '../../../seller_verification/presentation/widgets/seller_verification_page_toolbar.dart';

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
    return FeatureAccessBoundary(
      canAccess: PermissionManager.canReadAuctions,
      child: PersistentBlocProvider<AuctionsBloc>(
        debugLabel: 'AuctionsPage',
        create: () =>
            sl<AuctionsBloc>()..add(LoadAllAuctionsEvent(refresh: true)),
        child: BlocProvider(
          create: (_) =>
              sl<SellerVerificationBloc>()
                ..add(const LoadSellerVerificationsEvent(refresh: true)),
          child: const _AuctionsPageView(),
        ),
      ),
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
  AuctionsPageTab _activeTab = AuctionsPageTab.auctions;

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
      if (_activeTab == AuctionsPageTab.sellerVerification) {
        context.read<SellerVerificationBloc>().add(
          const LoadMoreSellerVerificationsEvent(),
        );
      } else {
        context.read<AuctionsBloc>().add(LoadMoreAuctionsEvent());
      }
    }
  }

  void _onRefresh() {
    if (_activeTab == AuctionsPageTab.sellerVerification) {
      context.read<SellerVerificationBloc>().add(
        const LoadSellerVerificationsEvent(refresh: true),
      );
    } else {
      context.read<AuctionsBloc>().add(LoadAllAuctionsEvent(refresh: true));
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
          body: BlocBuilder<SellerVerificationBloc, SellerVerificationState>(
            builder: (context, sellerState) {
              return BlocConsumer<AuctionsBloc, AuctionsState>(
                listenWhen: (previous, current) {
                  if (current is! AuctionsLoaded ||
                      current.actionError == null) {
                    return false;
                  }
                  if (previous is! AuctionsLoaded) return true;
                  return previous.actionError != current.actionError;
                },
                listener: (context, state) {
                  if (state is! AuctionsLoaded || state.actionError == null) {
                    return;
                  }
                  final scheme = Theme.of(context).colorScheme;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.actionError!),
                      backgroundColor: scheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                builder: (context, state) {
                  final showAuctionsTab =
                      _activeTab == AuctionsPageTab.auctions;
                  final isHeaderLoading = showAuctionsTab
                      ? state is AuctionsLoading
                      : sellerState is SellerVerificationLoading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: scheme.surfaceContainerLowest,
                        elevation: 0,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AuctionsLayoutMetrics.maxContentWidth,
                            ),
                            child: _AuctionsPageHeader(
                              theme: theme,
                              metrics: metrics,
                              activeTab: _activeTab,
                              isLoading: isHeaderLoading,
                              onTabChanged: (tab) {
                                setState(() => _activeTab = tab);
                                if (tab == AuctionsPageTab.sellerVerification) {
                                  final sellerBloc = context
                                      .read<SellerVerificationBloc>();
                                  if (sellerBloc.state
                                      is! SellerVerificationLoaded) {
                                    sellerBloc.add(
                                      const LoadSellerVerificationsEvent(
                                        refresh: true,
                                      ),
                                    );
                                  }
                                }
                              },
                              onRefresh: _onRefresh,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            if (showAuctionsTab)
                              SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth:
                                          AuctionsLayoutMetrics.maxContentWidth,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        metrics.pageHorizontalPadding,
                                        2,
                                        metrics.pageHorizontalPadding,
                                        0,
                                      ),
                                      child: const AuctionsActiveFilterChips(),
                                    ),
                                  ),
                                ),
                              ),
                            if (showAuctionsTab) ...[
                              if (state is AuctionsLoaded) ...[
                                _SliverGrid(loaded: state, metrics: metrics),
                                if (metrics.useDesktopPagination &&
                                    state.total > 0)
                                  _SliverPagination(
                                    loaded: state,
                                    metrics: metrics,
                                  ),
                                if (metrics.useInfiniteScroll &&
                                    state.isLoadingMore)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ] else if (state is AuctionsLoading) ...[
                                _SliverSkeletons(metrics: metrics),
                              ] else if (state is AuctionsError) ...[
                                _SliverError(message: state.message),
                              ],
                            ] else if (PermissionManager.canReadSellerVerification(
                              context,
                            )) ...[
                              SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth:
                                          AuctionsLayoutMetrics.maxContentWidth,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        metrics.pageHorizontalPadding,
                                        2,
                                        metrics.pageHorizontalPadding,
                                        0,
                                      ),
                                      child:
                                          const SellerVerificationActiveFilterChips(),
                                    ),
                                  ),
                                ),
                              ),
                              SellerVerificationPanel(
                                screenWidth: windowWidth,
                                useDesktopPagination:
                                    metrics.useDesktopPagination,
                                pageHorizontalPadding:
                                    metrics.pageHorizontalPadding,
                              ),
                            ] else
                              SliverPadding(
                                padding: EdgeInsets.all(
                                  metrics.pageHorizontalPadding,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: AccessDeniedView(
                                    message: context.l10n.tOr(
                                      'sellerVerificationNoAccess',
                                      'You do not have permission to review seller applications.',
                                    ),
                                  ),
                                ),
                              ),
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom: metrics.isMobile ? 16 : 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Fixed page header ────────────────────────────────────────────────────────

class _AuctionsPageHeader extends StatelessWidget {
  const _AuctionsPageHeader({
    required this.theme,
    required this.metrics,
    required this.activeTab,
    required this.isLoading,
    required this.onTabChanged,
    required this.onRefresh,
  });

  final ThemeData theme;
  final AuctionsLayoutMetrics metrics;
  final AuctionsPageTab activeTab;
  final bool isLoading;
  final ValueChanged<AuctionsPageTab> onTabChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = theme.colorScheme;
    final showAuctionStats = activeTab == AuctionsPageTab.auctions;
    final compact = metrics.isCompact;
    final controlSize = compact ? 36.0 : 40.0;

    final refreshBtn = Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isLoading ? null : onRefresh,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: controlSize,
          height: controlSize,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.refresh_rounded,
                    size: compact ? 18 : 20,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
    );

    final title = showAuctionStats
        ? l10n.t('auctions')
        : l10n.tOr('sellerVerificationTab', 'Seller verification');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.pageHorizontalPadding,
          metrics.pageTopPadding,
          metrics.pageHorizontalPadding,
          metrics.sectionGap,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final wide = metrics.headerWideAt(width);
              final medium = metrics.headerMediumAt(width);
              final titleSize = metrics.titleFontSizeAt(width);

              final tabs = AuctionsPageHeaderTabs(
                activeTab: activeTab,
                onTabChanged: onTabChanged,
                compact: compact,
                fullWidth: !wide,
              );

              final titleText = Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                  height: 1.1,
                  fontSize: titleSize,
                ),
              );

              if (wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: titleText),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: tabs),
                        const SizedBox(width: 8),
                        refreshBtn,
                      ],
                    ),
                    if (showAuctionStats) ...[
                      SizedBox(height: compact ? 6 : 8),
                      AuctionsPageToolbar(metrics: metrics),
                    ] else ...[
                      SizedBox(height: compact ? 6 : 8),
                      SellerVerificationPageToolbar(metrics: metrics),
                    ],
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: titleText),
                      if (medium) ...[const SizedBox(width: 8), refreshBtn],
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  tabs,
                  if (showAuctionStats) ...[
                    SizedBox(height: compact ? 6 : 8),
                    AuctionsPageToolbar(metrics: metrics),
                  ] else ...[
                    SizedBox(height: compact ? 6 : 8),
                    SellerVerificationPageToolbar(metrics: metrics),
                  ],
                  if (!medium) ...[
                    SizedBox(height: compact ? 6 : 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: refreshBtn,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────

class _SliverPagination extends StatelessWidget {
  const _SliverPagination({required this.loaded, required this.metrics});

  final AuctionsLoaded loaded;
  final AuctionsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AuctionsLayoutMetrics.maxContentWidth,
          ),
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
  const _SliverGrid({required this.loaded, required this.metrics});
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
        final extent = constraints.crossAxisExtent;
        final maxW = AuctionsLayoutMetrics.maxContentWidth;
        final sideInset = extent > maxW
            ? ((extent - maxW) / 2) + metrics.pageHorizontalPadding
            : metrics.pageHorizontalPadding;
        final contentWidth = (extent - sideInset * 2).clamp(0.0, maxW);
        final columns = adminGridColumnCount(contentWidth);
        final rowCount = (auctions.length / columns).ceil();
        final gap = metrics.gridGap;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            sideInset,
            metrics.gridTopPadding,
            sideInset,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, rowIndex) {
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
                                onCancel:
                                    PermissionManager.canModerateAuctions(
                                          context,
                                        ) &&
                                        rowAuctions[i].canAdminCancelOrBan
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
            }, childCount: rowCount),
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
          l10n.tOr(
            'forceCancelAuctionConfirm',
            'Cancel "${name ?? l10n.tOr('thisAuction', 'this auction')}"? This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('keep')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuctionsBloc>().add(
                AdminCancelAuctionFromListEvent(id),
              );
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
        final extent = constraints.crossAxisExtent;
        final maxW = AuctionsLayoutMetrics.maxContentWidth;
        final sideInset = extent > maxW
            ? ((extent - maxW) / 2) + metrics.pageHorizontalPadding
            : metrics.pageHorizontalPadding;
        final contentWidth = (extent - sideInset * 2).clamp(0.0, maxW);
        final columns = adminGridColumnCount(contentWidth);
        final gap = metrics.gridGap;
        const rows = 2;

        return SliverPadding(
          padding: EdgeInsets.fromLTRB(
            sideInset,
            metrics.gridTopPadding,
            sideInset,
            0,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, rowIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? gap : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      const Expanded(child: AuctionCardSkeleton()),
                    ],
                  ],
                ),
              );
            }, childCount: rows),
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
              Icon(Icons.error_outline_rounded, size: 44, color: scheme.error),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
