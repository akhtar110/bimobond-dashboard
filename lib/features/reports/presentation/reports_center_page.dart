import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart' as di;
import '../../auction_reports/presentation/bloc/auction_reports_bloc.dart';
import '../../auction_reports/presentation/pages/auction_reports_tab.dart';
import '../../category_reports/presentation/bloc/category_reports_bloc.dart';
import '../../gift_reports/presentation/bloc/gift_reports_bloc.dart';
import '../../post_reports/presentation/bloc/post_reports_bloc.dart';
import '../../post_reports/presentation/pages/post_reports_tab.dart';
import '../../user_reports/presentation/bloc/user_reports_bloc.dart';
import '../../user_reports/presentation/pages/user_reports_tab.dart';
import 'bloc/reports_bloc.dart';
import 'reports_center_tab.dart';
import 'reports_inline_detail.dart';
import 'tabs/category_reports_hub_tab.dart';
import 'tabs/gift_reports_hub_tab.dart';
import 'tabs/moderation_reports_tab.dart';
import 'utils/reports_center_breakpoints.dart';
import 'utils/reports_center_theme.dart';
import 'widgets/reports_admin_header.dart';
import 'widgets/reports_center_nav.dart';
import 'widgets/reports_detail_overlay_drawer.dart';
import 'widgets/reports_keep_alive_tab.dart';

export 'reports_center_tab.dart';

class ReportsCenterPage extends StatefulWidget {
  const ReportsCenterPage({super.key});

  @override
  State<ReportsCenterPage> createState() => _ReportsCenterPageState();
}

