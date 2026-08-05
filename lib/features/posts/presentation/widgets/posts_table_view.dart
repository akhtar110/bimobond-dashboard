import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../domain/utils/post_author_display.dart';
import 'post_list_thumbnail.dart';
import '../../../../features/post_management/presentation/utils/post_detail_labels.dart';
import '../bloc/posts_bloc.dart';
import '../utils/post_date_format.dart';
import 'post_list_location.dart';

const double kPostsTableHeaderHeight = 36;
const double kPostsTableRowHeight = 56;
const double _kCellHPad = 8;

String postDisplayTitle(ManagedPostEntity post) {
  final description = post.description?.trim();
  if (description != null && description.isNotEmpty) return description;
  return post.userName ?? post.userId;
}

String postDisplayAuthor(ManagedPostEntity post) => postAuthorDisplayName(post);

enum PostsTableDensity { wide, medium, narrow, compact }

PostsTableDensity postsTableDensityForWidth(double width) {
  if (width >= 1180) return PostsTableDensity.wide;
  if (width >= 900) return PostsTableDensity.medium;
  if (width >= 700) return PostsTableDensity.narrow;
  return PostsTableDensity.compact;
}

double _postsTableCheckboxWidth(PostsTableDensity density) =>
    density == PostsTableDensity.compact ? 28.0 : 34.0;

double _postsTableThumbWidth(PostsTableDensity density) => switch (density) {
  PostsTableDensity.compact => 32.0,
  PostsTableDensity.narrow => 42.0,
  _ => 50.0,
};

double _postsTableCellHPad(PostsTableDensity density) => switch (density) {
  PostsTableDensity.compact => 4.0,
  PostsTableDensity.narrow => 6.0,
  _ => _kCellHPad,
};

double _postsTableRowHPad(PostsTableDensity density) =>
    density == PostsTableDensity.compact ? 6.0 : 10.0;

class PostsTableHeader extends StatelessWidget {
  const PostsTableHeader({
    super.key,
    required this.l10n,
    required this.allVisibleSelected,
    required this.someVisibleSelected,
    required this.density,
  });

