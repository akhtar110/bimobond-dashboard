import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/activity_user_entity.dart';
import '../../domain/entities/user_comment_entity.dart';
import '../../domain/usecases/get_user_comments.dart';
import '../bloc/user_comments_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

/// Displays a paginated list of comments filtered by [type].
///
/// - `type = 'made'`     → comments written **by** this user
/// - `type = 'received'` → comments left **on** this user's posts
///
/// Each instance creates and owns its own [UserCommentsBloc], so two tabs
/// with different types can coexist in the same [TabBarView] without
/// sharing state.
class UserActivityCommentsTab extends StatefulWidget {
  const UserActivityCommentsTab({
    super.key,
    required this.userId,
    required this.isDark,
    this.type = 'received',
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  /// `'made'` | `'received'`
  final String type;

  @override
  State<UserActivityCommentsTab> createState() =>
      _UserActivityCommentsTabState();
}

class _UserActivityCommentsTabState extends State<UserActivityCommentsTab> {
  late final UserCommentsBloc _bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = UserCommentsBloc(
      getUserComments: sl<GetUserComments>(),
      initialType: widget.type,
    )
      ..add(SetUserCommentsUserId(widget.userId))
      ..add(LoadUserComments());

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    final state = _bloc.state;
    if (state.hasReachedMax || state.isLoadingMore) return;
    _bloc.add(LoadMoreUserComments());
  }

  Future<void> _onRefresh() async {
    _bloc.add(RefreshUserComments());
    await _bloc.stream.firstWhere((s) => !s.isLoading);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<UserCommentsBloc, UserCommentsState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return UserActivityListShimmer(isDark: widget.isDark);
          }

          if (state.hasError && state.items.isEmpty) {
            return ActivityErrorState(
              message: state.errorMessage ?? l10n.t('errorOccurred'),
              onRetry: () => _bloc.add(LoadUserComments()),
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
                  type: widget.type,
                  onOpenPost: () {
                    final c = state.items[index];
                    final owner = c.post.user?.displayName;
                    openPostInvestigation(
                      context,
                      postId: c.postId,
                      post: managedPostFromComment(
                        c,
                        profileUser: widget.sourceUser,
                        type: widget.type,
                      ),
                      sourceUser: widget.sourceUser,
                      activityContext: ActivityContext.comment(
                        commentId: c.id,
                        commentText: c.content,
                        activityDate: c.createdAt,
                        postOwnerName: owner,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Comment card ─────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isDark,
    required this.type,
    required this.onOpenPost,
  });

  final UserCommentEntity comment;
  final bool isDark;
  final String type;
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
          // ── Comment text + badges ───────────────────────────────────────
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
              if (comment.isGift) ...[
                const SizedBox(width: 8),
                _Badge(
                  icon: Icons.card_giftcard,
                  label: l10n.t('gift'),
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),

          // ── Meta row ───────────────────────────────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('${comment.likeCount}', style: _meta(isDark)),
              const SizedBox(width: 12),
              Icon(Icons.reply_outlined,
                  size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                context.tr('repliesCount', {'count': '${comment.replyCount}'}),
                style: _meta(isDark),
              ),
              const Spacer(),
              Text(dateStr, style: _meta(isDark)),
            ],
          ),

          // ── Post context ───────────────────────────────────────────────
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          const SizedBox(height: 10),

          // 'made'  → show post owner as context ("on post by …")
          // 'received' → show who wrote the comment ("from …")
          if (type == 'received' && comment.user != null)
            _ContextRow(
              label: 'From',
              user: comment.user!,
              isDark: isDark,
            )
          else if (type == 'made' && post.user != null)
            _ContextRow(
              label: 'On post by',
              user: post.user!,
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

  TextStyle _meta(bool isDark) => TextStyle(
        fontSize: 11,
        color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
      );
}

// ─── Context row ──────────────────────────────────────────────────────────────

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.label,
    required this.user,
    required this.isDark,
  });

  final String label;
  final ActivityUserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: ActivityAuthorRow(
            username: user.username,
            fullName: user.fullName,
            avatarUrl: user.avatarUrl,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
