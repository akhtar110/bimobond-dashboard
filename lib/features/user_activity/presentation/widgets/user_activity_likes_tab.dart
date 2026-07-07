import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../injection_container.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_like_entity.dart';
import '../../domain/usecases/get_user_likes.dart';
import '../bloc/user_likes_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'activity_list_widgets.dart';
import 'user_activity_shimmer.dart';

/// Displays a paginated list of likes filtered by [type].
///
/// - `type = 'made'`     → likes **given** by this user to other posts
/// - `type = 'received'` → likes **received** on this user's posts
///
/// Each instance creates and owns its own [UserLikesBloc], so two tabs
/// with different types can coexist in the same [TabBarView] without
/// sharing state.
class UserActivityLikesTab extends StatefulWidget {
  const UserActivityLikesTab({
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
  State<UserActivityLikesTab> createState() => _UserActivityLikesTabState();
}

class _UserActivityLikesTabState extends State<UserActivityLikesTab> {
  late final UserLikesBloc _bloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = UserLikesBloc(
      getUserLikes: sl<GetUserLikes>(),
      initialType: widget.type,
    )
      ..add(SetUserLikesUserId(widget.userId))
      ..add(LoadUserLikes());

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
    _bloc.add(LoadMoreUserLikes());
  }

  Future<void> _onRefresh() async {
    _bloc.add(RefreshUserLikes());
    await _bloc.stream.firstWhere((s) => !s.isLoading);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<UserLikesBloc, UserLikesState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return UserActivityListShimmer(isDark: widget.isDark);
          }

          if (state.hasError && state.items.isEmpty) {
            return ActivityErrorState(
              message: state.errorMessage ?? l10n.t('errorOccurred'),
              onRetry: () => _bloc.add(LoadUserLikes()),
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
                  type: widget.type,
                  onTap: () {
                    final like = state.items[index];
                    openPostInvestigation(
                      context,
                      postId: like.postId,
                      post: managedPostFromLike(
                        like,
                        profileUser: widget.sourceUser,
                        type: widget.type,
                      ),
                      sourceUser: widget.sourceUser,
                      activityContext: ActivityContext.like(
                        likeId: like.id,
                        activityDate: like.createdAt,
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

// ─── Like card ────────────────────────────────────────────────────────────────

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.like,
    required this.isDark,
    required this.type,
    required this.onTap,
  });

  final UserLikeEntity like;
  final bool isDark;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final post = like.post;
    final dateStr = DateFormat('MMM d, yyyy · HH:mm').format(like.createdAt);

    final isMade = type == 'made';

    return ActivityListCard(
      isDark: isDark,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                isMade ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: scheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMade
                      ? context.l10n.t('likedPost')
                      : context.l10n.t('receivedLike'),
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

          // ── Post description ───────────────────────────────────────────
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],

          // ── Post owner / liker ─────────────────────────────────────────
          if (post.user != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  isMade ? 'By ' : 'From ',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: ActivityAuthorRow(
                    username: post.user!.username,
                    fullName: post.user!.fullName,
                    avatarUrl: post.user!.avatarUrl,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],

          // For 'received' also show the liker's info if available
          if (!isMade && like.user != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Liked by ',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: ActivityAuthorRow(
                    username: like.user!.username,
                    fullName: like.user!.fullName,
                    avatarUrl: like.user!.avatarUrl,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
