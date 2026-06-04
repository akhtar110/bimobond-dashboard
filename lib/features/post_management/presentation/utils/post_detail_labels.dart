import '../../../../core/localization/localization.dart';
import '../../domain/entities/managed_post_entity.dart';

String postStatusLabel(AppLocalizations l10n, String status) {
  switch (status.toUpperCase()) {
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
      source.category != draft.category ||
      source.privacyStatus != draft.privacyStatus ||
      source.allowComments != draft.allowComments ||
      source.allowDuets != draft.allowDuets ||
      source.allowStitch != draft.allowStitch;
}
