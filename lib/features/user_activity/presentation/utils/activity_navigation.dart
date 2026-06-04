import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/domain/entities/post_management_route_args.dart';
import '../../../users/domain/entities/user_entity.dart';

/// Minimal post entity for navigation — detail screen loads full data by id.
ManagedPostEntity managedPostStubForNavigation(String postId) {
  final now = DateTime.now();
  return ManagedPostEntity(
    id: postId,
    userId: '',
    type: 'VIDEO',
    status: 'PUBLISHED',
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
}

/// Opens post moderation with optional investigation context from user activity.
Future<void> openPostInvestigation(
  BuildContext context, {
  required String postId,
  UserEntity? sourceUser,
  ActivityContext? activityContext,
  ManagedPostEntity? post,
}) async {
  if (postId.isEmpty) return;
  final args = PostManagementRouteArgs(
    post: post ?? managedPostStubForNavigation(postId),
    sourceUser: sourceUser,
    activityContext: activityContext,
  );
  await Navigator.pushNamed(
    context,
    AppRoutes.postManagementDetail,
    arguments: args,
  );
}

Future<void> openPostManagementById(
  BuildContext context,
  String postId, {
  UserEntity? sourceUser,
  ActivityContext? activityContext,
}) =>
    openPostInvestigation(
      context,
      postId: postId,
      sourceUser: sourceUser,
      activityContext: activityContext,
    );
