import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../user_activity/presentation/widgets/activity_list_widgets.dart';
import '../../domain/entities/user_history_entity.dart';
import '../../../reports/presentation/utils/report_detail_labels.dart';

class UserHistoryTimelineCard extends StatelessWidget {
  const UserHistoryTimelineCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.isLast,
    this.onTap,
  });

  final UserHistoryEntity item;
  final bool isDark;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final presentation = _resolvePresentation(context, item);

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
                    color: presentation.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: presentation.color.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    presentation.icon,
                    size: 16,
                    color: presentation.color,
                  ),
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
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            presentation.title,
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
                    if (presentation.lines.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...presentation.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (presentation.thumbnailUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CachedNetworkImage(
                            imageUrl: presentation.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
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

  _HistoryPresentation _resolvePresentation(
    BuildContext context,
    UserHistoryEntity item,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final type = item.normalizedType;

    switch (type) {
      case UserHistoryTypes.screenView:
        return _HistoryPresentation(
          icon: Icons.smartphone_outlined,
          color: theme.colorScheme.primary,
          title: l10n.tOr('userHistoryScreenViewed', 'Screen Viewed'),
          lines: [
            if (item.dataString('targetId') != null)
              '${l10n.tOr('userHistoryTargetScreen', 'Target Screen')}: '
                  '${item.dataString('targetId')}',
            if (_metaPath(item) != null)
              '${l10n.tOr('userHistoryPath', 'Path')}: ${_metaPath(item)}',
          ],
        );
      case UserHistoryTypes.profileView:
        return _HistoryPresentation(
          icon: Icons.person_search_outlined,
          color: theme.colorScheme.secondary,
          title: l10n.tOr('userHistoryViewedProfile', 'Viewed Profile'),
          lines: [
            if (item.dataString('targetId') != null ||
                item.nestedString('profile', 'id') != null)
              '${l10n.tOr('userHistoryProfileId', 'Profile ID')}: '
                  '${item.dataString('targetId') ?? item.nestedString('profile', 'id')}',
          ],
        );
      case UserHistoryTypes.share:
        return _HistoryPresentation(
          icon: Icons.share_outlined,
          color: theme.colorScheme.tertiary,
          title: l10n.tOr('userHistorySharedContent', 'Shared Content'),
          lines: [
            if (item.dataString('targetId') != null)
              '${l10n.tOr('userHistoryTargetId', 'Target ID')}: '
                  '${item.dataString('targetId')}',
          ],
        );
      case UserHistoryTypes.profileVisitGiven:
        return _HistoryPresentation(
          icon: Icons.outbound_outlined,
          color: theme.colorScheme.primary,
          title: l10n.tOr('userHistoryVisitedProfile', 'Visited Profile'),
          lines: [
            if (_username(item, 'profile') != null)
              '${l10n.tOr('username', 'Username')}: ${_username(item, 'profile')}',
            if (item.dataNum('visitCount') != null)
              '${l10n.tOr('userHistoryVisitCount', 'Visit Count')}: '
                  '${item.dataNum('visitCount')}',
            if (item.dataString('source') != null)
              '${l10n.tOr('userHistorySource', 'Source')}: '
                  '${item.dataString('source')}',
          ],
        );
      case UserHistoryTypes.profileVisitReceived:
        return _HistoryPresentation(
          icon: Icons.login_outlined,
          color: theme.colorScheme.secondary,
          title: l10n.tOr('userHistoryProfileVisitor', 'Profile Visitor'),
          lines: [
            if (_username(item, 'viewer') != null)
              '${l10n.tOr('username', 'Username')}: ${_username(item, 'viewer')}',
            if (item.dataNum('visitCount') != null)
              '${l10n.tOr('userHistoryVisitCount', 'Visit Count')}: '
                  '${item.dataNum('visitCount')}',
          ],
        );
      case UserHistoryTypes.createPost:
        return _HistoryPresentation(
          icon: Icons.videocam_outlined,
          color: theme.colorScheme.primary,
          title: l10n.tOr('userHistoryCreatedPost', 'Created Post'),
          lines: [
            if (_postDescription(item) != null) _postDescription(item)!,
          ],
          thumbnailUrl: _postThumbnail(item),
        );
      case UserHistoryTypes.likePost:
        return _HistoryPresentation(
          icon: Icons.favorite_border,
          color: theme.colorScheme.error,
          title: l10n.tOr('userHistoryLikedPost', 'Liked Post'),
          lines: [
            if (_postDescription(item) != null) _postDescription(item)!,
          ],
          thumbnailUrl: _postThumbnail(item),
        );
      case UserHistoryTypes.comment:
        return _HistoryPresentation(
          icon: Icons.chat_bubble_outline,
          color: theme.colorScheme.secondary,
          title: l10n.tOr('userHistoryCommented', 'Commented'),
          lines: [
            if (item.dataString('content') != null ||
                item.dataString('comment') != null)
              '${l10n.tOr('userHistoryComment', 'Comment')}: '
                  '${item.dataString('content') ?? item.dataString('comment')}',
            if (_postDescription(item) != null)
              '${l10n.tOr('userHistoryRelatedPost', 'Related Post')}: '
                  '${_postDescription(item)}',
          ],
        );
      case UserHistoryTypes.repost:
        return _HistoryPresentation(
          icon: Icons.repeat_rounded,
          color: theme.colorScheme.tertiary,
          title: l10n.tOr('userHistoryReposted', 'Reposted'),
          lines: [
            if (_postDescription(item) != null)
              '${l10n.tOr('userHistoryRelatedPost', 'Related Post')}: '
                  '${_postDescription(item)}',
          ],
          thumbnailUrl: _postThumbnail(item),
        );
      case UserHistoryTypes.sendGift:
        return _HistoryPresentation(
          icon: Icons.card_giftcard,
          color: theme.colorScheme.tertiary,
          title: l10n.tOr('userHistoryGiftSent', 'Gift Sent'),
          lines: [
            if (_giftName(item) != null)
              '${l10n.tOr('gift', 'Gift')}: ${_giftName(item)}',
            if (_username(item, 'receiver') != null ||
                item.dataString('receiverUsername') != null)
              '${l10n.tOr('userHistoryReceiver', 'Receiver')}: '
                  '${_username(item, 'receiver') ?? item.dataString('receiverUsername')}',
            if (_coins(item) != null)
              '${l10n.tOr('userHistoryCoins', 'Coins')}: ${_coins(item)}',
          ],
        );
      case UserHistoryTypes.postView:
        final sourceKey = item.dataString('trafficSource');
        final sourceLabel = sourceKey != null
            ? ReportDetailLabels.trafficSourceLabel(l10n, sourceKey)
            : null;
        final watchTime =
            item.dataNum('watchedDuration') ?? item.dataNum('watchTime');
        return _HistoryPresentation(
          icon: Icons.visibility_outlined,
          color: theme.colorScheme.primary,
          title: l10n.tOr('userHistoryViewedPost', 'Viewed Post'),
          lines: [
            if (_postDescription(item) != null) _postDescription(item)!,
            if (sourceLabel != null)
              '${l10n.tOr('trafficSource', 'Traffic Source')}: $sourceLabel',
            if (watchTime != null && watchTime > 0)
              '${l10n.tOr('watchTime', 'Watch Time')}: ${watchTime.toInt()}s',
          ],
          thumbnailUrl: _postThumbnail(item),
        );
      case UserHistoryTypes.save:
        return _HistoryPresentation(
          icon: Icons.bookmark_border_rounded,
          color: theme.colorScheme.secondary,
          title: l10n.tOr('userHistorySavedPost', 'Saved Post'),
          lines: [
            if (_postDescription(item) != null) _postDescription(item)!,
          ],
          thumbnailUrl: _postThumbnail(item),
        );
      case UserHistoryTypes.storyView:
        return _HistoryPresentation(
          icon: Icons.auto_stories_outlined,
          color: theme.colorScheme.tertiary,
          title: l10n.tOr('userHistoryViewedStory', 'Viewed Story'),
          lines: [
            if (_storyOwner(item) != null)
              '${l10n.tOr('userHistoryStoryOwner', 'Story Owner')}: '
                  '${_storyOwner(item)}',
          ],
        );
      case UserHistoryTypes.search:
        return _HistoryPresentation(
          icon: Icons.search_rounded,
          color: theme.colorScheme.primary,
          title: l10n.tOr('userHistorySearchKeyword', 'Search Keyword'),
          lines: [
            if (item.dataString('query') != null ||
                item.dataString('keyword') != null)
              item.dataString('query') ?? item.dataString('keyword')!,
          ],
        );
      case UserHistoryTypes.location:
        return _HistoryPresentation(
          icon: Icons.location_on_outlined,
          color: theme.colorScheme.error,
          title: l10n.tOr('userHistoryLocation', 'Location'),
          lines: [
            if (item.dataNum('latitude') != null ||
                item.dataString('latitude') != null)
              '${l10n.tOr('userHistoryLatitude', 'Latitude')}: '
                  '${item.dataNum('latitude') ?? item.dataString('latitude')}',
            if (item.dataNum('longitude') != null ||
                item.dataString('longitude') != null)
              '${l10n.tOr('userHistoryLongitude', 'Longitude')}: '
                  '${item.dataNum('longitude') ?? item.dataString('longitude')}',
            if (item.dataString('city') != null)
              '${l10n.tOr('userHistoryCity', 'City')}: '
                  '${item.dataString('city')}',
            if (item.dataString('country') != null)
              '${l10n.tOr('userHistoryCountry', 'Country')}: '
                  '${item.dataString('country')}',
          ],
        );
      default:
        return _HistoryPresentation(
          icon: Icons.timeline,
          color: theme.colorScheme.outline,
          title: item.type,
          lines: const [],
        );
    }
  }

  static String? _metaPath(UserHistoryEntity item) {
    final meta = item.dataMap('meta');
    final path = meta?['path']?.toString().trim();
    if (path != null && path.isNotEmpty) return path;
    return item.dataString('path');
  }

  static String? _username(UserHistoryEntity item, String mapKey) {
    return item.nestedString(mapKey, 'username') ??
        item.nestedString(mapKey, 'fullName');
  }

  static String? _postDescription(UserHistoryEntity item) {
    return item.nestedString('post', 'description') ??
        item.dataString('description') ??
        item.dataString('postDescription');
  }

  static String? _postThumbnail(UserHistoryEntity item) {
    final raw = item.nestedString('post', 'thumbnailUrl') ??
        item.dataString('thumbnailUrl');
    return resolveMediaUrl(raw);
  }

  static String? _giftName(UserHistoryEntity item) {
    return item.nestedString('gift', 'name') ??
        item.dataString('giftName') ??
        item.dataString('gift');
  }

  static String? _coins(UserHistoryEntity item) {
    final value = item.dataNum('coins') ??
        item.dataNum('priceCoins') ??
        item.nestedString('gift', 'priceCoins');
    return value?.toString();
  }

  static String? _storyOwner(UserHistoryEntity item) {
    return item.nestedString('owner', 'username') ??
        item.nestedString('story', 'username') ??
        item.nestedString('user', 'username') ??
        item.dataString('ownerUsername');
  }
}

class _HistoryPresentation {
  const _HistoryPresentation({
    required this.icon,
    required this.color,
    required this.title,
    required this.lines,
    this.thumbnailUrl,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> lines;
  final String? thumbnailUrl;
}
