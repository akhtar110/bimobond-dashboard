import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_history_entity.dart';

String userHistoryTypeLabel(AppLocalizations l10n, String type) {
  return switch (type.toUpperCase()) {
    UserHistoryTypes.profileView =>
      l10n.tOr('userHistoryTypeProfileView', 'Profile View'),
    UserHistoryTypes.screenView =>
      l10n.tOr('userHistoryTypeScreenView', 'Screen View'),
    UserHistoryTypes.share => l10n.tOr('userHistoryTypeShare', 'Share'),
    UserHistoryTypes.profileVisitGiven =>
      l10n.tOr('userHistoryTypeProfileVisitGiven', 'Profile Visit Given'),
    UserHistoryTypes.profileVisitReceived =>
      l10n.tOr('userHistoryTypeProfileVisitReceived', 'Profile Visit Received'),
    UserHistoryTypes.createPost =>
      l10n.tOr('userHistoryTypeCreatePost', 'Create Post'),
    UserHistoryTypes.likePost =>
      l10n.tOr('userHistoryTypeLikePost', 'Like Post'),
    UserHistoryTypes.comment => l10n.tOr('userHistoryTypeComment', 'Comment'),
    UserHistoryTypes.repost => l10n.tOr('userHistoryTypeRepost', 'Repost'),
    UserHistoryTypes.sendGift =>
      l10n.tOr('userHistoryTypeSendGift', 'Send Gift'),
    UserHistoryTypes.postView =>
      l10n.tOr('userHistoryTypePostView', 'Post View'),
    UserHistoryTypes.save => l10n.tOr('userHistoryTypeSave', 'Save'),
    UserHistoryTypes.storyView =>
      l10n.tOr('userHistoryTypeStoryView', 'Story View'),
    UserHistoryTypes.search => l10n.tOr('userHistoryTypeSearch', 'Search'),
    UserHistoryTypes.location =>
      l10n.tOr('userHistoryTypeLocation', 'Location'),
    _ => type,
  };
}
