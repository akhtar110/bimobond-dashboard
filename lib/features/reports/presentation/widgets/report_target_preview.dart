import 'package:flutter/material.dart';

import '../../domain/entities/report_entity.dart';
import 'report_card_theme.dart';

/// Target content preview for a reported post, user, or comment.
class ReportTargetPreview extends StatelessWidget {
  const ReportTargetPreview({
    super.key,
    required this.report,
  });

  final ReportEntity report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _previewData();
    if (preview == null) return const SizedBox.shrink();

    final (title, body, icon) = preview;

    return Semantics(
      label: '$title: $body',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ReportCardTheme.previewSurface(scheme),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: ReportCardTheme.mutedText(scheme),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ReportCardTheme.mutedText(scheme),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String title, String body, IconData icon)? _previewData() {
    switch (report.targetType) {
      case 'post':
        final desc = report.post?.description;
        final body = desc?.isNotEmpty == true
            ? '"$desc"'
            : 'Post ID: ${report.postId}';
        return ('Post Content', body, Icons.videocam_outlined);
      case 'user':
        final username = report.reportedUser?.username;
        final name = report.reportedUser?.displayName;
        final body = username?.isNotEmpty == true
            ? '@$username'
            : (name ?? 'User ID: ${report.reportedUserId}');
        return ('Reported User', body, Icons.person_outline_rounded);
      case 'comment':
        return (
          'Comment',
          'Comment ID: ${report.commentId}',
          Icons.chat_bubble_outline_rounded,
        );
      default:
        return null;
    }
  }
}
