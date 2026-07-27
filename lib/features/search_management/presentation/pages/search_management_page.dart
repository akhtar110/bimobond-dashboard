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
        final compact = metrics.isMobile;
        final tabHeight = compact ? 34.0 : 36.0;

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
                  _SearchManagementTabs(
                    controller: _tabController,
                    height: tabHeight,
                    compact: compact,
                    labels: [
                      l10n.tOr('searchMgmtTabOverview', 'Overview'),
                      l10n.tOr('searchMgmtTabSearches', 'Searches'),
                      l10n.tOr('searchMgmtTabUsers', 'Users'),
                      l10n.tOr('searchMgmtTabSounds', 'Sounds'),
                      l10n.tOr('searchMgmtTabHashtags', 'Hashtags'),
                      l10n.tOr('searchMgmtTabTrends', 'Trends'),
                    ],
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

/// Dense, scrollable pill tabs — works on narrow and wide screens.
class _SearchManagementTabs extends StatelessWidget {
  const _SearchManagementTabs({
    required this.controller,
    required this.height,
    required this.labels,
    this.compact = false,
  });

  final TabController controller;
  final double height;
  final List<String> labels;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12 : 13,
          height: 1.1,
        );

    return SizedBox(
      height: height + 4,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.symmetric(horizontal: compact ? 2 : 4),
        padding: EdgeInsets.zero,
        splashBorderRadius: BorderRadius.circular(999),
        indicator: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        indicatorPadding: const EdgeInsets.symmetric(vertical: 2),
        labelColor: scheme.onPrimary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: labelStyle,
        unselectedLabelStyle: labelStyle?.copyWith(fontWeight: FontWeight.w600),
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.08),
        ),
        tabs: [
          for (final label in labels)
            Tab(
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
                child: Text(label),
              ),
            ),
        ],
      ),
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
    final controlHeight = compact ? 34.0 : 36.0;
    final titleStyle = (compact
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.titleLarge)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.45,
      height: 1.05,
      color: scheme.onSurface,
    );

    void showExportSoon() {
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
    }

    final refreshBtn = IconButton.filledTonal(
      tooltip: l10n.tOr('refresh', 'Refresh'),
      onPressed: onRefresh,
      icon: Icon(Icons.refresh_rounded, size: compact ? 18 : 20),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: Size(controlHeight, controlHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    final exportBtn = compact
        ? IconButton.outlined(
            tooltip: l10n.tOr('export', 'Export'),
            onPressed: showExportSoon,
            icon: const Icon(Icons.download_outlined, size: 18),
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: Size(controlHeight, controlHeight),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: showExportSoon,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(l10n.tOr('export', 'Export')),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, controlHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              l10n.tOr('searchMgmtTitle', 'Search Management'),
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          exportBtn,
          SizedBox(width: compact ? 6 : 8),
          refreshBtn,
        ],
      ),
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
      SearchManagementLoaded loaded =>
          SearchManagementContentPanel(state: loaded, metrics: metrics),
      _ => const SizedBox.shrink(),
    };
  }
}
