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

/// Builds a PATCH payload containing only fields that differ from [original].
ManagedPostUpdateData buildManagedPostUpdateDiff(
  ManagedPostEntity original,
  ManagedPostEntity draft,
) {
  return ManagedPostUpdateData(
    description:
        original.description != draft.description ? draft.description : null,
    categoryId: original.categoryEntity?.id != draft.categoryEntity?.id
        ? draft.categoryEntity?.id
        : null,
    privacyStatus: original.privacyStatus != draft.privacyStatus
        ? draft.privacyStatus
        : null,
    status: original.status != draft.status ? draft.status : null,
    allowComments: original.allowComments != draft.allowComments
        ? draft.allowComments
        : null,
    allowDuets:
        original.allowDuets != draft.allowDuets ? draft.allowDuets : null,
    allowStitch:
        original.allowStitch != draft.allowStitch ? draft.allowStitch : null,
  );
}

bool managedPostUpdateDataHasChanges(ManagedPostUpdateData data) {
  return data.description != null ||
      data.categoryId != null ||
      data.category != null ||
      data.privacyStatus != null ||
      data.status != null ||
      data.allowComments != null ||
      data.allowDuets != null ||
      data.allowStitch != null;
}

/// Human-readable label for a moderation timeline field key.
String moderationTimelineFieldLabel(AppLocalizations l10n, String fieldKey) {
  final key = fieldKey.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  return switch (key) {
    'description' || 'caption' => l10n.t('caption'),
    'categoryid' || 'category' => l10n.t('categoryName'),
    'privacystatus' || 'privacy' => l10n.t('privacy'),
    'status' => l10n.t('postStatus'),
    'allowcomments' => l10n.t('allowComments'),
    'allowduets' => l10n.t('allowDuets'),
    'allowstitch' => l10n.t('allowStitch'),
    _ => fieldKey.trim(),
  };
}

/// Formats admin field-update timeline messages to list only affected fields.
String? formatModerationTimelineAdminAction(
  AppLocalizations l10n, {
  String? reason,
  List<String> changedFields = const [],
}) {
  final fields = changedFields.isNotEmpty
      ? changedFields
      : _parseAdminUpdatedFieldsFromReason(reason);
  if (fields.isEmpty) return null;

  final labels = fields
      .map((field) => moderationTimelineFieldLabel(l10n, field))
      .where((label) => label.isNotEmpty)
      .toSet()
      .toList();
  if (labels.isEmpty) return null;

  final joined = labels.join(', ');
  return '${l10n.tOr('adminUpdatedPostFieldsPrefix', 'Admin updated')}: $joined';
}

List<String> _parseAdminUpdatedFieldsFromReason(String? reason) {
  if (reason == null || reason.trim().isEmpty) return const [];

  final match = RegExp(
    r'admin\s+update(?:d)?\s+fields?\s*:?\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(reason.trim());
  if (match == null) return const [];

  return match
      .group(1)!
      .split(RegExp(r'[,;]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}
