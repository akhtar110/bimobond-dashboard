import 'package:flutter/material.dart';

import '../../../post_management/domain/entities/activity_context.dart';
import '../../../post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/presentation/utils/post_management_navigation.dart';
import '../../../users/domain/entities/user_entity.dart';

/// Opens post moderation with optional investigation context from user activity.
Future<void> openPostInvestigation(
  BuildContext context, {
  required String postId,
  UserEntity? sourceUser,
  ActivityContext? activityContext,
  ManagedPostEntity? post,
}) async {
  if (postId.isEmpty) return;

  await navigateToPostManagementDetail(
    context,
    post: post != null && post.id.isNotEmpty
        ? post
        : managedPostSeed(postId, author: sourceUser),
    sourceUser: sourceUser,
    activityContext: activityContext,
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
