import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../../../features/post_management/presentation/utils/post_detail_labels.dart';
import '../bloc/posts_bloc.dart';

const double kPostsTableHeaderHeight = 40;
const double _kCellHPad = 8;
const double _kRowVPad = 8;

enum PostsTableDensity { wide, medium, narrow }

PostsTableDensity postsTableDensityForWidth(double width) {
  if (width >= 1180) return PostsTableDensity.wide;
  if (width >= 860) return PostsTableDensity.medium;
  return PostsTableDensity.narrow;
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
        title: Text(l10n.t('postTitle'), style: style),
        author: density == PostsTableDensity.narrow
            ? const SizedBox.shrink()
            : Text(l10n.t('postAuthor'), style: style),
        status: Text(l10n.t('postStatus'), style: style),
        visibility: density == PostsTableDensity.wide
            ? Text(l10n.t('visibility'), style: style)
            : const SizedBox.shrink(),
        engagement: density != PostsTableDensity.narrow
            ? Text(l10n.t('engagement'), style: style)
            : const SizedBox.shrink(),
        created: Text(l10n.t('createdAt'), style: style),
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
  });

  final ManagedPostEntity post;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final VoidCallback onTap;
  final PostsTableDensity density;

  @override
  State<PostsTableRow> createState() => _PostsTableRowState();
}

class _PostsTableRowState extends State<PostsTableRow> {
  bool _hovered = false;

  String get _title {
    final description = widget.post.description?.trim();
    if (description != null && description.isNotEmpty) return description;
    return widget.post.userName ?? widget.post.userId;
  }

  String get _author =>
      widget.post.userFullName?.trim().isNotEmpty == true
          ? widget.post.userFullName!
          : (widget.post.userName ?? widget.post.userId);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final post = widget.post;
    final created = DateFormat(
      widget.density == PostsTableDensity.narrow ? 'MMM d' : 'MMM d, yyyy',
    ).format(post.createdAt);
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          height: 1.25,
        );

    final bg = widget.isSelected
        ? scheme.primaryContainer.withValues(alpha: 0.18)
        : _hovered
            ? scheme.surfaceContainerHighest
            : scheme.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: _kRowVPad),
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
                _title,
                maxLines: widget.density == PostsTableDensity.narrow ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
              ),
              author: widget.density == PostsTableDensity.narrow
                  ? const SizedBox.shrink()
                  : Text(
                      _author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle,
                    ),
              status: _StatusChip(status: post.status),
              visibility: widget.density == PostsTableDensity.wide
                  ? Text(
                      privacyLabel(l10n, post.privacyStatus),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
                    )
                  : const SizedBox.shrink(),
              engagement: widget.density != PostsTableDensity.narrow
                  ? _EngagementMetrics(
                      post: post,
                      compact: widget.density == PostsTableDensity.medium,
                    )
                  : const SizedBox.shrink(),
              created: Text(
                created,
                maxLines: 1,
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
  final Widget created;

  @override
  Widget build(BuildContext context) {
    final showAuthor = density != PostsTableDensity.narrow;
    final showVisibility = density == PostsTableDensity.wide;
    final showEngagement = density != PostsTableDensity.narrow;
    final thumbWidth = density == PostsTableDensity.narrow ? 42.0 : 50.0;

    // Flex weights redistribute space after removing the category column.
    final titleFlex = switch (density) {
      PostsTableDensity.wide => 5,
      PostsTableDensity.medium => 5,
      PostsTableDensity.narrow => 6,
    };
    final authorFlex = 3;
    final statusFlex = 2;
    final visibilityFlex = 2;
    final engagementFlex = density == PostsTableDensity.medium ? 3 : 4;
    final createdFlex = 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 34, child: checkbox),
        SizedBox(width: thumbWidth, child: thumbnail),
        Expanded(flex: titleFlex, child: _cell(title)),
        if (showAuthor) Expanded(flex: authorFlex, child: _cell(author)),
        Expanded(flex: statusFlex, child: _cell(status)),
        if (showVisibility)
          Expanded(flex: visibilityFlex, child: _cell(visibility)),
        if (showEngagement)
          Expanded(flex: engagementFlex, child: _cell(engagement)),
        Expanded(flex: createdFlex, child: _cell(created)),
      ],
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kCellHPad),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: child,
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.post, this.small = false});

  final ManagedPostEntity post;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = post.displayThumbnailUrl;
    final size = small ? 36.0 : 42.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, e, st) => _placeholder(scheme),
              )
            : _placeholder(scheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Icon(Icons.image_outlined, size: 16, color: scheme.onSurfaceVariant),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = postStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        postStatusLabel(l10n, status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
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
