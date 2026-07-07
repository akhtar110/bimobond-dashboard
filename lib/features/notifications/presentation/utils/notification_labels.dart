import '../../../../core/localization/localization.dart';
import '../../domain/entities/notification_type.dart';

/// Localized label for feed filter type codes (e.g. POST_LIKE).
String notificationFeedTypeLabel(AppLocalizations l10n, String type) {
  return switch (type.toUpperCase()) {
    'ALL' => l10n.t('allTypes'),
    'POST_LIKE' => l10n.t('notificationTypePostLike'),
    'COMMENT' => l10n.t('notificationTypeComment'),
    'COMMENT_LIKE' => l10n.t('notificationTypeCommentLike'),
    'FOLLOW' => l10n.t('notificationTypeFollow'),
    'MENTION' => l10n.t('notificationTypeMention'),
    'REPOST' => l10n.t('notificationTypeRepost'),
    'ADMIN_MESSAGE' => l10n.t('notificationTypeAdminMessage'),
    'BROADCAST' => l10n.t('notificationTypeBroadcast'),
    'SYSTEM' => l10n.t('notificationTypeSystem'),
    _ => type
        .split('_')
        .map((w) => w.isEmpty ? '' : w[0] + w.substring(1).toLowerCase())
        .join(' '),
  };
}

String notificationReadFilterLabel(AppLocalizations l10n, String filter) {
  return switch (filter.toUpperCase()) {
    'ALL' => l10n.t('all'),
    'READ' => l10n.t('filterRead'),
    'UNREAD' => l10n.t('filterUnread'),
    _ => filter,
  };
}

String notificationComposerTypeLabel(
  AppLocalizations l10n,
  NotificationType type,
) {
  return switch (type) {
    NotificationType.adminMessage => l10n.t('notificationTypeAdminMessage'),
    NotificationType.broadcast => l10n.t('notificationTypeBroadcast'),
    NotificationType.system => l10n.t('notificationTypeSystem'),
    NotificationType.newFollower => l10n.t('notificationTypeNewFollower'),
    NotificationType.followRequest => l10n.t('notificationTypeFollowRequest'),
    NotificationType.followRequestAccepted =>
      l10n.t('notificationTypeFollowRequestAccepted'),
    NotificationType.postLike => l10n.t('notificationTypePostLike'),
    NotificationType.postComment => l10n.t('notificationTypePostComment'),
    NotificationType.commentReply => l10n.t('notificationTypeCommentReply'),
    NotificationType.commentLike => l10n.t('notificationTypeCommentLike'),
    NotificationType.mention => l10n.t('notificationTypeMention'),
    NotificationType.repost => l10n.t('notificationTypeRepost'),
    NotificationType.giftReceived => l10n.t('notificationTypeGiftReceived'),
    NotificationType.auctionUpdate => l10n.t('notificationTypeAuctionUpdate'),
    NotificationType.auctionWon => l10n.t('notificationTypeAuctionWon'),
  };
}

String notificationActionText(AppLocalizations l10n, String type, {String? message}) {
  if (message != null && message.trim().isNotEmpty) return message;
  return switch (type.toUpperCase()) {
    'POST_LIKE' => l10n.t('notificationActionPostLike'),
    'COMMENT' => l10n.t('notificationActionComment'),
    'COMMENT_LIKE' => l10n.t('notificationActionCommentLike'),
    'FOLLOW' => l10n.t('notificationActionFollow'),
    'MENTION' => l10n.t('notificationActionMention'),
    'REPOST' => l10n.t('notificationActionRepost'),
    'ADMIN_MESSAGE' => l10n.t('notificationActionAdminMessage'),
    'BROADCAST' => l10n.t('notificationActionBroadcast'),
    'SYSTEM' => l10n.t('notificationActionSystem'),
    _ => type.toLowerCase().replaceAll('_', ' '),
  };
}

String notificationRelativeTime(AppLocalizations l10n, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.t('notificationJustNow');
  if (diff.inMinutes < 60) {
    return l10n.tArgs('notificationMinutesAgo', {'count': '${diff.inMinutes}'});
  }
  if (diff.inHours < 24) {
    return l10n.tArgs('notificationHoursAgo', {'count': '${diff.inHours}'});
  }
  if (diff.inDays < 7) {
    return l10n.tArgs('notificationDaysAgo', {'count': '${diff.inDays}'});
  }
  return '${dt.day}/${dt.month}/${dt.year}';
}

String notificationCountLabel(AppLocalizations l10n, int total) {
  if (total == 1) {
    return l10n.tArgs('notificationCountSummaryOne', {'count': '$total'});
  }
  return l10n.tArgs('notificationCountSummary', {'count': '$total'});
}
