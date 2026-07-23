import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_viewer_slide.dart';

abstract final class StoriesAdminL10n {
  static String pageTitle(BuildContext context) =>
      context.l10n.tOr('storiesManagement', 'Stories');

  static String pageSubtitle(BuildContext context) =>
      context.l10n.tOr(
        'storiesManagementSubtitle',
        'Moderate published stories, privacy, and TTL.',
      );

  static String searchHint(BuildContext context) =>
      context.l10n.tOr('storiesSearchHint', 'Search by description…');

  static String noStories(BuildContext context) =>
      context.l10n.tOr('storiesNoResults', 'No stories found');

  static String statusLabel(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return context.l10n.tOr('storiesStatusPublished', 'Published');
      case 'HIDDEN':
        return context.l10n.tOr('storiesStatusHidden', 'Hidden');
      case 'EXPIRED':
        return context.l10n.tOr('storiesStatusExpired', 'Expired');
      default:
        return status;
    }
  }

  static String privacyLabel(BuildContext context, String privacy) {
    switch (privacy.toUpperCase()) {
      case 'PUBLIC':
        return context.l10n.tOr('storiesPrivacyPublic', 'Public');
      case 'PRIVATE':
        return context.l10n.tOr('storiesPrivacyPrivate', 'Private');
      case 'FRIENDS':
        return context.l10n.tOr('storiesPrivacyFriends', 'Friends');
      default:
        return privacy;
    }
  }

  static String activeOnlyLabel(BuildContext context) =>
      context.l10n.tOr('storiesActiveOnly', 'Active only');

  /// Status dropdown value for the active-only API filter (not a story status).
  static const String activeStatusFilter = '__ACTIVE__';

  static String activeStatusFilterLabel(BuildContext context) =>
      context.l10n.tOr('storiesActive', 'Active');

  static String userIdFilter(BuildContext context) =>
      context.l10n.tOr('storiesUserIdFilter', 'User ID');

  static String pageSizeLabel(BuildContext context) =>
      context.l10n.tOr('storiesPageSize', 'Page size');

  static String viewDetails(BuildContext context) =>
      context.l10n.t('viewDetails');

  static String editStory(BuildContext context) =>
      context.l10n.tOr('storiesEditStory', 'Edit Story');

  static String deleteStory(BuildContext context) =>
      context.l10n.tOr('storiesDeleteStory', 'Delete Story');

  static String updateSuccess(BuildContext context) =>
      context.l10n.tOr('storiesUpdateSuccess', 'Story updated');

  static String deleteSuccess(BuildContext context) =>
      context.l10n.tOr('storiesDeleteSuccess', 'Story deleted');

  static String ttlValidation(BuildContext context) => context.l10n.tOr(
        'storiesTtlValidation',
        'TTL must be between 1 and 168 hours',
      );

  static String activeIndicator(BuildContext context, StoryEntity story) =>
      story.isActive
          ? context.l10n.tOr('storiesActive', 'Active')
          : context.l10n.tOr('storiesInactive', 'Expired / inactive');

  static String formatDate(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '—';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dateTime.toLocal());
  }

  static String authorName(BuildContext context, StoryEntity story) {
    final user = story.user;
    if (user == null) return story.userId;
    final name = user.displayName.trim();
    if (name.isEmpty) {
      return context.l10n.tOr('activeStoryUnknownAuthor', 'Unknown');
    }
    return name;
  }

  static String authorUsername(StoryEntity story) =>
      story.user?.username.trim().isNotEmpty == true
          ? '@${story.user!.username.trim()}'
          : '';

  static String viewerAuthorName(BuildContext context, StoryViewerAuthor author) {
    final name = author.name.trim();
    if (name.isEmpty) {
      return context.l10n.tOr('activeStoryUnknownAuthor', 'Unknown');
    }
    return name;
  }

  static String viewsLabel(BuildContext context, int count) => context.l10n
      .tOr('storiesViewsCount', '$count views')
      .replaceAll('{count}', '$count');

  static String ttlHoursLabel(BuildContext context, int hours) =>
      context.l10n
          .tOr('storiesTtlHours', '{hours}h TTL')
          .replaceAll('{hours}', '$hours');
}
