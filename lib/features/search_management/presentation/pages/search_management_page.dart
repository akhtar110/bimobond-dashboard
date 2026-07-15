import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/search_management_entities.dart';
import '../bloc/search_management_bloc.dart';
import '../bloc/search_management_event.dart';
import '../bloc/search_management_state.dart';
import '../utils/search_management_responsive.dart';
import '../widgets/search_management_content_panel.dart';
import '../widgets/search_management_filters_bar.dart';
import '../widgets/search_management_overview_cards.dart';

class SearchManagementPage extends StatelessWidget {
  const SearchManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('SearchManagementPage rebuilt');
    return PersistentBlocProvider<SearchManagementBloc>(
      debugLabel: 'SearchManagementPage',
      create: () => di.sl<SearchManagementBloc>()
        ..add(const LoadSearchManagementEvent()),
      child: const _SearchManagementView(),
    );
  }
}

class _SearchManagementView extends StatefulWidget {
  const _SearchManagementView();

  @override
  State<_SearchManagementView> createState() => _SearchManagementViewState();
}

class _SearchManagementViewState extends State<_SearchManagementView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    SearchManagementTab.overview,
    SearchManagementTab.searches,
    SearchManagementTab.users,
    SearchManagementTab.sounds,
    SearchManagementTab.hashtags,
    SearchManagementTab.trends,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabTick);
  }

  void _onTabTick() {
    if (_tabController.indexIsChanging) return;
    context.read<SearchManagementBloc>().add(
          SearchManagementUiTabChangedEvent(_tabs[_tabController.index]),
        );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabTick);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = SearchManagementLayoutMetrics(
          getSearchManagementDeviceType(constraints.maxWidth),
        );

        return BlocConsumer<SearchManagementBloc, SearchManagementState>(
          listenWhen: (p, c) =>
              c is SearchManagementLoaded &&
              c.message != null &&
              (p is! SearchManagementLoaded || p.message != c.message),
          listener: (context, state) {
            if (state is! SearchManagementLoaded || state.message == null) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor:
                    state.isErrorMessage ? scheme.error : null,
              ),
            );
          },
          builder: (context, state) {
            final isInitial = state is SearchManagementInitial ||
                state is SearchManagementLoading;
            final isRefreshing =
                state is SearchManagementLoaded && state.isRefreshing;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.pageHorizontalPadding,
                metrics.pageTopPadding,
                metrics.pageHorizontalPadding,
                metrics.pageBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(
                    metrics: metrics,
                    onRefresh: () => context
                        .read<SearchManagementBloc>()
                        .add(const RefreshSearchManagementEvent()),
                  ),
                  SizedBox(height: metrics.toolbarFilterGap),
                  if (state is SearchManagementLoaded) ...[
                    SearchManagementOverviewCards(
                      overview: state.overview,
                      metrics: metrics,
                    ),
                    SizedBox(height: metrics.toolbarFilterGap),
                  ] else if (isInitial) ...[
                    const SearchManagementOverviewSkeleton(),
                    SizedBox(height: metrics.toolbarFilterGap),
                  ],
                  SearchManagementFiltersBar(metrics: metrics),
                  SizedBox(height: metrics.toolbarFilterGap),
                  Material(
                    color: scheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      indicator: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: scheme.onPrimaryContainer,
                      unselectedLabelColor: scheme.onSurfaceVariant,
                      labelStyle: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      unselectedLabelStyle:
                          Theme.of(context).textTheme.labelMedium,
                      tabs: [
                        Tab(
                          height: 36,
                          text: l10n.tOr('searchMgmtTabOverview', 'Overview'),
                        ),
                        Tab(
                          height: 36,
                          text: l10n.tOr('searchMgmtTabSearches', 'Searches'),
                        ),
                        Tab(
                          height: 36,
                          text: l10n.tOr('searchMgmtTabUsers', 'Users'),
                        ),
                        Tab(
                          height: 36,
                          text: l10n.tOr('searchMgmtTabSounds', 'Sounds'),
                        ),
                        Tab(
                          height: 36,
                          text: l10n.tOr('searchMgmtTabHashtags', 'Hashtags'),
                        ),
                        Tab(
                          height: 36,
                          text: l10n.tOr('searchMgmtTabTrends', 'Trends'),
                        ),
                      ],
                    ),
                  ),
                  if (isInitial || isRefreshing) ...[
                    SizedBox(height: metrics.toolbarFilterGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(height: metrics.toolbarFilterGap),
                  Expanded(child: _Body(state: state, metrics: metrics)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.metrics,
    required this.onRefresh,
  });

  final SearchManagementLayoutMetrics metrics;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final compact = metrics.isMobile;
    final titleStyle = (compact
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.titleLarge)
        ?.copyWith(fontWeight: FontWeight.w800);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.tOr('refresh', 'Refresh'),
          onPressed: onRefresh,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 2),
        if (compact)
          IconButton.outlined(
            tooltip: l10n.tOr('export', 'Export'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.tOr(
                      'searchMgmtExportComingSoon',
                      'Export coming soon',
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 18),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.tOr(
                      'searchMgmtExportComingSoon',
                      'Export coming soon',
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l10n.tOr('export', 'Export')),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tOr('searchMgmtTitle', 'Search Management'),
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: metrics.toolbarFilterGap),
              Text(
                l10n.tOr(
                  'searchMgmtSubtitle',
                  'Explore unified search, trends, and platform search activity.',
                ),
                maxLines: compact ? 2 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: compact ? 12 : null,
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.metrics});

  final SearchManagementState state;
  final SearchManagementLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      SearchManagementLoading() || SearchManagementInitial() =>
        const LoadingView(),
      SearchManagementError(:final message) => ErrorView(
          message: message,
          retryLabel: l10n.tOr('retry', 'Retry'),
          onRetry: () => context
              .read<SearchManagementBloc>()
              .add(const LoadSearchManagementEvent()),
        ),
      SearchManagementLoaded loaded => Stack(
          children: [
            SearchManagementContentPanel(state: loaded, metrics: metrics),
            if (loaded.isLoadingMore)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
