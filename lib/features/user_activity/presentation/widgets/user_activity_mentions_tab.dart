import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_mention_entity.dart';
import '../../domain/usecases/get_user_mentions.dart';
import '../bloc/user_mentions_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

/// Paginated mentions list filtered by [type]:
/// `'made'` | `'received'` | `'all'`.
///
/// Each instance owns its own [UserMentionsBloc] so subtabs stay independent.
class UserActivityMentionsTab extends StatefulWidget {
  const UserActivityMentionsTab({
    super.key,
    required this.userId,
    required this.isDark,
    this.type = 'received',
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  /// `'made'` | `'received'` | `'all'`
  final String type;

  @override
  State<UserActivityMentionsTab> createState() =>
      _UserActivityMentionsTabState();
}

class _UserActivityMentionsTabState extends State<UserActivityMentionsTab> {
  late final UserMentionsBloc _bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = UserMentionsBloc(
      getUserMentions: sl<GetUserMentions>(),
      initialType: widget.type,
    )
      ..add(SetUserMentionsUserId(widget.userId))
      ..add(LoadUserMentions());

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
    _bloc.add(LoadMoreUserMentions());
  }

  Future<void> _onRefresh() async {
    _bloc.add(RefreshUserMentions());
    await _bloc.stream.firstWhere((s) => !s.isLoading);
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

  String? _resolveCommentId(UserMentionEntity mention) {
    if (mention.commentId != null && mention.commentId!.isNotEmpty) {
      return mention.commentId;
    }
    final nestedId = mention.comment?.id;
    if (nestedId != null && nestedId.isNotEmpty) return nestedId;
    return null;
  }

  bool _isCommentMention(UserMentionEntity mention) =>
      _resolveCommentId(mention) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<UserMentionsBloc, UserMentionsState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return UserActivityListShimmer(isDark: widget.isDark);
          }

          if (state.hasError && state.items.isEmpty) {
            return ActivityErrorState(
              message: state.errorMessage ?? l10n.t('errorOccurred'),
              onRetry: () => _bloc.add(LoadUserMentions()),
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
                  type: widget.type,
                  onTap: postId != null
                      ? () {
                          final m = mention;
                          final commentId = _resolveCommentId(m);
                          final isCommentMention = _isCommentMention(m);
                          final text = isCommentMention && m.comment != null
                              ? m.comment!.content
                              : m.post?.description;
                          openPostInvestigation(
                            context,
                            postId: postId,
                            post: managedPostFromMention(
                              m,
                              profileUser: widget.sourceUser,
                            ),
                            sourceUser: widget.sourceUser,
                            activityContext: ActivityContext.mention(
                              activityDate: m.createdAt,
                              mentionText: text,
                              mentionSource: isCommentMention
                                  ? l10n.t('mentionInComment')
                                  : l10n.t('mentionInPost'),
                              postOwnerName: m.post?.user?.displayName,
                              commentId: commentId,
                              commentText: m.comment?.content,
                            ),
                          );
                        }
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MentionCard extends StatelessWidget {
  const _MentionCard({
    required this.mention,
    required this.isDark,
    required this.type,
    this.onTap,
  });

  final UserMentionEntity mention;
  final bool isDark;
  final String type;
  final VoidCallback? onTap;

  String _headerLabel(BuildContext context) {
    final l10n = context.l10n;
    if (type == 'made') {
      return mention.isCommentMention
          ? l10n.tOr('mentionMadeInComment', 'Mention made in comment')
          : l10n.tOr('mentionMadeInPost', 'Mention made in post');
    }
    if (type == 'received') {
      return mention.isCommentMention
          ? l10n.t('mentionInComment')
          : l10n.t('mentionInPost');
    }
    return mention.isCommentMention
        ? l10n.t('mentionInComment')
        : l10n.t('mentionInPost');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                  _headerLabel(context),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
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
                color: scheme.onSurfaceVariant,
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
                  color: scheme.onSurfaceVariant,
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
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
