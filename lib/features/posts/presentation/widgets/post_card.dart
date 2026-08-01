import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/categories/presentation/widgets/category_icon.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../../../features/post_management/presentation/utils/post_detail_labels.dart';
import '../utils/post_card_layout.dart';
import '../utils/posts_page_layout.dart';
import '../utils/posts_responsive.dart';
import 'post_list_location.dart';
import 'post_list_thumbnail.dart';
import 'posts_table_view.dart';

/// Compact thumbnail aspect — wider than tall so cards stay shorter.
const double kPostCardThumbnailAspectCompact = 1.65;
const double kPostCardThumbnailAspect = 1.75;

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.metrics,
  });

  final ManagedPostEntity post;
  final VoidCallback? onTap;

  /// When provided by the grid, skips [LayoutBuilder] during scroll.
  final PostCardMetrics? metrics;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _hovered = false;

  PostCardMetrics _resolveMetrics(BoxConstraints constraints) {
    return widget.metrics ??
        PostCardMetrics(
          cardWidth: constraints.maxWidth,
          deviceType: getPostsDeviceType(MediaQuery.sizeOf(context).width),
          columns: postsGridColumnCount(MediaQuery.sizeOf(context).width),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.metrics != null) {
      return _buildCard(context, widget.metrics!, scheme, isDark);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildCard(
          context,
          _resolveMetrics(constraints),
          scheme,
          isDark,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    PostCardMetrics metrics,
    ColorScheme scheme,
    bool isDark,
  ) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(metrics.borderRadius),
        border: Border.all(
          color: _hovered && metrics.enableHoverEffects
              ? scheme.primary.withValues(alpha: 0.42)
              : scheme.outlineVariant.withValues(alpha: 0.85),
          width: _hovered && metrics.enableHoverEffects ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(
              alpha: _hovered && metrics.enableHoverEffects
                  ? (isDark ? 0.45 : 0.12)
                  : (isDark ? 0.28 : 0.05),
            ),
            blurRadius:
                _hovered && metrics.enableHoverEffects ? 18 : 10,
            spreadRadius: _hovered && metrics.enableHoverEffects ? 0.5 : 0,
            offset: Offset(
              0,
              _hovered && metrics.enableHoverEffects ? 8 : 3,
            ),
          ),
          if (_hovered && metrics.enableHoverEffects)
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(metrics.borderRadius),
        child: metrics.isHorizontal
            ? _HorizontalCardBody(
                post: widget.post,
                metrics: metrics,
                isDark: isDark,
                hovered: _hovered,
              )
            : _VerticalCardBody(
                post: widget.post,
                metrics: metrics,
                isDark: isDark,
                hovered: _hovered,
              ),
      ),
    );

    Widget interactive = card;
    if (metrics.enableHoverEffects) {
      interactive = AnimatedScale(
        scale: _hovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedSlide(
          offset: _hovered ? const Offset(0, -0.012) : Offset.zero,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: card,
        ),
      );
    }

    return MouseRegion(
      onEnter: metrics.enableHoverEffects
          ? (_) => setState(() => _hovered = true)
          : null,
      onExit: metrics.enableHoverEffects
          ? (_) => setState(() => _hovered = false)
          : null,
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: interactive,
      ),
    );
  }
}

class _VerticalCardBody extends StatelessWidget {
  const _VerticalCardBody({
    required this.post,
    required this.metrics,
    required this.isDark,
    required this.hovered,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool isDark;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MediaPreview(
          post: post,
          metrics: metrics,
          isDark: isDark,
          hovered: hovered,
        ),
        Padding(
          padding: metrics.bodyPadding,
          child: _CardContent(
            post: post,
            metrics: metrics,
            isDark: isDark,
            hovered: hovered,
          ),
        ),
      ],
    );
  }
}

