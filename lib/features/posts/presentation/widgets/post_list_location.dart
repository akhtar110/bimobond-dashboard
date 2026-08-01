import 'package:flutter/material.dart';

import '../../../post_management/data/utils/managed_post_location_hydration.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../../domain/utils/post_location_filter.dart';
import '../utils/post_card_layout.dart';
import '../utils/post_date_format.dart';
import 'posts_location_filter.dart';

String? postListLocationLabel(ManagedPostEntity post) =>
    managedPostListLocationLabel(post);

/// Prominent location row for post cards and list cells.
class PostLocationRow extends StatelessWidget {
  const PostLocationRow({
    super.key,
    required this.post,
    this.compact = false,
    this.fontSize = 11,
  });

  final ManagedPostEntity post;
  final bool compact;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final label = postListLocationLabel(post);
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.location_on_rounded,
            size: fontSize + 2,
            color: scheme.tertiary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact location label for posts table cells.
class PostListLocationLabel extends StatelessWidget {
  const PostListLocationLabel({
    super.key,
    required this.post,
    this.compact = false,
    this.iconSize = 11,
    this.fontSize = 10,
  });

  final ManagedPostEntity post;
  final bool compact;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final label = postListLocationLabel(post);
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: iconSize,
          color: scheme.tertiary,
        ),
        SizedBox(width: compact ? 2 : 3),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Created date, optional location, and engagement metrics.
class PostListMetaRow extends StatelessWidget {
  const PostListMetaRow({
    super.key,
    required this.post,
    required this.metrics,
    this.hovered = false,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool hovered;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = formatPostCreatedDateTime(
      post.createdAt,
      locale: locale,
      compact: metrics.compact,
    );
    final location = postListLocationLabel(post);
    final metaSize = metrics.metaFontSize;
    final statSize = metrics.statFontSize;

    final stats = <Widget>[
      if (metrics.showViewStat)
        _InlineStat(
          icon: Icons.visibility_outlined,
          value: _fmt(post.viewCount),
          color: scheme.primary,
          size: statSize,
        ),
      if (metrics.showLikeStat) ...[
        if (metrics.showViewStat) SizedBox(width: metrics.compact ? 4 : 6),
        _InlineStat(
          icon: Icons.favorite_border_rounded,
          value: _fmt(post.likeCount),
          color: scheme.error,
          size: statSize,
        ),
      ],
      if (metrics.showCommentStat) ...[
        SizedBox(width: metrics.compact ? 4 : 6),
        _InlineStat(
          icon: Icons.chat_bubble_outline_rounded,
          value: _fmt(post.commentCount),
          color: scheme.tertiary,
          size: statSize,
        ),
      ],
      if (metrics.showShareStat) ...[
        SizedBox(width: metrics.compact ? 4 : 6),
        _InlineStat(
          icon: Icons.share_outlined,
          value: _fmt(post.shareCount),
          color: scheme.secondary,
          size: statSize,
        ),
      ],
    ];

    final dateRow = Text(
      dateStr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: metaSize,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
        height: 1.1,
      ),
    );

    final locationCoords = managedPostFilterCoordinates(post);
    final locationRow = location != null
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: locationCoords == null
                  ? null
                  : () => applyPostLocationProximityFilter(context, post),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: metaSize + 3,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: metaSize + 0.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.tertiary,
                          height: 1.1,
                          decoration: locationCoords != null
                              ? TextDecoration.underline
                              : null,
                          decorationColor:
                              scheme.tertiary.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : null;

    final dateLocationRow = locationRow == null
        ? dateRow
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateRow,
              SizedBox(height: metrics.compact ? 2 : 3),
              locationRow,
            ],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        vertical: metrics.compact ? 3 : 4,
        horizontal: metrics.compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: hovered && metrics.enableHoverEffects
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : scheme.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(
            alpha: hovered && metrics.enableHoverEffects ? 0.8 : 0.55,
          ),
        ),
      ),
      child: metrics.stackMetaRow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateLocationRow,
                SizedBox(height: metrics.compact ? 3 : 4),
                Wrap(
                  spacing: metrics.compact ? 2 : 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: stats,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: dateLocationRow),
                const SizedBox(width: 6),
                ...stats,
              ],
            ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.icon,
    required this.value,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final String value;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: size + 1, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
      ],
    );
  }
}
