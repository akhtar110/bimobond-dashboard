import '../../../../core/localization/localization.dart';
import '../../../post_reports/domain/entities/post_report_entities.dart';
import '../../domain/entities/managed_post_entity.dart';
import '../../domain/entities/post_moderation_entities.dart';
import '../bloc/post_management_bloc.dart';
import '../utils/post_detail_labels.dart';

enum PostDetailExportFormat { csv, excel, pdf }

class PostDetailExportRow {
  const PostDetailExportRow(this.field, this.value);

  final String field;
  final String value;
}

class PostDetailExportData {
  const PostDetailExportData({
    required this.filenameBase,
    required this.generatedAt,
    required this.details,
    required this.timeline,
    this.analyticsRows = const [],
  });

  final String filenameBase;
  final DateTime generatedAt;
  final List<PostDetailExportRow> details;
  final List<PostDetailExportRow> timeline;
  final List<PostDetailExportRow> analyticsRows;

  factory PostDetailExportData.fromLoaded({
    required PostManagementLoaded state,
    required AppLocalizations l10n,
  }) {
    final post = state.post;
    final locale = l10n.locale.languageCode;
    final details = <PostDetailExportRow>[
      PostDetailExportRow(l10n.t('postId'), post.id),
      PostDetailExportRow(l10n.t('postStatus'), postStatusLabel(l10n, post.status)),
      PostDetailExportRow(l10n.t('type'), post.displayContentType),
      PostDetailExportRow(l10n.t('caption'), post.description ?? ''),
      PostDetailExportRow(l10n.t('categoryName'), post.category ?? ''),
      PostDetailExportRow(l10n.t('privacy'), privacyLabel(l10n, post.privacyStatus)),
      PostDetailExportRow(l10n.t('created'), _formatDate(post.createdAt, locale)),
      PostDetailExportRow(l10n.tOr('updatedAtShort', 'Updated'), _formatDate(post.updatedAt, locale)),
      PostDetailExportRow(l10n.t('views'), '${post.viewCount}'),
      PostDetailExportRow(l10n.t('likes'), '${post.likeCount}'),
      PostDetailExportRow(l10n.t('comments'), '${post.commentCount}'),
      PostDetailExportRow(l10n.t('saves'), '${post.saveCount}'),
      PostDetailExportRow(l10n.t('reposts'), '${post.repostCount}'),
      PostDetailExportRow(l10n.t('shares'), '${post.shareCount}'),
      PostDetailExportRow(l10n.tOr('downloads', 'Downloads'), '${post.downloadCount}'),
      PostDetailExportRow(l10n.t('allowComments'), '${post.allowComments}'),
      PostDetailExportRow(l10n.t('allowDuets'), '${post.allowDuets}'),
      PostDetailExportRow(l10n.t('allowStitch'), '${post.allowStitch}'),
      PostDetailExportRow(l10n.tOr('isStory', 'Story'), '${post.isStory}'),
      PostDetailExportRow(l10n.tOr('isAd', 'Ad'), '${post.isAd}'),
      PostDetailExportRow(l10n.tOr('isAuctionable', 'Auctionable'), '${post.isAuctionable}'),
      PostDetailExportRow(l10n.tOr('author', 'Author'), _authorLabel(post)),
      PostDetailExportRow(l10n.tOr('username', 'Username'), post.userName ?? ''),
      PostDetailExportRow(l10n.tOr('email', 'Email'), post.userEmail ?? ''),
      PostDetailExportRow(l10n.tOr('userId', 'User ID'), post.userId),
      PostDetailExportRow(
        l10n.tOr('location', 'Location'),
        post.location?.displayLabel ?? post.locationId ?? '',
      ),
      PostDetailExportRow(
        l10n.tOr('mediaItems', 'Media items'),
        '${post.media.length}',
      ),
    ];

    final timeline = _timelineRows(state.timelineEntries, l10n, locale);
    if (timeline.isEmpty) {
      final summary = state.analyticsDetail?.moderationSummary;
      if (summary != null && summary.actionTimeline.isNotEmpty) {
        timeline.addAll(
          _reportTimelineRows(summary.actionTimeline, l10n, locale),
        );
      }
    }

    final analyticsRows = _analyticsRows(state.analyticsDetail, l10n);

    return PostDetailExportData(
      filenameBase: _safeFilename('post_${post.id}'),
      generatedAt: DateTime.now(),
      details: details,
      timeline: timeline,
      analyticsRows: analyticsRows,
    );
  }

  static String _authorLabel(ManagedPostEntity post) {
    if (post.userFullName?.trim().isNotEmpty == true) return post.userFullName!.trim();
    if (post.userName?.trim().isNotEmpty == true) return post.userName!.trim();
    return post.userId;
  }

  static String _formatDate(DateTime date, String locale) {
    return '${date.toLocal()}';
  }

