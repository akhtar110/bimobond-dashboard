import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_comment_entity.dart';
import '../bloc/user_comments_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

class UserActivityCommentsTab extends StatefulWidget {
  const UserActivityCommentsTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<UserActivityCommentsTab> createState() =>
      _UserActivityCommentsTabState();
}

class _UserActivityCommentsTabState extends State<UserActivityCommentsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserCommentsBloc>();
    if (!bloc.state.hasLoadedOnce) {
      bloc.add(LoadUserComments());
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

    final bloc = context.read<UserCommentsBloc>();
    final state = bloc.state;
    if (state.hasReachedMax || state.isLoadingMore) return;
    bloc.add(LoadMoreUserComments());
  }

  Future<void> _onRefresh() async {
    context.read<UserCommentsBloc>().add(RefreshUserComments());
    await context.read<UserCommentsBloc>().stream.firstWhere(
          (s) => !s.isLoading,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UserCommentsBloc, UserCommentsState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return UserActivityListShimmer(isDark: widget.isDark);
        }

        if (state.hasError && state.items.isEmpty) {
          return ActivityErrorState(
            message: state.errorMessage ?? l10n.t('errorOccurred'),
            onRetry: () =>
                context.read<UserCommentsBloc>().add(LoadUserComments()),
            isDark: widget.isDark,
          );
        }

        if (state.items.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.chat_bubble_outline,
            message: l10n.t('noCommentsYet'),
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
              return _CommentCard(
                comment: state.items[index],
                isDark: widget.isDark,
                onOpenPost: () => openPostManagementById(
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

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isDark,
    required this.onOpenPost,
  });

  final UserCommentEntity comment;
  final bool isDark;
  final VoidCallback onOpenPost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(comment.createdAt);
    final post = comment.post;

    return ActivityListCard(
      isDark: isDark,
      onTap: onOpenPost,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
              if (comment.isGift)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.t('gift'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${comment.likeCount}', style: _metaStyle(isDark)),
              const SizedBox(width: 12),
              Icon(Icons.reply_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                context.tr('repliesCount', {'count': '${comment.replyCount}'}),
                style: _metaStyle(isDark),
              ),
              const Spacer(),
              Text(dateStr, style: _metaStyle(isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          const SizedBox(height: 10),
          if (post.user != null)
            ActivityAuthorRow(
              username: post.user!.username,
              fullName: post.user!.fullName,
              avatarUrl: post.user!.avatarUrl,
              isDark: isDark,
            ),
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _metaStyle(bool isDark) {
    return TextStyle(
      fontSize: 11,
      color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
    );
  }
}
