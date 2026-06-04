import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../bloc/user_unified_activity_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

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

  void _onItemTap(UserActivityItemEntity item) {
    final postId = item.detailString('postId');
    if (postId != null && postId.isNotEmpty) {
      openPostInvestigation(
        context,
        postId: postId,
        sourceUser: widget.sourceUser,
        activityContext: ActivityContext.feed(
          activityDate: item.createdAt,
          label: item.type,
        ),
      );
    }
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
              return _TimelineItem(
                item: item,
                isDark: widget.isDark,
                isLast: isLast && !state.isLoadingMore,
                onTap: () => _onItemTap(item),
              );
            },
          ),
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
    required this.onTap,
  });

  final UserActivityItemEntity item;
  final bool isDark;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
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
                onTap: item.detailString('postId') != null ? onTap : null,
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
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d · HH:mm').format(item.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade500
                                : const Color(0xFF9CA3AF),
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
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
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
          const Color(0xFF2563EB),
          l10n.t('activityComment'),
          item.detailString('content') ??
              item.detailString('postDescription') ??
              '',
        );
      case 'LIKE_POST':
        return (
          Icons.favorite_border,
          const Color(0xFFDC2626),
          l10n.t('activityLikePost'),
          item.detailString('postDescription') ?? '',
        );
      case 'SEND_GIFT':
        final giftName = item.detailString('giftName') ?? l10n.t('gift');
        final receiver = item.detailString('receiverUsername') ?? '';
        final price = item.detailDouble('priceUsd');
        final priceLabel =
            price != null ? ' · \$${price.toStringAsFixed(2)}' : '';
        return (
          Icons.card_giftcard,
          const Color(0xFF9333EA),
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