  static String _safeFilename(String raw) {
    return raw.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  static List<PostDetailExportRow> _timelineRows(
    List<PostModerationTimelineEntry> entries,
    AppLocalizations l10n,
    String locale,
  ) {
    final rows = <PostDetailExportRow>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final prefix = '${l10n.tOr('timeline', 'Timeline')} ${i + 1}';
      rows.add(
        PostDetailExportRow(
          '$prefix ${l10n.t("postStatus")}',
          postStatusLabel(l10n, entry.status),
        ),
      );
      rows.add(
        PostDetailExportRow(
          '$prefix ${l10n.tOr("date", "Date")}',
          _formatDate(entry.createdAt, locale),
        ),
      );
      if (entry.moderator != null) {
        rows.add(
          PostDetailExportRow(
            '$prefix ${l10n.tOr("moderator", "Moderator")}',
            entry.moderator!.displayName,
          ),
        );
      }
      if (entry.reason?.isNotEmpty == true) {
        rows.add(
          PostDetailExportRow(
            '$prefix ${l10n.tOr("reason", "Reason")}',
            entry.reason!,
          ),
        );
      }
      if (entry.note?.isNotEmpty == true) {
        rows.add(
          PostDetailExportRow(
            '$prefix ${l10n.tOr("internalNote", "Internal Note")}',
            entry.note!,
          ),
        );
      }
    }
    return rows;
  }

  static List<PostDetailExportRow> _reportTimelineRows(
    List<PostReportModerationLog> entries,
    AppLocalizations l10n,
    String locale,
  ) {
    final rows = <PostDetailExportRow>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final prefix = '${l10n.tOr('timeline', 'Timeline')} ${i + 1}';
      rows.add(
        PostDetailExportRow(
          '$prefix ${l10n.t("postStatus")}',
          postStatusLabel(l10n, entry.status),
        ),
      );
      rows.add(
        PostDetailExportRow(
          '$prefix ${l10n.tOr("date", "Date")}',
          _formatDate(entry.createdAt, locale),
        ),
      );
      if (entry.moderator != null) {
        rows.add(
          PostDetailExportRow(
            '$prefix ${l10n.tOr("moderator", "Moderator")}',
            entry.moderator!.displayName,
          ),
        );
      }
      if (entry.reason?.isNotEmpty == true) {
        rows.add(
          PostDetailExportRow(
            '$prefix ${l10n.tOr("reason", "Reason")}',
            entry.reason!,
          ),
        );
      }
      if (entry.note?.isNotEmpty == true) {
        rows.add(
          PostDetailExportRow(
            '$prefix ${l10n.tOr("internalNote", "Internal Note")}',
            entry.note!,
          ),
        );
      }
    }
    return rows;
  }

  static List<PostDetailExportRow> _analyticsRows(
    PostReportDetailEntity? detail,
    AppLocalizations l10n,
  ) {
    if (detail == null) return const [];
    final metrics = detail.metrics;
    return [
      PostDetailExportRow(l10n.t('views'), '${metrics.viewCount}'),
      PostDetailExportRow(l10n.t('likes'), '${metrics.likeCount}'),
      PostDetailExportRow(l10n.t('comments'), '${metrics.commentCount}'),
      PostDetailExportRow(l10n.t('saves'), '${metrics.saveCount}'),
      PostDetailExportRow(l10n.t('reposts'), '${metrics.repostCount}'),
      PostDetailExportRow(l10n.t('shares'), '${metrics.shareCount}'),
      PostDetailExportRow(
        l10n.tOr('engagementRate', 'Engagement Rate'),
        '${metrics.engagementRate.toStringAsFixed(2)}%',
      ),
      PostDetailExportRow(
        l10n.tOr('completionRate', 'Completion Rate'),
        '${metrics.completionRate.toStringAsFixed(1)}%',
      ),
      PostDetailExportRow(
        l10n.tOr('retentionRate', 'Retention Rate'),
        '${metrics.viewerRetentionRate.toStringAsFixed(1)}%',
      ),
      PostDetailExportRow(
        l10n.tOr('watchTime', 'Watch Time'),
        '${metrics.totalWatchTimeSeconds}s',
      ),
      PostDetailExportRow(
        l10n.tOr('forYou', 'For You'),
        '${metrics.trafficSourceBreakdown.forYou}',
      ),
      PostDetailExportRow(
        l10n.tOr('profile', 'Profile'),
        '${metrics.trafficSourceBreakdown.profile}',
      ),
      PostDetailExportRow(
        l10n.tOr('search', 'Search'),
        '${metrics.trafficSourceBreakdown.search}',
      ),
      PostDetailExportRow(
        l10n.tOr('hashtags', 'Hashtags'),
        '${metrics.trafficSourceBreakdown.hashtags}',
      ),
      PostDetailExportRow(
        l10n.tOr('shares', 'Shares'),
        '${metrics.trafficSourceBreakdown.shares}',
      ),
    ];
  }
}