class _HorizontalCardBody extends StatelessWidget {
  const _HorizontalCardBody({
    required this.post,
    required this.metrics,
    required this.isDark,
    required this.hovered,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool isDark;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final thumbSize = metrics.horizontalThumbSize;

    return Padding(
      padding: metrics.bodyPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: thumbSize,
            height: thumbSize,
            child: _MediaPreview(
              post: post,
              metrics: metrics,
              isDark: isDark,
              hovered: hovered,
              fixedSize: thumbSize,
            ),
          ),
          SizedBox(width: metrics.sectionGap + 2),
          Expanded(
            child: _CardContent(
              post: post,
              metrics: metrics,
              isDark: isDark,
              hovered: hovered,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.post,
    required this.metrics,
    required this.isDark,
    required this.hovered,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool isDark;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuthorRow(
          post: post,
          isDark: isDark,
          metrics: metrics,
        ),
        SizedBox(height: metrics.sectionGap),
        _CategoryStatusRow(post: post, metrics: metrics),
        SizedBox(height: metrics.sectionGap),
        PostListMetaRow(
          post: post,
          metrics: metrics,
          hovered: hovered,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Media preview
// ─────────────────────────────────────────────────────────────

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.post,
    required this.metrics,
    required this.isDark,
    required this.hovered,
    this.fixedSize,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool isDark;
  final bool hovered;
  final double? fixedSize;

  String? get _mediaUrl => post.previewThumbnailUrl;
  bool get _isVideo => post.containsVideoMedia;
  bool get _isCarousel => post.type.toUpperCase() == 'CAROUSEL';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mediaUrl = _mediaUrl;
    final compact = metrics.compact;

    final media = Stack(
      fit: StackFit.expand,
      children: [
        if (mediaUrl != null && mediaUrl.isNotEmpty)
          PostListThumbnail(
            key: ValueKey('post_thumb_${post.id}_$mediaUrl'),
            postId: post.id,
            imageUrl: mediaUrl,
            fit: BoxFit.cover,
            placeholder: (context) => _ShimmerBox(isDark: isDark),
            error: (context) =>
                _MediaPlaceholder(isDark: isDark, isVideo: _isVideo),
          )
        else
          _MediaPlaceholder(isDark: isDark, isVideo: _isVideo),
        IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.scrim.withValues(alpha: hovered ? 0.08 : 0.04),
                  Colors.transparent,
                  Colors.transparent,
                  scheme.scrim.withValues(
                    alpha: hovered ? 0.28 : 0.18,
                  ),
                ],
                stops: const [0, 0.35, 0.65, 1],
              ),
            ),
          ),
        ),
        if (_isVideo) Center(child: _GlassPlayBadge(compact: compact)),
        if (_isCarousel)
          Positioned(
            top: compact ? 6 : 7,
            right: compact ? 6 : 7,
            child: const _GlassMediaBadge(icon: Icons.collections_rounded),
          ),
      ],
    );

    if (fixedSize != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(metrics.compact ? 8 : 10),
        child: media,
      );
    }

    return AspectRatio(
      aspectRatio: metrics.thumbnailAspect,
      child: media,
    );
  }
}

class _GlassPlayBadge extends StatelessWidget {
  const _GlassPlayBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = compact ? 34.0 : 38.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface.withValues(alpha: 0.28),
        border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: scheme.scrim.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: scheme.onPrimary,
        size: compact ? 20 : 22,
      ),
    );
  }
}

class _GlassMediaBadge extends StatelessWidget {
  const _GlassMediaBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: scheme.scrim.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, color: scheme.onPrimary, size: 12),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.isDark, this.isVideo = false});

  final bool isDark;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_outlined : Icons.image_outlined,
          size: 32,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Author
