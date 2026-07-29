import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../user_activity/presentation/widgets/activity_empty_state.dart';
import '../../../user_activity/presentation/widgets/activity_list_widgets.dart';
import '../../../user_activity/presentation/widgets/user_activity_shimmer.dart';
import '../../domain/entities/user_history_entity.dart';
import '../bloc/user_history_bloc.dart';
import '../bloc/user_history_event.dart';
import '../bloc/user_history_state.dart';
import '../utils/user_history_post_navigation.dart';
import 'user_history_filters_bar.dart';
import 'user_history_timeline_card.dart';
import '../../../users/domain/entities/user_entity.dart';

class UserHistoryTab extends StatefulWidget {
  const UserHistoryTab({
    super.key,
    required this.isDark,
    this.sourceUser,
  });

  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserHistoryTab> createState() => _UserHistoryTabState();
}

class _UserHistoryTabState extends State<UserHistoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<UserHistoryBloc>();
    if (!bloc.state.hasLoadedOnce) {
      bloc.add(const LoadUserHistory());
    }
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<UserHistoryBloc>();
    bloc.add(const RefreshUserHistory());
    await bloc.stream.firstWhere(
      (s) => s is! UserHistoryLoading && s is! UserHistoryLoadingMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UserHistoryFiltersBar(),
        Expanded(
          child: BlocConsumer<UserHistoryBloc, UserHistoryState>(
            listenWhen: (previous, current) =>
                current is UserHistoryError && current.items.isNotEmpty,
            listener: (context, state) {
              if (state is! UserHistoryError) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            },
            builder: (context, state) {
              if (state is UserHistoryLoading || state is UserHistoryInitial) {
                return UserActivityListShimmer(isDark: widget.isDark);
              }

              if (state is UserHistoryError && state.items.isEmpty) {
                return ActivityErrorState(
                  message: state.message,
                  onRetry: () => context
                      .read<UserHistoryBloc>()
                      .add(const LoadUserHistory()),
                  isDark: widget.isDark,
                );
              }

              if (state is UserHistoryEmpty) {
                return ActivityEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  message: l10n.tOr(
                    'noUserHistoryFound',
                    'No user history found.',
                  ),
                  isDark: widget.isDark,
                );
              }

              final items = switch (state) {
                UserHistoryLoaded(:final items) => items,
                UserHistoryLoadingMore(:final items) => items,
                UserHistoryError(:final items) => items,
                _ => const <UserHistoryEntity>[],
              };

              final meta = switch (state) {
                UserHistoryLoaded(:final meta) => meta,
                UserHistoryLoadingMore(:final meta) => meta,
                UserHistoryError(:final meta) => meta,
                _ => null,
              };

              if (items.isEmpty) {
                return ActivityEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  message: l10n.tOr(
                    'noUserHistoryFound',
                    'No user history found.',
                  ),
                  isDark: widget.isDark,
                );
              }

              final isLoadingMore = state is UserHistoryLoadingMore;

              return Column(
                children: [
                  if (isLoadingMore) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final canOpen = canOpenUserHistoryItem(item);
                          return UserHistoryTimelineCard(
                            item: item,
                            isDark: widget.isDark,
                            isLast: index == items.length - 1,
                            onTap: canOpen
                                ? () => openUserHistoryItem(
                                      context,
                                      item,
                                      sourceUser: widget.sourceUser,
                                    )
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  if (meta != null)
                    AppPaginationBar(
                      currentPage: meta.page < 1 ? 1 : meta.page,
                      lastPage: meta.totalPages < 1 ? 1 : meta.totalPages,
                      total: meta.total,
                      pageSize: meta.limit > 0 ? meta.limit : 30,
                      itemCount: items.length,
                      hideWhenSinglePage: false,
                      showTopBorder: true,
                      onPageChanged: (page) {
                        context
                            .read<UserHistoryBloc>()
                            .add(ChangeUserHistoryPage(page));
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
