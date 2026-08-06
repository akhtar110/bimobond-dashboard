import '../entities/user_history_entity.dart';

/// Normalizes timeline / audit-log type strings to [UserHistoryTypes] constants.
String normalizeUserHistoryType(String rawType) {
  final upper = rawType.trim().toUpperCase();
  if (upper.isEmpty) return upper;

  if (upper == UserHistoryTypes.likePost ||
      upper == 'LIKE' ||
      upper == 'POST_LIKE' ||
      upper == 'POST_UNLIKE') {
    return UserHistoryTypes.likePost;
  }
  if (upper == UserHistoryTypes.comment ||
      upper == 'POST_COMMENT' ||
      upper == 'CREATE_COMMENT' ||
      upper == 'COMMENT_CREATE' ||
      upper == 'COMMENT_DELETE') {
    return UserHistoryTypes.comment;
  }
  if (upper == UserHistoryTypes.repost ||
      upper == 'POST_REPOST' ||
      upper == 'POST_UNREPOST') {
    return UserHistoryTypes.repost;
  }
  if (upper == UserHistoryTypes.share || upper == 'POST_SHARE') {
    return UserHistoryTypes.share;
  }
  if (upper == UserHistoryTypes.sendGift ||
      upper == 'GIFT' ||
      upper == 'GIFT_SENT' ||
      upper == 'GIFT_SEND') {
    return UserHistoryTypes.sendGift;
  }
  if (upper == UserHistoryTypes.storyView ||
      upper == 'VIEW_STORY' ||
      upper == 'STORY_VIEW' ||
      upper == 'STORY_CREATE') {
    return UserHistoryTypes.storyView;
  }
  if (upper == UserHistoryTypes.search || upper == 'SEARCH_QUERY') {
    return UserHistoryTypes.search;
  }
  if (upper == UserHistoryTypes.location ||
      upper == 'LOCATION_UPDATE' ||
      upper == 'GEO') {
    return UserHistoryTypes.location;
  }
  if (upper == UserHistoryTypes.save ||
      upper == 'POST_SAVE' ||
      upper == 'POST_UNSAVE' ||
      upper == 'BOOKMARK') {
    return UserHistoryTypes.save;
  }
  if (upper == UserHistoryTypes.createPost ||
      upper == 'POST_CREATE' ||
      upper == 'POST_DELETE' ||
      upper == 'PUBLISH') {
    return UserHistoryTypes.createPost;
  }
  if (upper == UserHistoryTypes.postView ||
      upper == 'VIEW_POST' ||
      upper == 'WATCH_POST') {
    return UserHistoryTypes.postView;
  }
  if (upper == UserHistoryTypes.screenView ||
      upper == 'PAGE_VIEW' ||
      upper == 'VIEW_PAGE') {
    return UserHistoryTypes.screenView;
  }
  if (upper == UserHistoryTypes.profileVisitGiven ||
      upper == 'VISITED_PROFILE') {
    return UserHistoryTypes.profileVisitGiven;
  }
  if (upper == UserHistoryTypes.profileVisitReceived ||
      upper == 'PROFILE_VISITOR') {
    return UserHistoryTypes.profileVisitReceived;
  }
  if (upper == UserHistoryTypes.profileView ||
      upper == 'VIEW_PROFILE' ||
      upper == 'PROFILE_VIEW') {
    return UserHistoryTypes.profileView;
  }
  if (upper == UserHistoryTypes.authLogin ||
      upper == 'AUTH_LOGIN' ||
      upper == 'LOGIN') {
    return UserHistoryTypes.authLogin;
  }
  if (upper == UserHistoryTypes.authLogout ||
      upper == 'AUTH_LOGOUT' ||
      upper == 'LOGOUT') {
    return UserHistoryTypes.authLogout;
  }

  if (upper.contains('STORY')) return UserHistoryTypes.storyView;
  if (upper.contains('COMMENT')) return UserHistoryTypes.comment;
  if (upper.contains('LIKE')) return UserHistoryTypes.likePost;
  if (upper.contains('REPOST')) return UserHistoryTypes.repost;
  if (upper.contains('SHARE')) return UserHistoryTypes.share;
  if (upper.contains('GIFT')) return UserHistoryTypes.sendGift;
  if (upper.contains('SEARCH')) return UserHistoryTypes.search;
  if (upper.contains('LOCATION') || upper.contains('GEO')) {
    return UserHistoryTypes.location;
  }
  if (upper.contains('SAVE') || upper.contains('BOOKMARK')) {
    return UserHistoryTypes.save;
  }
  if (upper.contains('CREATE_POST') ||
      upper.contains('POST_CREATE') ||
      upper.contains('PUBLISH')) {
    return UserHistoryTypes.createPost;
  }
  if (upper.contains('POST_VIEW') ||
      upper.contains('VIEW_POST') ||
      upper.contains('WATCH')) {
    return UserHistoryTypes.postView;
  }
  if (upper.contains('SCREEN') ||
      upper.contains('PAGE') ||
      upper.contains('NAVIGATE')) {
    return UserHistoryTypes.screenView;
  }
  if (upper.contains('PROFILE')) return UserHistoryTypes.profileView;
  if (upper.contains('LOGIN') ||
      upper.contains('LOGOUT') ||
      upper.contains('AUTH')) {
    return upper.contains('LOGOUT')
        ? UserHistoryTypes.authLogout
        : UserHistoryTypes.authLogin;
  }

  return upper;
}

