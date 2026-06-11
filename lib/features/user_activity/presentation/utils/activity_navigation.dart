import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../../post_management/domain/entities/post_management_route_args.dart';
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

  final resolved = post != null
      ? post
      : managedPostSeed(
          postId,
          author: sourceUser,
        );

  final args = PostManagementRouteArgs(
    post: resolved,
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
