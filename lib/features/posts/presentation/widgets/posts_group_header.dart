import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../utils/post_date_format.dart';
import '../utils/posts_date_grouping.dart';
import '../utils/posts_responsive.dart';

/// Modern, space-efficient section header for date-grouped posts with centered date text.
class PostsGroupHeader extends StatelessWidget {
  const PostsGroupHeader({
    super.key,
    required this.title,
    required this.count,
    this.dateText,
    this.isFirst = false,
    this.metrics,
  });

  final String title;
  final int count;
  final String? dateText;
  final bool isFirst;
  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final layout = metrics ??
        PostsLayoutMetrics(getPostsDeviceType(MediaQuery.sizeOf(context).width));
    final compact = layout.isMobile;

    final topPadding = isFirst ? 2.0 : (compact ? 8.0 : 12.0);
    final bottomPadding = compact ? 6.0 : 8.0;
    final hasDate = dateText != null && dateText!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Title & Count Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : 14,
                  letterSpacing: -0.1,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Left divider
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          // Center: Date badge
          if (hasDate) ...[
            const SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                dateText!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 11 : 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Right divider
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Computes a localized date or date-range label for a [PostsDateGroup].
String? postsDateGroupDateText(BuildContext context, PostsDateGroup group) {
  if (group.posts.isEmpty) return null;

  final locale = context.l10n.locale.languageCode;
  final dates = group.posts
      .map((p) => dateOnly(p.createdAt.toLocal()))
      .toList()
    ..sort();
  final earliest = dates.first;
  final latest = dates.last;

  if (earliest == latest) {
    return DateFormat.yMMMd(locale).format(earliest);
  }

  final sameYear = earliest.year == latest.year;
  final startStr = sameYear
      ? DateFormat.MMMd(locale).format(earliest)
      : DateFormat.yMMMd(locale).format(earliest);
  final endStr = DateFormat.yMMMd(locale).format(latest);

  return '$startStr – $endStr';
}

/// Localized header for a [PostsDateGroup].
class PostsDateGroupHeader extends StatelessWidget {
  const PostsDateGroupHeader({
    super.key,
    required this.group,
    this.isFirst = false,
    this.metrics,
  });

  final PostsDateGroup group;
  final bool isFirst;
  final PostsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return PostsGroupHeader(
      title: postsDateGroupLabel(context.l10n, group.kind),
      dateText: postsDateGroupDateText(context, group),
      count: group.count,
      isFirst: isFirst,
      metrics: metrics,
    );
  }
}