// ─────────────────────────────────────────────────────────────

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.post,
    required this.isDark,
    required this.metrics,
  });

  final ManagedPostEntity post;
  final bool isDark;
  final PostCardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = postDisplayAuthor(post);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          url: post.userProfileImage,
          name: name,
          isDark: isDark,
          radius: metrics.avatarRadius,
          fontSize: metrics.compact ? 10 : 11,
        ),
        SizedBox(width: metrics.compact ? 5 : 6),
        Expanded(
          child: Text(
            name,
            maxLines: metrics.isHorizontal ? 2 : (metrics.narrow ? 2 : 1),
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: metrics.authorFontSize,
              height: 1.2,
              letterSpacing: -0.1,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.name,
    required this.isDark,
    required this.radius,
    required this.fontSize,
  });

  final String? url;
  final String name;
  final bool isDark;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: url != null && url!.isNotEmpty
          ? CircleAvatar(
              radius: radius,
              backgroundImage: CachedNetworkImageProvider(url!),
              backgroundColor: scheme.surfaceContainerHighest,
            )
          : CircleAvatar(
              radius: radius,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category | Status
// ─────────────────────────────────────────────────────────────

class _CategoryStatusRow extends StatelessWidget {
  const _CategoryStatusRow({required this.post, required this.metrics});

  final ManagedPostEntity post;
  final PostCardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: metrics.compact ? 4 : 6,
      runSpacing: metrics.compact ? 3 : 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (post.categoryEntity != null || post.category != null)
          _CategoryBadge(
            category: post.categoryEntity,
            fallbackName: post.category,
            fontSize: metrics.badgeFontSize,
          ),
        _StatusBadge(status: post.status, fontSize: metrics.badgeFontSize),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.fontSize});

  final String status;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fg = postStatusColor(status, scheme);
    final label = postStatusLabel(l10n, status);
    final icon = postStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize < 10 ? 6 : 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 1, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    this.category,
    this.fallbackName,
    required this.fontSize,
  });

  final CategoryEntity? category;
  final String? fallbackName;
  final double fontSize;

  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
  ];

  Color _colorFor(String key) {
    final idx = key.codeUnits.fold(0, (a, b) => a + b) % _palette.length;
    return _palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = category?.name ?? fallbackName ?? l10n.t('uncategorized');
    final slug = category?.slug ?? name.toLowerCase();
    final color = _colorFor(slug);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize < 10 ? 6 : 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryIcon(
            category: category,
            iconUrl: category?.iconUrl,
            name: name,
            size: fontSize + 4,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: color.withValues(alpha: 0.15),
            iconColor: color,
            fallbackIcon: Icons.label_outline_rounded,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.isDark});

  final bool isDark;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerLow;
    final highlight = scheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value * 2, 0),
            end: Alignment(-1 + _anim.value * 2 + 1, 0),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key, this.metrics});

  final PostCardMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolved = metrics ??
            PostCardMetrics(
              cardWidth: constraints.maxWidth,
              deviceType: getPostsDeviceType(
                MediaQuery.sizeOf(context).width,
              ),
              columns: postsGridColumnCount(
                MediaQuery.sizeOf(context).width,
              ),
            );
        return _PostCardSkeletonBody(metrics: resolved);
      },
    );
  }
}

class _PostCardSkeletonBody extends StatelessWidget {
  const _PostCardSkeletonBody({required this.metrics});

  final PostCardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = scheme.surfaceContainerLow;

    if (metrics.isHorizontal) {
      final thumb = metrics.horizontalThumbSize;
      return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(metrics.borderRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        padding: metrics.bodyPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: thumb,
              height: thumb,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(width: metrics.sectionGap + 2),
            Expanded(
              child: _SkeletonContent(base: base, metrics: metrics),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(metrics.borderRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: metrics.thumbnailAspect,
            child: _ShimmerBox(isDark: isDark),
          ),
          Padding(
            padding: metrics.bodyPadding,
            child: _SkeletonContent(base: base, metrics: metrics),
          ),
        ],
      ),
    );
  }
}

class _SkeletonContent extends StatelessWidget {
  const _SkeletonContent({required this.base, required this.metrics});

  final Color base;
  final PostCardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: metrics.avatarRadius, backgroundColor: base),
            SizedBox(width: metrics.compact ? 5 : 6),
            _SkeletonLine(width: 80, height: 10, base: base),
          ],
        ),
        SizedBox(height: metrics.sectionGap),
        Row(
          children: [
            _SkeletonLine(width: 56, height: 18, base: base, radius: 8),
            SizedBox(width: metrics.compact ? 4 : 6),
            _SkeletonLine(width: 48, height: 18, base: base, radius: 8),
          ],
        ),
        SizedBox(height: metrics.sectionGap),
        _SkeletonLine(
          width: double.infinity,
          height: metrics.stackMetaRow ? 36 : 24,
          base: base,
          radius: 8,
        ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.base,
    this.radius = 4,
  });

  final double width;
  final double height;
  final Color base;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
