import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../bloc/user_activity_bloc.dart';
import '../bloc/user_unified_activity_bloc.dart';
import '../utils/activity_navigation.dart';
import '../utils/user_repost_delete.dart';
import '../utils/user_repost_resolver.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';
import 'user_repost_details_sheet.dart';

class UserActivityTab extends StatefulWidget {
  const UserActivityTab({
    super.key,
    required this.isDark,
    this.sourceUser,
  });

  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityTab> createState() => _UserActivityTabState();
}

class _UserActivityTabState extends State<UserActivityTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<UserUnifiedActivityBloc>();
    if (!bloc.state.hasLoadedOnce) {
      bloc.add(LoadUserUnifiedActivity());
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

    final bloc = context.read<UserUnifiedActivityBloc>();
    final state = bloc.state;
    if (state.hasReachedMax || state.isLoadingMore) return;
    bloc.add(LoadMoreUserUnifiedActivity());
  }

  Future<void> _onRefresh() async {
    context.read<UserUnifiedActivityBloc>().add(RefreshUserUnifiedActivity());
    await context.read<UserUnifiedActivityBloc>().stream.firstWhere(
          (s) => !s.isLoading,
        );
  }

  String? _resolveCommentId(UserActivityItemEntity item) {
    final fromDetails = item.detailString('commentId');
    if (fromDetails != null && fromDetails.isNotEmpty) return fromDetails;
    if (item.type.toUpperCase() == 'COMMENT' && item.id.isNotEmpty) {
      return item.id;
    }
    return null;
  }

  ActivityContext _activityContextForItem(
    UserActivityItemEntity item,
    AppLocalizations l10n,
  ) {
    final type = item.type.toUpperCase();
    final postOwnerName = postOwnerDisplayNameFromActivityItem(item);
    final actor = activityActorFromActivityItem(item);

    if (type == 'COMMENT') {
      final commentId = _resolveCommentId(item);
      if (commentId != null) {
        return ActivityContext.comment(
          commentId: commentId,
          commentText: item.detailString('content') ?? '',
          activityDate: item.createdAt,
          postOwnerName: postOwnerName,
          commentUserId: actor?.id ?? item.detailString('userId'),
          commentUsername: actor?.username ?? item.detailString('username'),
        );
      }
    }

    if (type == 'LIKE_POST') {
      return ActivityContext.like(
        likeId: item.id,
        activityDate: item.createdAt,
      );
    }

    if (type.contains('MENTION')) {
      final commentId = _resolveCommentId(item);
      final isCommentMention = commentId != null;
      return ActivityContext.mention(
        activityDate: item.createdAt,
        mentionText: item.detailString('content') ??
            item.detailString('commentContent') ??
            item.detailString('postDescription'),
        mentionSource: isCommentMention
            ? l10n.t('mentionInComment')
            : l10n.t('mentionInPost'),
        postOwnerName: postOwnerName,
        commentId: commentId,
        commentText: item.detailString('content') ??
            item.detailString('commentContent'),
      );
    }

    return ActivityContext.feed(
      activityDate: item.createdAt,
      label: item.type,
    );
  }

  Future<void> _onItemTap(UserActivityItemEntity item) async {
    if (item.type.toUpperCase() == 'REPOST') {
      final repost = await resolveRepostForActivityItem(
        context,
        item,
        sourceUser: widget.sourceUser,
      );
      if (!mounted) return;
      await showUserRepostDetailsSheet(
        context,
        repost: repost,
        isDark: widget.isDark,
        sourceUser: widget.sourceUser,
      );
      return;
    }

    final postId = item.detailString('postId');
    if (postId != null && postId.isNotEmpty) {
      openPostInvestigation(
        context,
        postId: postId,
        post: managedPostFromActivityItem(
          item,
          profileUser: widget.sourceUser,
        ),
        sourceUser: widget.sourceUser,
        activityContext: _activityContextForItem(item, context.l10n),
      );
    }
  }

  bool _isItemTappable(UserActivityItemEntity item) {
    if (item.type.toUpperCase() == 'REPOST') return true;
    final postId = item.detailString('postId');
    return postId != null && postId.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserUnifiedActivityBloc, UserUnifiedActivityState>(
      builder: (context, state) {
        if (state.isLoading && state.items.isEmpty) {
          return UserActivityListShimmer(isDark: widget.isDark);
        }

        if (state.hasError && state.items.isEmpty) {
          return ActivityErrorState(
            message: state.errorMessage ?? context.l10n.t('errorOccurred'),
            onRetry: () => context
                .read<UserUnifiedActivityBloc>()
                .add(LoadUserUnifiedActivity()),
            isDark: widget.isDark,
          );
        }

        if (state.items.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.timeline,
            message: context.l10n.t('noActivityYet'),
            isDark: widget.isDark,
          );
        }

        return BlocBuilder<UserActivityBloc, UserActivityState>(
          buildWhen: (previous, current) =>
              previous.deletingRepostId != current.deletingRepostId,
          builder: (context, activityState) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final item = state.items[index];
                  final isLast = index == state.items.length - 1;
                  final isRepost = item.type.toUpperCase() == 'REPOST';
                  return _TimelineItem(
                    item: item,
                    isDark: widget.isDark,
                    isLast: isLast && !state.isLoadingMore,
                    isTappable: _isItemTappable(item),
                    onTap: () => _onItemTap(item),
                    onDelete: isRepost && item.id.isNotEmpty
                        ? () => confirmAndDeleteUserRepost(context, item.id)
                        : null,
                    isDeleting:
                        isRepost && activityState.deletingRepostId == item.id,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.isDark,
    required this.isLast,
    required this.isTappable,
    required this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  final UserActivityItemEntity item;
  final bool isDark;
  final bool isLast;
  final bool isTappable;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, color, title, body) = _resolvePresentation(context, item);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: ActivityListCard(
                isDark: isDark,
                onTap: isTappable ? onTap : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: onDelete != null ? 2 : 0,
                        right: onDelete != null ? 28 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d · HH:mm')
                                    .format(item.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: isDeleting
                            ? SizedBox(
                                width: 28,
                                height: 28,
                                child: Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              )
                            : Material(
                                color: scheme.surface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(8),
                                child: IconButton(
                                  tooltip: context.l10n.t('delete'),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: onDelete,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String, String) _resolvePresentation(
    BuildContext context,
    UserActivityItemEntity item,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    switch (item.type.toUpperCase()) {
      case 'CREATE_POST':
        return (
          Icons.videocam_outlined,
          theme.colorScheme.primary,
          l10n.t('activityCreatePost'),
          item.detailString('description') ?? '',
        );
      case 'COMMENT':
        return (
          Icons.chat_bubble_outline,
          theme.colorScheme.secondary,
          l10n.t('activityComment'),
          item.detailString('content') ??
              item.detailString('postDescription') ??
              '',
        );
      case 'LIKE_POST':
        return (
          Icons.favorite_border,
          theme.colorScheme.error,
          l10n.t('activityLikePost'),
          item.detailString('postDescription') ?? '',
        );
      case 'REPOST':
        final quote = item.detailString('quote');
        final description = item.detailString('postDescription') ?? '';
        final body = quote?.isNotEmpty == true
            ? '"$quote"\n$description'.trim()
            : description;
        return (
          Icons.repeat_rounded,
          theme.colorScheme.tertiary,
          l10n.tOr('activityRepost', 'Reposted a post'),
          body,
        );
      case 'SEND_GIFT':
        final giftName = item.detailString('giftName') ?? l10n.t('gift');
        final receiver = item.detailString('receiverUsername') ?? '';
        final price = item.detailDouble('priceCoins');
        final priceLabel =
            price != null ? ' · \$${price.toStringAsFixed(2)}' : '';
        return (
          Icons.card_giftcard,
          theme.colorScheme.tertiary,
          l10n.t('activitySendGift'),
          '$giftName → @$receiver$priceLabel',
        );
      default:
        return (
          Icons.circle_outlined,
          theme.colorScheme.outline,
          item.type,
          '',
        );
    }
  }
}
