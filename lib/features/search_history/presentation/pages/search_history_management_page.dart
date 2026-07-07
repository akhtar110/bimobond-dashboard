import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../bloc/search_history_bloc.dart';
import '../bloc/search_history_event.dart';
import '../bloc/search_history_state.dart';
import '../utils/search_history_responsive.dart';
import '../widgets/search_history_bulk_bar.dart';
import '../widgets/search_history_filters_bar.dart';
import '../widgets/search_history_overview_cards.dart';
import '../widgets/search_history_table.dart';

class SearchHistoryManagementPage extends StatelessWidget {
  const SearchHistoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = SearchHistoryLayoutMetrics(
          getSearchHistoryDeviceType(constraints.maxWidth),
        );

        return BlocConsumer<SearchHistoryBloc, SearchHistoryState>(
          listenWhen: (p, c) =>
              c is SearchHistoryLoaded &&
              c.message != null &&
              (p is! SearchHistoryLoaded || p.message != c.message),
          listener: (context, state) {
            if (state is! SearchHistoryLoaded || state.message == null) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: state.isErrorMessage
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
          },
          builder: (context, state) {
            final isInitialLoad = state is SearchHistoryInitial ||
                state is SearchHistoryLoading;
            final isRefreshing =
                state is SearchHistoryLoaded && state.isActioning;

            final compactHeader = metrics.isMobile;
            final titleStyle = (compactHeader
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.headlineSmall)
                ?.copyWith(fontWeight: FontWeight.w800);

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
                  Text(
                    l10n.tOr('searchHistoryTitle', 'Search History'),
                    style: titleStyle,
                  ),
                  SizedBox(height: metrics.toolbarFilterGap),
                  Text(
                    l10n.tOr(
                      'searchHistorySubtitle',
                      'Monitor and moderate user search queries across the platform.',
                    ),
                    maxLines: compactHeader ? 2 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: compactHeader ? 12 : null,
                          height: compactHeader ? 1.3 : null,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  SizedBox(height: metrics.toolbarSectionGap),
                  if (state is SearchHistoryLoaded && state.overview != null) ...[
                    SearchHistoryOverviewCards(
                      overview: state.overview!,
                      metrics: metrics,
                    ),
                    SizedBox(height: metrics.sectionGap),
                  ] else if (isInitialLoad) ...[
                    const SearchHistoryOverviewSkeleton(),
                    SizedBox(height: metrics.sectionGap),
                  ],
                  SearchHistoryFiltersBar(metrics: metrics),
                  SizedBox(height: metrics.toolbarFilterGap),
                  const SearchHistoryBulkBar(),
                  if (isInitialLoad || isRefreshing) ...[
                    SizedBox(height: metrics.toolbarFilterGap),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  SizedBox(height: metrics.sectionGap),
                  Expanded(
                    child: _ManagementBody(
                      state: state,
                      metrics: metrics,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ManagementBody extends StatelessWidget {
  const _ManagementBody({
    required this.state,
    required this.metrics,
  });

  final SearchHistoryState state;
  final SearchHistoryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final current = state;
    if (current is SearchHistoryError) {
      return Center(
        child: ErrorView(
          message: current.message,
          retryLabel: context.l10n.t('retry'),
          onRetry: () => context.read<SearchHistoryBloc>().add(
                const LoadSearchHistory(),
              ),
        ),
      );
    }

    if (current is SearchHistoryInitial || current is SearchHistoryLoading) {
      return const Center(child: LoadingView());
    }

    final loaded = current as SearchHistoryLoaded;
    return SearchHistoryTable(
      showProgress: loaded.isActioning,
      metrics: metrics,
    );
  }
}
