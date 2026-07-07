import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/utils/post_status_utils.dart';

/// All post statuses admins can set via [UpdatePostStatusEvent].
const kPostAdminStatuses = [
  'PUBLISHED',
  'DRAFT',
  'HIDDEN',
  'BANNED',
  'UNDER_REVIEW',
  'ARCHIVED',
];

String postStatusLabel(AppLocalizations l10n, String status) {
  switch (normalizePostStatus(status)) {
    case 'PUBLISHED':
      return l10n.t('postStatusPublished');
    case 'BANNED':
      return l10n.t('postStatusBanned');
    case 'DRAFT':
      return l10n.t('postStatusDraft');
    case 'HIDDEN':
      return l10n.t('postStatusHidden');
    case 'UNDER_REVIEW':
      return l10n.t('postStatusUnderReview');
    case 'ARCHIVED':
      return l10n.t('archived');
    default:
      return status;
  }
}

IconData postStatusIcon(String status) {
  switch (normalizePostStatus(status)) {
    case 'PUBLISHED':
      return Icons.check_circle_outline_rounded;
    case 'DRAFT':
      return Icons.edit_note_outlined;
    case 'HIDDEN':
      return Icons.visibility_off_outlined;
    case 'BANNED':
      return Icons.block_outlined;
    case 'UNDER_REVIEW':
      return Icons.rate_review_outlined;
    case 'ARCHIVED':
      return Icons.inventory_2_outlined;
    default:
      return Icons.flag_outlined;
  }
}

Color postStatusColor(String status, [ColorScheme? scheme]) =>
    postStatusColorFromScheme(scheme ?? const ColorScheme.light(), status);

Color postStatusColorFromScheme(ColorScheme scheme, String status) {
  switch (normalizePostStatus(status)) {
    case 'PUBLISHED':
      return scheme.tertiary;
    case 'DRAFT':
      return scheme.primary;
    case 'HIDDEN':
      return scheme.secondary;
    case 'BANNED':
      return scheme.error;
    case 'UNDER_REVIEW':
      return scheme.primary;
    case 'ARCHIVED':
      return scheme.outline;
    default:
      return scheme.onSurfaceVariant;
  }
}

String privacyLabel(AppLocalizations l10n, String value) {
  switch (value.toUpperCase()) {
    case 'PUBLIC':
      return l10n.t('public');
    case 'PRIVATE':
      return l10n.t('private');
    case 'FRIENDS':
      return l10n.t('friendsOnly');
    default:
      return value;
  }
}

String compactNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

bool hasDraftChanges(ManagedPostEntity source, ManagedPostEntity draft) {
  return source.description != draft.description ||
      source.categoryEntity?.id != draft.categoryEntity?.id ||
      source.category != draft.category ||
      source.privacyStatus != draft.privacyStatus ||
      source.allowComments != draft.allowComments ||
      source.allowDuets != draft.allowDuets ||
      source.allowStitch != draft.allowStitch;
}
