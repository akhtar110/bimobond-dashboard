import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_mention_entity.dart';
import '../bloc/user_mentions_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

class UserActivityMentionsTab extends StatefulWidget {
  const UserActivityMentionsTab({super.key, required this.isDark});

  final bool isDark;

  @override
  State<UserActivityMentionsTab> createState() =>
      _UserActivityMentionsTabState();
}

class _UserActivityMentionsTabState extends State<UserActivityMentionsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserMentionsBloc>();
    if (!bloc.state.hasLoadedOnce) {
      bloc.add(LoadUserMentions());
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

    final bloc = context.read<UserMentionsBloc>();
    final state = bloc.state;
    if (state.hasReachedMax || state.isLoadingMore) return;
    bloc.add(LoadMoreUserMentions());
  }

  Future<void> _onRefresh() async {
    context.read<UserMentionsBloc>().add(RefreshUserMentions());
    await context.read<UserMentionsBloc>().stream.firstWhere(
          (s) => !s.isLoading,
        );
  }

  String? _resolvePostId(UserMentionEntity mention) {
    if (mention.postId != null && mention.postId!.isNotEmpty) {
      return mention.postId;
    }
    if (mention.post?.id.isNotEmpty == true) return mention.post!.id;
    if (mention.comment?.post.id.isNotEmpty == true) {
      return mention.comment!.post.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<UserMentionsBloc, UserMentionsState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return UserActivityListShimmer(isDark: widget.isDark);
        }

        if (state.hasError && state.items.isEmpty) {
          return ActivityErrorState(
            message: state.errorMessage ?? l10n.t('errorOccurred'),
            onRetry: () =>
                context.read<UserMentionsBloc>().add(LoadUserMentions()),
            isDark: widget.isDark,
          );
        }

        if (state.items.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.alternate_email,
            message: l10n.t('noMentionsYet'),
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
              final mention = state.items[index];
              final postId = _resolvePostId(mention);
              return _MentionCard(
                mention: mention,
                isDark: widget.isDark,
                onTap: postId != null
                    ? () => openPostManagementById(context, postId)
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}

class _MentionCard extends StatelessWidget {
  const _MentionCard({
    required this.mention,
    required this.isDark,
    this.onTap,
  });

  final UserMentionEntity mention;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(mention.createdAt);
    final isComment = mention.isCommentMention;

    return ActivityListCard(
      isDark: isDark,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComment ? Icons.chat_bubble_outline : Icons.article_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isComment ? l10n.t('mentionInComment') : l10n.t('mentionInPost'),
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
          if (isComment && mention.comment != null) ...[
            ActivityAuthorRow(
              username: mention.comment!.user.username,
              fullName: mention.comment!.user.fullName,
              avatarUrl: mention.comment!.user.avatarUrl,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Text(
              mention.comment!.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: isDark ? Colors.grey.shade200 : const Color(0xFF374151),
              ),
            ),
            if (mention.comment!.post.description != null &&
                mention.comment!.post.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                mention.comment!.post.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ] else if (mention.post != null) ...[
            if (mention.post!.user != null)
              ActivityAuthorRow(
                username: mention.post!.user!.username,
                fullName: mention.post!.user!.fullName,
                avatarUrl: mention.post!.user!.avatarUrl,
                isDark: isDark,
              ),
            if (mention.post!.description != null &&
                mention.post!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                mention.post!.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: isDark ? Colors.grey.shade200 : const Color(0xFF374151),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