class _ReportsCenterPageState extends State<ReportsCenterPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ReportsCenterTab _selected = ReportsCenterTab.moderation;
  final _loadedTabs = <ReportsCenterTab>{ReportsCenterTab.moderation};
  ReportsInlineDetail? _inlineDetail;

  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  String? _moderationStatus;
  String? _moderationType;

  UserReportsBloc? _userReportsBloc;
  PostReportsBloc? _postReportsBloc;
  AuctionReportsBloc? _auctionReportsBloc;
  GiftReportsBloc? _giftReportsBloc;
  CategoryReportsBloc? _categoryReportsBloc;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _userReportsBloc?.close();
    _postReportsBloc?.close();
    _auctionReportsBloc?.close();
    _giftReportsBloc?.close();
    _categoryReportsBloc?.close();
    super.dispose();
  }

  void _selectTab(ReportsCenterTab tab) {
    _prepareTab(tab);
    setState(() {
      _selected = tab;
      _loadedTabs.add(tab);
      _inlineDetail = null;
      _searchController.clear();
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _prepareTab(ReportsCenterTab tab) {
    switch (tab) {
      case ReportsCenterTab.moderation:
        if (!context.read<ReportsBloc>().isClosed) {
          context.read<ReportsBloc>().add(LoadReportsEvent());
        }
      case ReportsCenterTab.users:
        _kickUserReportsLoad(_ensureUserReportsBloc());
      case ReportsCenterTab.posts:
        _kickPostReportsLoad(_ensurePostReportsBloc());
      case ReportsCenterTab.auctions:
        _kickAuctionReportsLoad(_ensureAuctionReportsBloc());
      case ReportsCenterTab.gifts:
        _kickGiftReportsLoad(_ensureGiftReportsBloc());
      case ReportsCenterTab.categories:
        _kickCategoryReportsLoad(_ensureCategoryReportsBloc());
    }
  }

  UserReportsBloc _ensureUserReportsBloc() {
    final existing = _userReportsBloc;
    if (existing != null && !existing.isClosed) return existing;
    final bloc = di.sl<UserReportsBloc>();
    _userReportsBloc = bloc;
    return bloc;
  }

  PostReportsBloc _ensurePostReportsBloc() {
    final existing = _postReportsBloc;
    if (existing != null && !existing.isClosed) return existing;
    final bloc = di.sl<PostReportsBloc>();
    _postReportsBloc = bloc;
    return bloc;
  }

  AuctionReportsBloc _ensureAuctionReportsBloc() {
    final existing = _auctionReportsBloc;
    if (existing != null && !existing.isClosed) return existing;
    final bloc = di.sl<AuctionReportsBloc>();
    _auctionReportsBloc = bloc;
    return bloc;
  }

  GiftReportsBloc _ensureGiftReportsBloc() {
    final existing = _giftReportsBloc;
    if (existing != null && !existing.isClosed) return existing;
    final bloc = di.sl<GiftReportsBloc>();
    _giftReportsBloc = bloc;
    return bloc;
  }

  CategoryReportsBloc _ensureCategoryReportsBloc() {
    final existing = _categoryReportsBloc;
    if (existing != null && !existing.isClosed) return existing;
    final bloc = di.sl<CategoryReportsBloc>();
    _categoryReportsBloc = bloc;
    return bloc;
  }

  void _kickUserReportsLoad(UserReportsBloc bloc) {
    final state = bloc.state;
    if (state is UserReportsInitial || state is UserReportsError) {
      bloc.add(const LoadList(refresh: true));
    }
  }

  void _kickPostReportsLoad(PostReportsBloc bloc) {
    final state = bloc.state;
    if (state is PostReportsInitial || state is PostReportsError) {
      bloc.add(LoadPostReportsEvent(refresh: true));
    }
  }

  void _kickAuctionReportsLoad(AuctionReportsBloc bloc) {
    final state = bloc.state;
    if (state is AuctionReportsInitial || state is AuctionReportsError) {
      bloc.add(LoadAuctionReportsEvent(refresh: true));
    }
  }

  void _kickGiftReportsLoad(GiftReportsBloc bloc) {
    final state = bloc.state;
    final needsLoad = switch (state) {
      GiftReportsInitial() || GiftReportsError() => true,
      GiftReportsLoaded(
        :final items,
        :final isListFetching,
        :final listError,
      ) =>
        !isListFetching && items.isEmpty && listError == null,
      _ => false,
    };
    if (needsLoad) {
      bloc.add(LoadGiftReportsListEvent(refresh: true));
    }
  }

  void _kickCategoryReportsLoad(CategoryReportsBloc bloc) {
    final state = bloc.state;
    final needsLoad = switch (state) {
      CategoryReportsInitial() || CategoryReportsError() => true,
      CategoryReportsLoaded(
        :final items,
        :final isListFetching,
        :final listError,
      ) =>
        !isListFetching && items.isEmpty && listError == null,
      _ => false,
    };
    if (needsLoad) {
      bloc.add(LoadCategoryReportsListEvent(refresh: true));
    }
  }

  void _openDetail(ReportsInlineDetail detail) {
    setState(() => _inlineDetail = detail);
  }

  void _closeDetail() => setState(() => _inlineDetail = null);

  void _onGlobalSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      switch (_selected) {
        case ReportsCenterTab.users:
          _userReportsBloc?.add(SearchChanged(query));
        case ReportsCenterTab.posts:
          _postReportsBloc?.add(UpdatePostReportsSearchEvent(query));
        case ReportsCenterTab.auctions:
          _auctionReportsBloc?.add(UpdateAuctionReportsSearchEvent(query));
        case ReportsCenterTab.gifts:
          _giftReportsBloc?.add(UpdateGiftReportsSearchEvent(query));
        case ReportsCenterTab.categories:
          _categoryReportsBloc?.add(UpdateCategoryReportsSearchEvent(query));
        case ReportsCenterTab.moderation:
          break;
      }
    });
  }

  void _onRefresh() {
    switch (_selected) {
      case ReportsCenterTab.moderation:
        context.read<ReportsBloc>().add(RefreshReportsEvent());
      case ReportsCenterTab.users:
        _userReportsBloc?.add(const LoadList(refresh: true));
      case ReportsCenterTab.posts:
        _postReportsBloc?.add(LoadPostReportsEvent(refresh: true));
      case ReportsCenterTab.auctions:
        _auctionReportsBloc?.add(LoadAuctionReportsEvent(refresh: true));
      case ReportsCenterTab.gifts:
        _giftReportsBloc?.add(RefreshGiftReportsEvent());
      case ReportsCenterTab.categories:
        _categoryReportsBloc?.add(RefreshCategoryReportsEvent());
    }
  }

  void _onModerationStatusChanged(String? status) {
    setState(() => _moderationStatus = status);
    context.read<ReportsBloc>().add(
          FilterReportsEvent(status: status, type: _moderationType),
        );
  }

  void _onModerationTypeChanged(String? type) {
    setState(() => _moderationType = type);
    context.read<ReportsBloc>().add(
          FilterReportsEvent(status: _moderationStatus, type: type),
        );
  }

  Widget _buildTabBody(ReportsCenterTab tab) {
    if (!_loadedTabs.contains(tab)) {
      return const SizedBox.shrink();
    }

    final body = switch (tab) {
      ReportsCenterTab.moderation => const ModerationReportsTab(
          denseLayout: true,
        ),
      ReportsCenterTab.users when _userReportsBloc != null => BlocProvider.value(
          value: _userReportsBloc!,
          child: UserReportsTab(
            denseLayout: true,
            onUserTap: (userId) =>
                _openDetail(UserReportsInlineDetail(userId)),
          ),
        ),
      ReportsCenterTab.posts when _postReportsBloc != null => BlocProvider.value(
          value: _postReportsBloc!,
          child: PostReportsTab(
            denseLayout: true,
            onRowTap: (post) =>
                _openDetail(PostReportsInlineDetail(post.id)),
          ),
        ),
      ReportsCenterTab.auctions when _auctionReportsBloc != null =>
        BlocProvider.value(
          value: _auctionReportsBloc!,
          child: AuctionReportsTab(
            denseLayout: true,
            onRowTap: (auction) =>
                _openDetail(AuctionReportsInlineDetail(auction.id)),
          ),
        ),
      ReportsCenterTab.gifts when _giftReportsBloc != null => BlocProvider.value(
          value: _giftReportsBloc!,
          child: GiftReportsHubTab(
            denseLayout: true,
            onGiftTap: (giftId) =>
                _openDetail(GiftReportsInlineDetail(giftId)),
          ),
        ),
      ReportsCenterTab.categories when _categoryReportsBloc != null =>
        BlocProvider.value(
          value: _categoryReportsBloc!,
          child: CategoryReportsHubTab(
            denseLayout: true,
            onCategoryTap: (categoryId) =>
                _openDetail(CategoryReportsInlineDetail(categoryId)),
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };

    return ReportsKeepAliveTab(
      key: ValueKey(tab),
      child: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scheme = Theme.of(context).colorScheme;
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        final useRail = ReportsCenterBreakpoints.useNavRail(width);
        final useDrawer = ReportsCenterBreakpoints.useNavDrawer(width);
        final showTabStrip =
            ReportsCenterBreakpoints.useHorizontalTabStrip(width);
        final showDetail =
            _inlineDetail != null && _inlineDetail!.section == _selected;
        final contentPadding = ReportsCenterBreakpoints.pagePadding(width);
        final navWidth = ReportsCenterTheme.navRailWidth;
        final mainAreaWidth = useRail ? width - navWidth : width;
        final maxWidth = ReportsCenterTheme.maxContentWidth(width);

        return SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ReportsCenterTheme.pageBackgroundGradient(scheme),
            ),
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              drawer: useDrawer
                  ? ReportsCenterNavDrawer(
                      selected: _selected,
                      onSelected: _selectTab,
                    )
                  : null,
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (useRail)
                    ReportsCenterNavRail(
                      width: navWidth,
                      selected: _selected,
                      onSelected: _selectTab,
                    ),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ReportsAdminHeader(
                              selected: _selected,
                              onTabSelected: _selectTab,
                              searchController: _searchController,
                              onSearchChanged: _onGlobalSearch,
                              onRefresh: _onRefresh,
                              showModerationFilters:
                                  _selected == ReportsCenterTab.moderation,
                              hideSearch:
                                  _selected == ReportsCenterTab.moderation,
                              statusFilter: _moderationStatus,
                              onStatusFilterChanged: _onModerationStatusChanged,
                              typeFilter: _moderationType,
                              onTypeFilterChanged: _onModerationTypeChanged,
                              showTabStrip: showTabStrip,
                              showMenuButton: useDrawer,
                              onMenuTap: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              availableWidth: mainAreaWidth,
                            ),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxWidth,
                                  ),
                                  child: Padding(
                                    padding: contentPadding,
                                    child: IndexedStack(
                                      index: _selected.index,
                                      sizing: StackFit.expand,
                                      children: ReportsCenterTab.values
                                          .map(
                                            (tab) => _loadedTabs.contains(tab)
                                                ? SizedBox.expand(
                                                    child: _buildTabBody(tab),
                                                  )
                                                : const SizedBox.shrink(),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (showDetail)
                          ReportsDetailOverlayDrawer(
                            key: ValueKey(_inlineDetail),
                            detail: _inlineDetail!,
                            onClose: _closeDetail,
                            userReportsBloc: _userReportsBloc,
                            panelWidth:
                                ReportsCenterBreakpoints.detailPanelWidth(width),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
