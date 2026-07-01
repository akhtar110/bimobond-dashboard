import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../bloc/search_history_bloc.dart';
import '../bloc/search_history_event.dart';
import '../bloc/search_history_state.dart';
import 'search_history_bulk_bar.dart';
import 'search_history_filters_bar.dart';
import 'search_history_table.dart';

/// Embedded search history panel for user detail tab or scoped views.
class SearchHistoryUserPanel extends StatefulWidget {
  const SearchHistoryUserPanel({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  final String userId;
  final bool embedded;

  @override
  State<SearchHistoryUserPanel> createState() => _SearchHistoryUserPanelState();
}

class _SearchHistoryUserPanelState extends State<SearchHistoryUserPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<SearchHistoryBloc>();
      bloc.add(SetSearchHistoryScope(userId: widget.userId));
      bloc.add(LoadUserSearchHistory(userId: widget.userId));
    });
  }

  @override
  Widget build(BuildContext context) {
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
        final isInitialLoad =
            state is SearchHistoryInitial || state is SearchHistoryLoading;
        final isRefreshing =
            state is SearchHistoryLoaded && state.isActioning;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.embedded) ...[
              Text(
                context.l10n.tOr('searchHistory', 'Search History'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: PromotionsSpace.lg),
            ],
            SearchHistoryFiltersBar(embedded: true),
            const SizedBox(height: PromotionsSpace.sm),
            const SearchHistoryBulkBar(),
            if (isInitialLoad || isRefreshing) ...[
              const SizedBox(height: PromotionsSpace.sm),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: PromotionsSpace.md),
            Expanded(
              child: _EmbeddedBody(state: state, userId: widget.userId),
            ),
          ],
        );
      },
    );
  }
}

class _EmbeddedBody extends StatelessWidget {
  const _EmbeddedBody({
    required this.state,
    required this.userId,
  });

  final SearchHistoryState state;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final current = state;
    if (current is SearchHistoryError) {
      return ErrorView(
        message: current.message,
        retryLabel: context.l10n.t('retry'),
        onRetry: () => context.read<SearchHistoryBloc>().add(
              LoadUserSearchHistory(userId: userId),
            ),
      );
    }

    if (current is SearchHistoryInitial || current is SearchHistoryLoading) {
      return const LoadingView();
    }

    final loaded = current as SearchHistoryLoaded;
    return SearchHistoryTable(
      showUserColumn: false,
      showSelection: true,
      showProgress: loaded.isActioning,
    );
  }
}
