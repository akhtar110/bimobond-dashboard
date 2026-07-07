enum NotificationType {
  adminMessage,
  broadcast,
  system,
  // Future types
  newFollower,
  followRequest,
  followRequestAccepted,
  postLike,
  postComment,
  commentReply,
  commentLike,
  mention,
  repost,
  giftReceived,
  auctionUpdate,
  auctionWon,
}

extension NotificationTypeX on NotificationType {
  String get value => switch (this) {
        NotificationType.adminMessage => 'ADMIN_MESSAGE',
        NotificationType.broadcast => 'BROADCAST',
        NotificationType.system => 'SYSTEM',
        NotificationType.newFollower => 'NEW_FOLLOWER',
        NotificationType.followRequest => 'FOLLOW_REQUEST',
        NotificationType.followRequestAccepted => 'FOLLOW_REQUEST_ACCEPTED',
        NotificationType.postLike => 'POST_LIKE',
        NotificationType.postComment => 'POST_COMMENT',
        NotificationType.commentReply => 'COMMENT_REPLY',
        NotificationType.commentLike => 'COMMENT_LIKE',
        NotificationType.mention => 'MENTION',
        NotificationType.repost => 'REPOST',
        NotificationType.giftReceived => 'GIFT_RECEIVED',
        NotificationType.auctionUpdate => 'AUCTION_UPDATE',
        NotificationType.auctionWon => 'AUCTION_WON',
      };

  String get displayName => switch (this) {
        NotificationType.adminMessage => 'Admin Message',
        NotificationType.broadcast => 'Broadcast',
        NotificationType.system => 'System',
        NotificationType.newFollower => 'New Follower',
        NotificationType.followRequest => 'Follow Request',
        NotificationType.followRequestAccepted => 'Follow Request Accepted',
        NotificationType.postLike => 'Post Like',
        NotificationType.postComment => 'Post Comment',
        NotificationType.commentReply => 'Comment Reply',
        NotificationType.commentLike => 'Comment Like',
        NotificationType.mention => 'Mention',
        NotificationType.repost => 'Repost',
        NotificationType.giftReceived => 'Gift Received',
        NotificationType.auctionUpdate => 'Auction Update',
        NotificationType.auctionWon => 'Auction Won',
      };

  static NotificationType fromString(String s) => switch (s.toUpperCase()) {
        'ADMIN_MESSAGE' => NotificationType.adminMessage,
        'BROADCAST' => NotificationType.broadcast,
        'SYSTEM' => NotificationType.system,
        'NEW_FOLLOWER' => NotificationType.newFollower,
        'FOLLOW_REQUEST' => NotificationType.followRequest,
        'FOLLOW_REQUEST_ACCEPTED' => NotificationType.followRequestAccepted,
        'POST_LIKE' => NotificationType.postLike,
        'POST_COMMENT' => NotificationType.postComment,
        'COMMENT_REPLY' => NotificationType.commentReply,
        'COMMENT_LIKE' => NotificationType.commentLike,
        'MENTION' => NotificationType.mention,
        'REPOST' => NotificationType.repost,
        'GIFT_RECEIVED' => NotificationType.giftReceived,
        'AUCTION_UPDATE' => NotificationType.auctionUpdate,
        'AUCTION_WON' => NotificationType.auctionWon,
        _ => NotificationType.adminMessage,
      };

  static const adminTypes = [
    NotificationType.adminMessage,
    NotificationType.broadcast,
    NotificationType.system,
  ];
}
