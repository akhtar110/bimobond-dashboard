import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../notifications/presentation/bloc/user_notifications_bloc.dart';
import '../../../notifications/presentation/widgets/notification_item_card.dart';
import '../../../users/domain/entities/user_entity.dart';
import 'activity_empty_state.dart';
import 'user_activity_shimmer.dart';

class UserActivityNotificationsTab extends StatefulWidget {
  const UserActivityNotificationsTab({
    super.key,
    required this.userId,
    required this.isDark,
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityNotificationsTab> createState() =>
      _UserActivityNotificationsTabState();
}

class _UserActivityNotificationsTabState
    extends State<UserActivityNotificationsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final state = context.read<UserNotificationsBloc>().state;
    if (!state.loaded) {
      context
          .read<UserNotificationsBloc>()
          .add(LoadUserNotifications(userId: widget.userId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    final bloc = context.read<UserNotificationsBloc>();
    final state = bloc.state;
    if (state.hasReachedMax || state.loadingMore) return;
    bloc.add(LoadMoreUserNotifications(userId: widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<UserNotificationsBloc, UserNotificationsState>(
      buildWhen: (a, b) =>
          a.notifications != b.notifications ||
          a.loading != b.loading ||
          a.loadingMore != b.loadingMore ||
          a.error != b.error,
      builder: (context, state) {
        if (state.loading && state.notifications.isEmpty) {
          return UserActivityPostsGridShimmer(isDark: widget.isDark);
        }

        if (state.error != null && state.notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        context.read<UserNotificationsBloc>().add(
                              LoadUserNotifications(userId: widget.userId),
                            ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.t('retry')),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.notifications.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.notifications_none_rounded,
            message: l10n.t('noNotificationsYet'),
            isDark: widget.isDark,
          );
        }

        final count =
            state.total > 0 ? state.total : state.notifications.length;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.t('userNotifications'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: widget.isDark
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$count total',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Refresh',
                          onPressed: () =>
                              context.read<UserNotificationsBloc>().add(
                                    RefreshUserNotifications(
                                        userId: widget.userId),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              sliver: SliverList.separated(
                itemCount: state.notifications.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return NotificationItemCard(
                    notification: state.notifications[index],
                    isDark: widget.isDark,
                  );
                },
              ),
            ),
            if (state.loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (state.hasReachedMax && state.notifications.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      l10n.t('allNotificationsLoaded'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
