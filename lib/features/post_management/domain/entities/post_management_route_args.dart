import '../../../users/domain/entities/user_entity.dart';
import 'activity_context.dart';
import 'managed_post_entity.dart';

/// Navigation bundle for post moderation / investigation.
class PostManagementRouteArgs {
  const PostManagementRouteArgs({
    required this.post,
    this.sourceUser,
    this.activityContext,
  });

  final ManagedPostEntity post;
  final UserEntity? sourceUser;
  final ActivityContext? activityContext;

  bool get isInvestigation =>
      sourceUser != null || activityContext != null;

  /// Accepts [PostManagementRouteArgs], [ManagedPostEntity], or deep-link [Map].
  static PostManagementRouteArgs resolve(Object? arguments) {
    if (arguments is PostManagementRouteArgs) return arguments;
    if (arguments is ManagedPostEntity) {
      return PostManagementRouteArgs(post: arguments);
    }
    if (arguments is Map) {
      return fromMap(arguments);
    }
    throw ArgumentError(
      'Post management route expects PostManagementRouteArgs or ManagedPostEntity',
    );
  }

  /// Map keys: `postId`, `userId`, `commentId`, `activity`, optional stub post fields.
  static PostManagementRouteArgs fromMap(Map<dynamic, dynamic> map) {
    final postId = map['postId']?.toString() ?? map['id']?.toString() ?? '';
    final now = DateTime.now();
    final post = ManagedPostEntity(
      id: postId,
      userId: map['postUserId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'VIDEO',
      status: map['status']?.toString() ?? 'PUBLISHED',
      viewCount: 0,
      shareCount: 0,
      downloadCount: 0,
      likeCount: 0,
      commentCount: 0,
      saveCount: 0,
      isAd: false,
      privacyStatus: 'PUBLIC',
      allowComments: true,
      allowDuets: true,
      allowStitch: true,
      isStory: false,
      isAuctionable: false,
      createdAt: now,
      updatedAt: now,
    );

    final activityType = ActivityContext.typeFromQuery(
      map['activity']?.toString(),
    );
    ActivityContext? activityContext;
    final commentId = map['commentId']?.toString();
    if (activityType == ActivityType.comment && commentId != null) {
      activityContext = ActivityContext(
        type: ActivityType.comment,
        commentId: commentId,
        activityDate: now,
      );
    } else if (activityType == ActivityType.like) {
      activityContext = ActivityContext.like(likeId: '', activityDate: now);
    } else if (activityType == ActivityType.mention) {
      activityContext = ActivityContext.mention(activityDate: now);
    } else if (activityType == ActivityType.post) {
      activityContext = ActivityContext.post();
    }

    return PostManagementRouteArgs(
      post: post,
      activityContext: activityContext,
    );
  }

  /// Parses paths like `posts/{postId}` with query `user`, `comment`, `activity`.
  static PostManagementRouteArgs? tryParseRouteName(String? name) {
    if (name == null || name.isEmpty) return null;
    final uri = Uri.tryParse(name.startsWith('/') ? name : '/$name');
    if (uri == null) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    if (segments.first == 'posts' && segments.length >= 2) {
      return fromMap({
        'postId': segments[1],
        if (uri.queryParameters['user'] != null)
          'userId': uri.queryParameters['user'],
        if (uri.queryParameters['comment'] != null)
          'commentId': uri.queryParameters['comment'],
        if (uri.queryParameters['activity'] != null)
          'activity': uri.queryParameters['activity'],
      });
    }
    return null;
  }
}
