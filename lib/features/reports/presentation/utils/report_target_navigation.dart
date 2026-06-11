import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../post_management/domain/entities/post_management_route_args.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/report_entity.dart';

/// Navigates from a moderation report to the admin target screen.
abstract final class ReportTargetNavigation {
  ReportTargetNavigation._();

  static bool canOpen(ReportEntity report) =>
      report.postAuthorUserId != null ||
      report.reportedUserId != null ||
      report.postId != null ||
      report.commentId != null ||
      report.post?.id != null;

  static void open(BuildContext context, ReportEntity report) {
    final postId = _resolvePostId(report);
    if (postId != null && postId.isNotEmpty) {
      _openPost(context, report, postId);
      return;
    }

    if (report.reportedUserId != null) {
      _openUser(context, report);
      return;
    }

    _showError(context, 'No target is linked to this report.');
  }

  static String? _resolvePostId(ReportEntity report) {
    if (report.postId != null && report.postId!.isNotEmpty) {
      return report.postId;
    }
    if (report.post?.id != null && report.post!.id.isNotEmpty) {
      return report.post!.id;
    }
    return null;
  }

  static ManagedPostAuthorSnapshot? _postAuthorSnapshot(ReportEntity report) {
    final actor = report.postAuthor;
    final userId = report.postAuthorUserId;
    if (userId == null || userId.isEmpty) return null;

    return ManagedPostAuthorSnapshot(
      userId: userId,
      userName: actor?.username,
      userFullName: actor?.fullName,
      userProfileImage: actor?.avatarUrl,
    );
  }

  static UserEntity? _postAuthorUser(ReportEntity report) {
    final userId = report.postAuthorUserId;
    if (userId == null || userId.isEmpty) return null;

    final actor = report.postAuthor;
    return UserEntity(
      id: userId,
      username: actor?.username ?? userId,
      fullName: actor?.fullName,
      avatarUrl: actor?.avatarUrl,
      isVerified: false,
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
      roles: const [UserRole.user],
    );
  }

  static void _openUser(BuildContext context, ReportEntity report) {
    final userId = report.reportedUserId!;
    final actor = report.reportedUser;
    final user = UserEntity(
      id: userId,
      username: actor?.username ?? userId,
      fullName: actor?.fullName,
      avatarUrl: actor?.avatarUrl,
      isVerified: false,
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
      roles: const [UserRole.user],
    );

    Navigator.pushNamed(
      context,
      AppRoutes.userDetail,
      arguments: user,
    );
  }

  static void _openPost(
    BuildContext context,
    ReportEntity report,
    String postId,
  ) {
    final now = DateTime.now();
    final authorUser = _postAuthorUser(report);
    final authorSnapshot = _postAuthorSnapshot(report);
    final stubPost = managedPostSeed(
      postId,
      author: authorUser,
      authorSnapshot: authorSnapshot,
    );
    final activityCtx = report.commentId != null
        ? ActivityContext(
            type: ActivityType.comment,
            commentId: report.commentId,
            activityDate: now,
          )
        : null;

    Navigator.pushNamed(
      context,
      AppRoutes.postManagementDetail,
      arguments: PostManagementRouteArgs(
        post: stubPost,
        activityContext: activityCtx,
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