  final AppLocalizations l10n;
  final bool allVisibleSelected;
  final bool someVisibleSelected;
  final PostsTableDensity density;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      fontSize: 11,
      letterSpacing: 0.1,
    );

    return Container(
      height: kPostsTableHeaderHeight,
      color: scheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(horizontal: _postsTableRowHPad(density)),
      child: _PostsTableRowLayout(
        density: density,
        checkbox: Checkbox(
          tristate: true,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: allVisibleSelected
              ? true
              : someVisibleSelected
              ? null
              : false,
          onChanged: (_) =>
              context.read<PostsBloc>().add(SelectAllPostsEvent()),
        ),
        thumbnail: Text(
          density == PostsTableDensity.narrow ? '' : l10n.t('thumbnail'),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        title: Text(
          l10n.t('postTitle'),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        author: density == PostsTableDensity.narrow
            ? const SizedBox.shrink()
            : Text(
                l10n.t('postAuthor'),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        status: Text(
          l10n.t('postStatus'),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        visibility: density == PostsTableDensity.wide
            ? Text(l10n.t('visibility'), style: style)
            : const SizedBox.shrink(),
        engagement: density != PostsTableDensity.narrow
            ? Text(l10n.t('engagement'), style: style)
            : const SizedBox.shrink(),
        location: density != PostsTableDensity.narrow
            ? Text(
                l10n.t('location'),
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : const SizedBox.shrink(),
        created: Text(
          l10n.t('createdAt'),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class PostsTableRow extends StatefulWidget {
  const PostsTableRow({
    super.key,
    required this.post,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
    required this.density,
    this.striped = false,
  });

  final ManagedPostEntity post;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;
  final PostsTableDensity density;
  final bool striped;

  @override
  State<PostsTableRow> createState() => _PostsTableRowState();
}

class _PostsTableRowState extends State<PostsTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final post = widget.post;
    final locale = Localizations.localeOf(context).languageCode;
    final created = formatPostCreatedDateTime(
      post.createdAt,
      locale: locale,
      compact:
          widget.density == PostsTableDensity.narrow ||
          widget.density == PostsTableDensity.compact,
    );
    final cellStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.25);

    Color rowColor;
    if (widget.isSelected) {
      rowColor = scheme.primaryContainer.withValues(alpha: 0.18);
    } else if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            height: kPostsTableRowHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _postsTableRowHPad(widget.density),
              ),
              child: _PostsTableRowLayout(
                density: widget.density,
                checkbox: Checkbox(
                  value: widget.isSelected,
                  onChanged: widget.onSelectionChanged,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                thumbnail: _Thumb(
                  post: post,
                  small: widget.density == PostsTableDensity.narrow,
                ),
                title: Text(
                  postDisplayTitle(post),
                  maxLines: widget.density == PostsTableDensity.narrow ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                author: widget.density == PostsTableDensity.narrow
                    ? const SizedBox.shrink()
                    : Text(
                        postDisplayAuthor(post),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cellStyle,
                      ),
                status: PostsStatusChip(status: post.status),
                visibility: widget.density == PostsTableDensity.wide
                    ? Text(
                        privacyLabel(l10n, post.privacyStatus),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cellStyle?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
                engagement: widget.density != PostsTableDensity.narrow
                    ? _EngagementMetrics(
                        post: post,
                        compact: widget.density == PostsTableDensity.medium,
                      )
                    : const SizedBox.shrink(),
                location: widget.density != PostsTableDensity.narrow
                    ? PostListLocationLabel(
                        post: post,
                        compact: widget.density == PostsTableDensity.medium,
                        iconSize: 11,
                        fontSize: 11,
                      )
                    : const SizedBox.shrink(),
                created: Text(
                  created,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: cellStyle?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostsTableRowLayout extends StatelessWidget {
  const _PostsTableRowLayout({
    required this.density,
    required this.checkbox,
    required this.thumbnail,
    required this.title,
    required this.author,
    required this.status,
    required this.visibility,
    required this.engagement,
    required this.location,
    required this.created,
  });

  final PostsTableDensity density;
  final Widget checkbox;
  final Widget thumbnail;
  final Widget title;
  final Widget author;
  final Widget status;
  final Widget visibility;
  final Widget engagement;
  final Widget location;
  final Widget created;

  @override
  Widget build(BuildContext context) {
    final showAuthor = density != PostsTableDensity.narrow;
    final showVisibility = density == PostsTableDensity.wide;
    final showEngagement = density != PostsTableDensity.narrow;
    final showLocation = density != PostsTableDensity.narrow;
    final showCreated = true;
    final checkboxWidth = _postsTableCheckboxWidth(density);
    final thumbWidth = _postsTableThumbWidth(density);
    final cellHPad = _postsTableCellHPad(density);

    // Flex weights redistribute space after removing the category column.
    final titleFlex = switch (density) {
      PostsTableDensity.wide => 5,
      PostsTableDensity.medium => 5,
      PostsTableDensity.narrow => 6,
      PostsTableDensity.compact => 1,
    };
    final authorFlex = 3;
    const statusFlex = 2;
    final visibilityFlex = 2;
    final engagementFlex = density == PostsTableDensity.medium ? 3 : 4;
    const locationFlex = 2;
    const createdFlex = 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: checkboxWidth, child: checkbox),
        SizedBox(width: thumbWidth, child: thumbnail),
        Expanded(flex: titleFlex, child: _cell(title, cellHPad)),
        if (showAuthor)
          Expanded(flex: authorFlex, child: _cell(author, cellHPad)),
        Expanded(flex: statusFlex, child: _cell(status, cellHPad)),
        if (showVisibility)
          Expanded(flex: visibilityFlex, child: _cell(visibility, cellHPad)),
        if (showEngagement)
          Expanded(flex: engagementFlex, child: _cell(engagement, cellHPad)),
        if (showLocation)
          Expanded(flex: locationFlex, child: _cell(location, cellHPad)),
        if (showCreated)
          Expanded(flex: createdFlex, child: _cell(created, cellHPad)),
      ],
    );
  }

  Widget _cell(Widget child, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(alignment: AlignmentDirectional.centerStart, child: child),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.post, this.small = false, this.size});

  final ManagedPostEntity post;
  final bool small;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = post.previewThumbnailUrl;
    final thumbSize = size ?? (small ? 36.0 : 42.0);
    final isVideo = post.containsVideoMedia;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: thumbSize,
        height: thumbSize,
        child: url != null && url.isNotEmpty
            ? PostListThumbnail(
                key: ValueKey('table_thumb_${post.id}_$url'),
                postId: post.id,
                imageUrl: url,
                fit: BoxFit.cover,
                error: (_) => _placeholder(scheme, isVideo: isVideo),
              )
            : _placeholder(scheme, isVideo: isVideo),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme, {bool isVideo = false}) {
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        size: 16,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class PostsStatusChip extends StatelessWidget {
  const PostsStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = postStatusColor(status, scheme);
    final label = postStatusLabel(l10n, status);
    final icon = postStatusIcon(status);

    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 10 : 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: chip,
    );
  }
}

class PostsCompactCard extends StatelessWidget {
  const PostsCompactCard({
    super.key,
    required this.post,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onTap,
  });

  final ManagedPostEntity post;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final created = formatPostCreatedDateTime(
      post.createdAt,
      locale: locale,
      compact: true,
    );
    final location = postListLocationLabel(post);
    final subtitleParts = <String>[
      postDisplayAuthor(post),
      created,
      if (location != null && location.isNotEmpty) location,
      '${_fmt(post.likeCount)} ♥',
    ];
    final subtitle = subtitleParts.join(' · ');

    return Material(
      color: isSelected
          ? scheme.primaryContainer.withValues(alpha: 0.12)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: onSelectionChanged,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              _Thumb(post: post, size: 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postDisplayTitle(post),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (location != null && location.isNotEmpty) ...[
                      PostLocationRow(
                        post: post,
                        compact: true,
                        fontSize: 11,
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PostsStatusChip(status: post.status, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EngagementMetrics extends StatelessWidget {
  const _EngagementMetrics({required this.post, this.compact = false});

  final ManagedPostEntity post;
  final bool compact;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);

    if (compact) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _metric(Icons.favorite_border, _fmt(post.likeCount), style),
            const SizedBox(width: 8),
            _metric(Icons.chat_bubble_outline, _fmt(post.commentCount), style),
            const SizedBox(width: 8),
            _metric(Icons.visibility_outlined, _fmt(post.viewCount), style),
            const SizedBox(width: 8),
            _metric(Icons.flag_outlined, _fmt(post.reportCount), style),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _metric(Icons.favorite_border, _fmt(post.likeCount), style),
          const SizedBox(width: 8),
          _metric(Icons.chat_bubble_outline, _fmt(post.commentCount), style),
          const SizedBox(width: 8),
          _metric(Icons.share_outlined, _fmt(post.shareCount), style),
          const SizedBox(width: 8),
          _metric(Icons.visibility_outlined, _fmt(post.viewCount), style),
          const SizedBox(width: 8),
          _metric(Icons.flag_outlined, _fmt(post.reportCount), style),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: style.color),
        const SizedBox(width: 3),
        Text(value, style: style),
      ],
    );
  }
}
