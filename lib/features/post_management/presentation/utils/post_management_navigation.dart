import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/activity_context.dart';
import '../../domain/entities/managed_post_author_enrichment.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_management_nav_result.dart';
import '../../domain/entities/post_management_route_args.dart';
import '../../../users/domain/entities/user_entity.dart';

/// Canonical admin navigation into [PostManagementDetailScreen].
///
/// Always normalizes media/author fields the same way as [PostsPage].
Future<Object?> navigateToPostManagementDetail(
  BuildContext context, {
  required ManagedPostEntity post,
  UserEntity? sourceUser,
  ActivityContext? activityContext,
}) {
  final prepared = prepareManagedPostForDetailNavigation(
    post,
    sourceUser: sourceUser,
  );

  final Object arguments = sourceUser != null || activityContext != null
      ? PostManagementRouteArgs(
          post: prepared,
          sourceUser: sourceUser,
          activityContext: activityContext,
        )
      : prepared;

  return Navigator.pushNamed(
    context,
    AppRoutes.postManagementDetail,
    arguments: arguments,
  );
}

/// Posts list helper: patches the feed row when detail returns an update.
Future<void> navigateToPostManagementFromFeed(
  BuildContext context, {
  required ManagedPostEntity post,
  required void Function(PostManagementNavResult result, ManagedPostEntity listBaseline) onResult,
}) async {
  final listBaseline = snapshotPostListBaseline(post);
  final result = await navigateToPostManagementDetail(context, post: post);
  if (!context.mounted || result == null) return;

  if (result is PostManagementNavResult) {
    onResult(result, listBaseline);
  } else if (result == true) {
    onResult(const PostManagementNavResult.deleted(), listBaseline);
  }
}
