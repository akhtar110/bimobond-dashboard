import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../bloc/search_history_bloc.dart';
import '../bloc/search_history_event.dart';
import '../bloc/search_history_state.dart';
import 'search_history_delete_dialog.dart';

class SearchHistoryBulkBar extends StatelessWidget {
  const SearchHistoryBulkBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SearchHistoryBloc, SearchHistoryState>(
      buildWhen: (p, c) =>
          p is SearchHistoryLoaded &&
          c is SearchHistoryLoaded &&
          p.selectedIds != c.selectedIds,
      builder: (context, state) {
        if (state is! SearchHistoryLoaded || state.selectedIds.isEmpty) {
          return const SizedBox.shrink();
        }

        final bloc = context.read<SearchHistoryBloc>();
        final count = state.selectedIds.length;

        final clearSelectionButton = TextButton(
          onPressed: () => bloc.add(const ClearSearchHistorySelection()),
          child: Text(l10n.t('clearSelection')),
        );
        final deleteButton = OutlinedButton.icon(
          onPressed: () => _bulkDelete(context, state),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(
            l10n.tOr('searchHistoryBulkDelete', 'Delete selected'),
          ),
        );
        final scopedAction = state.isUserScoped
            ? FilledButton.tonalIcon(
                onPressed: () => _clearUserAll(context, state),
                icon: const Icon(Icons.history_toggle_off_rounded),
                label: Text(
                  l10n.tOr(
                    'searchHistoryClearAllForUser',
                    'Clear all for user',
                  ),
                ),
              )
            : FilledButton.tonalIcon(
                onPressed: () => _bulkClearUsers(context, state),
                icon: const Icon(Icons.person_off_outlined),
                label: Text(
                  l10n.tOr(
                    'searchHistoryClearUserHistory',
                    'Clear user history',
                  ),
                ),
              );

        final countLabel = Text(
          context.tr('searchHistorySelectedCount', {
            'count': '$count',
          }),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        );

        return Material(
          elevation: 2,
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final wrapActions = constraints.maxWidth < 960;

              final actionButtons = <Widget>[
                clearSelectionButton,
                deleteButton,
                scopedAction,
              ];

              if (compact) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PromotionsSpace.lg,
                    vertical: PromotionsSpace.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      countLabel,
                      const SizedBox(height: PromotionsSpace.sm),
                      Wrap(
                        spacing: PromotionsSpace.sm,
                        runSpacing: PromotionsSpace.sm,
                        alignment: WrapAlignment.end,
                        children: actionButtons,
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PromotionsSpace.lg,
                  vertical: PromotionsSpace.sm,
                ),
                child: Row(
                  children: [
                    Flexible(child: countLabel),
                    if (wrapActions) ...[
                      const SizedBox(width: PromotionsSpace.sm),
                      Flexible(
                        child: Wrap(
                          spacing: PromotionsSpace.sm,
                          runSpacing: PromotionsSpace.sm,
                          alignment: WrapAlignment.end,
                          children: actionButtons,
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                      ...actionButtons.expand(
                        (button) => [
                          const SizedBox(width: PromotionsSpace.sm),
                          button,
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _bulkDelete(
    BuildContext context,
    SearchHistoryLoaded state,
  ) async {
    final confirmed = await showSearchHistoryDeleteDialog(
      context,
      title: context.l10n.tOr(
        'searchHistoryBulkDeleteTitle',
        'Delete selected entries?',
      ),
      message: context.l10n.tOr(
        'searchHistoryBulkDeleteMessage',
        'Selected search history rows will be permanently removed.',
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<SearchHistoryBloc>().add(
          BulkDeleteSearchHistory(state.selectedIds.toList()),
        );
  }

  Future<void> _bulkClearUsers(
    BuildContext context,
    SearchHistoryLoaded state,
  ) async {
    final userIds = state.items
        .where((e) => state.selectedIds.contains(e.id) && e.user != null)
        .map((e) => e.user!.id)
        .toSet()
        .toList();
    if (userIds.isEmpty) return;

    final confirmed = await showSearchHistoryDeleteDialog(
      context,
      title: context.l10n.tOr(
        'searchHistoryClearUserHistory',
        'Clear user history',
      ),
      message: context.l10n.tOr(
        'searchHistoryClearUserHistoryMessage',
        'All search history for selected users will be cleared.',
      ),
      confirmLabel: context.l10n.tOr('clear', 'Clear'),
    );
    if (confirmed != true || !context.mounted) return;

    context.read<SearchHistoryBloc>().add(
          BulkClearUsersSearchHistory(
            userIds: userIds,
            category: state.query.category,
          ),
        );
  }

  Future<void> _clearUserAll(
    BuildContext context,
    SearchHistoryLoaded state,
  ) async {
    final userId = state.scopedUserId;
    if (userId == null) return;

    final confirmed = await showSearchHistoryDeleteDialog(
      context,
      title: context.l10n.tOr(
        'searchHistoryClearAllForUser',
        'Clear all for user',
      ),
      message: context.l10n.tOr(
        'searchHistoryClearAllForUserMessage',
        'Remove all search history for this user.',
      ),
      confirmLabel: context.l10n.tOr('clear', 'Clear'),
    );
    if (confirmed != true || !context.mounted) return;

    context.read<SearchHistoryBloc>().add(
          ClearSearchHistory(
            userId: userId,
            category: state.query.category,
          ),
        );
  }
}
