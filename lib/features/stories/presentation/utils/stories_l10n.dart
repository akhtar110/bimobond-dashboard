import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/active_story_author.dart';
import '../../domain/entities/active_story_entity.dart';

/// Localized copy for the active stories strip and viewer on [PostsPage].
abstract final class StoriesL10n {
  static const _unknownAuthorToken = 'Unknown';

  static String sectionTitle(BuildContext context) =>
      context.l10n.t('activeStoriesTitle');

  static String defaultStoryTitle(BuildContext context) =>
      context.l10n.t('activeStoryDefaultTitle');

  static String unknownAuthor(BuildContext context) =>
      context.l10n.t('activeStoryUnknownAuthor');

  static String viewDetails(BuildContext context) =>
      context.l10n.t('viewDetails');

  static String loading(BuildContext context) => context.l10n.t('loading');

  static String bubbleLabel(BuildContext context, ActiveStoryEntity story) {
    return authorName(context, story.author);
  }

  static String authorName(BuildContext context, ActiveStoryAuthor author) {
    final name = author.name.trim();
    if (name.isEmpty || name == _unknownAuthorToken) {
      return unknownAuthor(context);
    }
    return name;
  }

  static String formatCreatedAt(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_jm().format(dateTime.toLocal());
  }
}
