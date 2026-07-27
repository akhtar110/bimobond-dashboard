import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../post_management/domain/usecases/delete_comment_admin.dart';
import '../../../post_management/presentation/utils/moderation_confirm_dialog.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
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
  String? _deletingCommentId;

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

  Future<void> _confirmDeleteComment(UserCommentEntity comment) async {
    final confirmed = await showDeleteCommentConfirmDialog(context);
    if (!confirmed || !mounted) return;

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deletingCommentId = comment.id);
    try {
      await sl<DeleteCommentAdmin>()(comment.id);
      if (!mounted) return;
      _bloc.add(RemoveUserCommentEvent(comment.id));
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(l10n.t('commentDeleted')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.errorContainer,
          content: Text(
            e.toString(),
            style: TextStyle(color: scheme.onErrorContainer),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingCommentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canDeleteComments = PermissionManager.canAccessStaffDashboard(context);

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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final comment = state.items[index];
                return _CommentCard(
                  comment: comment,
                  isDark: widget.isDark,
                  type: widget.type,
                  canDelete: canDeleteComments,
                  isDeleting: _deletingCommentId == comment.id,
                  onDelete: () => _confirmDeleteComment(comment),
                  onOpenPost: () {
                    final c = comment;
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
                        commentUserId: c.user?.id ?? c.userId,
                        commentUsername: c.user?.username,
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
    this.canDelete = false,
    this.isDeleting = false,
    this.onDelete,
  });

  final UserCommentEntity comment;
  final bool isDark;
  final String type;
  final VoidCallback onOpenPost;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateStr = DateFormat('MMM d · HH:mm').format(comment.createdAt);
    final post = comment.post;
    final contextUser =
        type == 'received' ? comment.user : post.user;
    final contextLabel = type == 'received' ? 'From' : 'On post by';

    return ActivityListCard(
      isDark: isDark,
      onTap: onOpenPost,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contextUser != null)
                      _CompactContextHeader(
                        label: contextLabel,
                        user: contextUser,
                        isDark: isDark,
                      )
                    else
                      Text(
                        contextLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.65),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        comment.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: _meta(scheme),
                  ),
                  if (canDelete) ...[
                    const SizedBox(height: 4),
                    if (isDeleting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: l10n.t('delete'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: scheme.error,
                        ),
                        onPressed: onDelete,
                      ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(
                icon: Icons.favorite_border_rounded,
                label: '${comment.likeCount}',
                scheme: scheme,
              ),
              _MetaChip(
                icon: Icons.reply_rounded,
                label: context.tr('repliesCount', {'count': '${comment.replyCount}'}),
                scheme: scheme,
              ),
              if (comment.isGift)
                _Badge(
                  icon: Icons.card_giftcard_rounded,
                  label: l10n.t('gift'),
                  color: scheme.primary,
                ),
            ],
          ),
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      post.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _meta(ColorScheme scheme) => TextStyle(
        fontSize: 11,
        color: scheme.onSurfaceVariant,
      );
}

// ─── Compact context header ───────────────────────────────────────────────────

class _CompactContextHeader extends StatelessWidget {
  const _CompactContextHeader({
    required this.label,
    required this.user,
    required this.isDark,
  });

  final String label;
  final ActivityUserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = (user.fullName != null && user.fullName!.isNotEmpty)
        ? user.fullName!
        : user.username;

    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        CircleAvatar(
          radius: 10,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Icon(Icons.person, size: 12, color: scheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
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
