import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_follow_entity.dart';
import '../cubit/user_follow_list_cubit.dart';
import 'permission_denied_state.dart';

Future<void> showUserFollowListSheet({
  required BuildContext context,
  required String userId,
  required UserFollowListKind kind,
  required int count,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return BlocProvider(
        create: (_) => UserFollowListCubit(
          getUserFollowList: di.sl(),
          userId: userId,
          kind: kind,
        )..load(),
        child: UserFollowListSheet(kind: kind, count: count),
      );
    },
  );
}

class UserFollowListSheet extends StatelessWidget {
  const UserFollowListSheet({
    super.key,
    required this.kind,
    required this.count,
  });

  final UserFollowListKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final title = kind == UserFollowListKind.followers
        ? l10n.t('followers')
        : l10n.t('following');
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<UserFollowListCubit, UserFollowListState>(
                builder: (context, state) {
                  if (state is UserFollowListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is UserFollowListError) {
                    return PermissionDeniedState(
                      message: state.isPrivateAccount
                          ? l10n.tOr(
                              'privateAccountFollowToSeeMore',
                              'This account is private. Follow to see more.',
                            )
                          : state.message,
                      icon: state.isPrivateAccount
                          ? Icons.lock_outline_rounded
                          : Icons.people_outline_rounded,
                      onRetry: state.isPrivateAccount
                          ? null
                          : () => context.read<UserFollowListCubit>().load(),
                    );
                  }

                  if (state is UserFollowListLoaded) {
                    if (state.users.isEmpty) {
                      return _EmptyFollowList(
                        message: l10n.tOr(
                          'noUsersFound',
                          'No users found',
                        ),
                        onRetry: () =>
                            context.read<UserFollowListCubit>().load(),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _FollowUserTile(user: state.users[index]);
                            },
                          ),
                        ),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.error,
                              ),
                            ),
                          ),
                        if (state.hasMore)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: OutlinedButton.icon(
                              onPressed: state.isLoadingMore
                                  ? null
                                  : () => context
                                      .read<UserFollowListCubit>()
                                      .loadMore(),
                              icon: state.isLoadingMore
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.expand_more_rounded,
                                      size: 18),
                              label: Text(l10n.t('loadMoreComments')),
                            ),
                          ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUserTile extends StatelessWidget {
  const _FollowUserTile({required this.user});

  final UserFollowSummaryEntity user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = resolveMediaUrl(user.avatarUrl);
    final displayName =
        user.fullName?.isNotEmpty == true ? user.fullName! : '@${user.username}';

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            AppRoutes.userDetail,
            arguments: UserEntity(
              id: user.id,
              username: user.username,
              fullName: user.fullName,
              avatarUrl: user.avatarUrl,
              isVerified: user.isVerified,
              isPrivate: false,
              allowComments: true,
              allowDirectMsgs: true,
              language: 'en',
              theme: 'light',
              followerCount: 0,
              followingCount: 0,
              postCount: 0,
              totalLikes: 0,
              isBanned: false,
              roles: const [],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.verified_rounded,
                              size: 14, color: scheme.primary),
                        ],
                      ],
                    ),
                    if (user.fullName?.isNotEmpty == true)
                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFollowList extends StatelessWidget {
  const _EmptyFollowList({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.l10n.t('tryAgain')),
            ),
          ],
        ],
      ),
    );
  }
}
