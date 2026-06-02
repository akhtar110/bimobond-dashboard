import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_like_entity.dart';
import '../bloc/user_likes_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

class UserActivityLikesTab extends StatefulWidget {
  const UserActivityLikesTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<UserActivityLikesTab> createState() => _UserActivityLikesTabState();
}

class _UserActivityLikesTabState extends State<UserActivityLikesTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserLikesBloc>();
    if (!bloc.state.hasLoadedOnce) {
      bloc.add(LoadUserLikes());
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

    final bloc = context.read<UserLikesBloc>();
    final state = bloc.state;
    if (state.hasReachedMax || state.isLoadingMore) return;
    bloc.add(LoadMoreUserLikes());
  }

  Future<void> _onRefresh() async {
    context.read<UserLikesBloc>().add(RefreshUserLikes());
    await context.read<UserLikesBloc>().stream.firstWhere((s) => !s.isLoading);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UserLikesBloc, UserLikesState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return UserActivityListShimmer(isDark: widget.isDark);
        }

        if (state.hasError && state.items.isEmpty) {
          return ActivityErrorState(
            message: state.errorMessage ?? l10n.t('errorOccurred'),
            onRetry: () => context.read<UserLikesBloc>().add(LoadUserLikes()),
            isDark: widget.isDark,
          );
        }

        if (state.items.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.favorite_border,
            message: l10n.t('noLikesYet'),
            isDark: widget.isDark,
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _LikeCard(
                like: state.items[index],
                isDark: widget.isDark,
                onTap: () => openPostManagementById(
                  context,
                  state.items[index].postId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.like,
    required this.isDark,
    required this.onTap,
  });

  final UserLikeEntity like;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = like.post;
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(like.createdAt);

    return ActivityListCard(
      isDark: isDark,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.t('likedPost'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (post.description != null && post.description!.isNotEmpty)
            Text(
              post.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: isDark ? Colors.grey.shade200 : const Color(0xFF374151),
              ),
            ),
          if (post.user != null) ...[
            const SizedBox(height: 10),
            ActivityAuthorRow(
              username: post.user!.username,
              fullName: post.user!.fullName,
              avatarUrl: post.user!.avatarUrl,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}
