import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/comment_entity.dart';
import '../bloc/post_management_bloc.dart';

class CommentsModerationPanel extends StatefulWidget {
  const CommentsModerationPanel({
    super.key,
    required this.state,
    required this.isDark,
    required this.isBusy,
    this.highlightCommentId,
  });

  final PostManagementLoaded state;
  final bool isDark;
  final bool isBusy;
  final String? highlightCommentId;

  @override
  State<CommentsModerationPanel> createState() =>
      _CommentsModerationPanelState();
}

class _CommentsModerationPanelState extends State<CommentsModerationPanel> {
  final _scrollController = ScrollController();
  final _highlightKeys = <String, GlobalKey>{};
  bool _didScrollToHighlight = false;

  PostManagementLoaded get state => widget.state;
  bool get isDark => widget.isDark;
  bool get isBusy => widget.isBusy;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommentsModerationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightCommentId != widget.highlightCommentId) {
      _didScrollToHighlight = false;
    }
  }

  void _scrollToHighlight() {
    final id = widget.highlightCommentId;
    if (id == null || _didScrollToHighlight) return;
    final key = _highlightKeys[id];
    if (key?.currentContext == null) return;
    _didScrollToHighlight = true;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bloc = context.read<PostManagementBloc>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.t('commentsModeration'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${state.comments.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.t('refresh'),
                visualDensity: VisualDensity.compact,
                onPressed: state.isCommentsLoading || isBusy
                    ? null
                    : () => bloc.add(LoadPostCommentsEvent()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBody(context, bloc, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PostManagementBloc bloc,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (state.isCommentsLoading && state.comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (state.commentsError != null && state.comments.isEmpty) {
      return _CommentsMessage(
        icon: Icons.error_outline_rounded,
        message: state.commentsError!,
        actionLabel: l10n.t('tryAgain'),
        onAction: () => bloc.add(LoadPostCommentsEvent()),
        isDark: isDark,
      );
    }

    if (state.comments.isEmpty) {
      return _CommentsMessage(
        icon: Icons.chat_bubble_outline,
        message: l10n.t('noCommentsOnPost'),
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.comments.length,
          separatorBuilder: (_, index) => Divider(
            height: 1,
            color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
          ),
          itemBuilder: (context, index) {
            final comment = state.comments[index];
            final isDeleting = state.deletingCommentId == comment.id;
            final highlighted =
                widget.highlightCommentId != null &&
                widget.highlightCommentId == comment.id;
            final key = _highlightKeys.putIfAbsent(
              comment.id,
              GlobalKey.new,
            );
            if (highlighted && !_didScrollToHighlight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _scrollToHighlight();
              });
            }
            return _CommentTile(
              key: key,
              comment: comment,
              isDark: isDark,
              isDeleting: isDeleting,
              highlighted: highlighted,
              disabled: isBusy || state.deletingCommentId != null,
              onDelete: () => _confirmDeleteComment(context, bloc, comment),
              onBanUser: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('banUserComingSoon')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            );
          },
        ),
        if (state.commentsHasMore) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: state.isCommentsLoadingMore || isBusy
                ? null
                : () => bloc.add(LoadMorePostCommentsEvent()),
            child: state.isCommentsLoadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.t('loadMoreComments')),
          ),
        ],
        if (state.commentsError != null && state.comments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            state.commentsError!,
            style: TextStyle(fontSize: 12, color: Colors.red.shade400),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteComment(
    BuildContext context,
    PostManagementBloc bloc,
    CommentEntity comment,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('deleteCommentTitle')),
        content: Text(l10n.t('deleteCommentMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(DeletePostCommentAdminEvent(comment.id));
    }
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    required this.isDark,
    required this.isDeleting,
    required this.highlighted,
    required this.disabled,
    required this.onDelete,
    required this.onBanUser,
  });

  final CommentEntity comment;
  final bool isDark;
  final bool isDeleting;
  final bool highlighted;
  final bool disabled;
  final VoidCallback onDelete;
  final VoidCallback onBanUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: highlighted
          ? BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary, width: 1.5),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlighted)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.t('selectedActivity'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.avatarUrl != null &&
                    comment.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null || comment.avatarUrl!.isEmpty
                ? Text(
                    comment.displayName.isNotEmpty
                        ? comment.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      dateFormat.format(comment.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? Colors.grey.shade500
                            : const Color(0xFF9CA3AF),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 12,
                      color: isDark
                          ? Colors.grey.shade500
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likeCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? Colors.grey.shade500
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (isDeleting)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.t('delete'),
                  visualDensity: VisualDensity.compact,
                  onPressed: disabled ? null : onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                ),
                IconButton(
                  tooltip: l10n.t('banUser'),
                  visualDensity: VisualDensity.compact,
                  onPressed: disabled ? null : onBanUser,
                  icon: Icon(
                    Icons.block_outlined,
                    size: 18,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommentsMessage extends StatelessWidget {
  const _CommentsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.isDark,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 40,
            color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