bool userHistoryTypeMatchesFilter(String itemType, String filterType) {
  return normalizeUserHistoryType(itemType) ==
      normalizeUserHistoryType(filterType);
}

bool isStoryNavigableUserHistoryType(String type) {
  return normalizeUserHistoryType(type) == UserHistoryTypes.storyView;
}

bool isPostNavigableUserHistoryType(String type) {
  final normalized = normalizeUserHistoryType(type);
  switch (normalized) {
    case UserHistoryTypes.postView:
    case UserHistoryTypes.likePost:
    case UserHistoryTypes.comment:
    case UserHistoryTypes.createPost:
    case UserHistoryTypes.sendGift:
    case UserHistoryTypes.repost:
    case UserHistoryTypes.save:
    case UserHistoryTypes.share:
      return true;
    default:
      break;
  }

  final upper = type.trim().toUpperCase();
  return upper.contains('POST') ||
      upper.contains('LIKE') ||
      upper.contains('COMMENT') ||
      upper.contains('REPOST') ||
      upper.contains('SHARE') ||
      upper.contains('SAVE') ||
      upper.contains('GIFT');
}

/// Maps a single UI filter chip to user-history audit log query params.
({String category, String action})? userHistoryAuditFilterForType(
  String filterType,
) {
  switch (normalizeUserHistoryType(filterType)) {
    case UserHistoryTypes.likePost:
      return (category: 'CONTENT', action: 'POST_LIKE');
    case UserHistoryTypes.comment:
      return (category: 'CONTENT', action: 'COMMENT_CREATE');
    case UserHistoryTypes.createPost:
      return (category: 'CONTENT', action: 'POST_CREATE');
    case UserHistoryTypes.repost:
      return (category: 'CONTENT', action: 'POST_REPOST');
    case UserHistoryTypes.share:
      return (category: 'CONTENT', action: 'POST_SHARE');
    case UserHistoryTypes.save:
      return (category: 'CONTENT', action: 'POST_SAVE');
    case UserHistoryTypes.sendGift:
      return (category: 'COMMERCE', action: 'GIFT_SEND');
    case UserHistoryTypes.storyView:
      return (category: 'CONTENT', action: 'STORY_CREATE');
    case UserHistoryTypes.search:
      return (category: 'NAVIGATION', action: 'SEARCH');
    case UserHistoryTypes.location:
      return (category: 'SETTINGS', action: 'LOCATION_UPDATE');
    case UserHistoryTypes.profileView:
    case UserHistoryTypes.profileVisitGiven:
    case UserHistoryTypes.profileVisitReceived:
      return (category: 'NAVIGATION', action: 'PROFILE_VIEW');
    case UserHistoryTypes.screenView:
      return (category: 'NAVIGATION', action: 'SCREEN_VIEW');
    case UserHistoryTypes.postView:
      return null;
    default:
      return null;
  }
}

bool userHistoryQueryPrefersTimeline(UserHistoryQuery query) {
  return query.types.isNotEmpty;
}
