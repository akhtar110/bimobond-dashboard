import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';

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

Future<void> openPostManagementById(
  BuildContext context,
  String postId,
) async {
  if (postId.isEmpty) return;
  await Navigator.pushNamed(
    context,
    AppRoutes.postManagementDetail,
    arguments: managedPostStubForNavigation(postId),
  );
}
