enum ActivityType {
  comment,
  like,
  mention,
  post,
  activityFeed,
  auction,
  gift,
  device,
  unknown,
}

/// Context for why an admin opened [PostManagementDetailScreen].
class ActivityContext {
  const ActivityContext({
    required this.type,
    this.commentId,
    this.commentText,
    this.commentUserId,
    this.commentUsername,
    this.activityDate,
    this.mentionText,
    this.likeId,
    this.postOwnerName,
    this.mentionSource,
    this.mentionedUserNames = const [],
  });

  final ActivityType type;
  final String? commentId;
  final String? commentText;
  final String? commentUserId;
  final String? commentUsername;
  final DateTime? activityDate;
  final String? mentionText;
  final String? likeId;
  final String? postOwnerName;
  final String? mentionSource;
  final List<String> mentionedUserNames;

  bool get fromComments => type == ActivityType.comment;
  bool get fromLikes => type == ActivityType.like;
  bool get fromMentions => type == ActivityType.mention;

  String? get highlightCommentId => commentId;

  static ActivityContext comment({
    required String commentId,
    required String commentText,
    required DateTime activityDate,
    String? postOwnerName,
    String? commentUserId,
    String? commentUsername,
  }) =>
      ActivityContext(
        type: ActivityType.comment,
        commentId: commentId,
        commentText: commentText,
        commentUserId: commentUserId,
        commentUsername: commentUsername,
        activityDate: activityDate,
        postOwnerName: postOwnerName,
      );

  static ActivityContext like({
    required String likeId,
    required DateTime activityDate,
  }) =>
      ActivityContext(
        type: ActivityType.like,
        likeId: likeId,
        activityDate: activityDate,
      );

  static ActivityContext mention({
    required DateTime activityDate,
    String? mentionText,
    String? mentionSource,
    List<String> mentionedUserNames = const [],
    String? postOwnerName,
    String? commentId,
    String? commentText,
  }) =>
      ActivityContext(
        type: ActivityType.mention,
        activityDate: activityDate,
        mentionText: mentionText,
        mentionSource: mentionSource,
        mentionedUserNames: mentionedUserNames,
        postOwnerName: postOwnerName,
        commentId: commentId,
        commentText: commentText,
      );

  static ActivityContext post({DateTime? activityDate}) => ActivityContext(
        type: ActivityType.post,
        activityDate: activityDate,
      );

  static ActivityContext feed({DateTime? activityDate, String? label}) =>
      ActivityContext(
        type: ActivityType.activityFeed,
        activityDate: activityDate,
        mentionText: label,
      );

  /// Deep-link query: `activity=mention|comment|like|post`
  static ActivityType? typeFromQuery(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'comment':
      case 'comments':
        return ActivityType.comment;
      case 'like':
      case 'likes':
        return ActivityType.like;
      case 'mention':
      case 'mentions':
        return ActivityType.mention;
      case 'post':
      case 'posts':
        return ActivityType.post;
      default:
        return ActivityType.unknown;
    }
  }
}
