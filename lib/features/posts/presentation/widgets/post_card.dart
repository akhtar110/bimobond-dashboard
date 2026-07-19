import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/categories/presentation/widgets/category_icon.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../../../features/post_management/presentation/utils/post_detail_labels.dart';
import 'post_list_thumbnail.dart';
import 'posts_table_view.dart';

/// Compact thumbnail aspect — wider than tall so cards stay shorter.
const double kPostCardThumbnailAspectCompact = 1.65;
const double kPostCardThumbnailAspect = 1.75;

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, this.onTap});

  final ManagedPostEntity post;
  final VoidCallback? onTap;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 170;
        final bodyPadding = compact ? 6.0 : 8.0;
        final radius = compact ? 10.0 : 12.0;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _hovered ? 1.01 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _hovered ? const Offset(0, -0.012) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: _hovered
                          ? scheme.primary.withValues(alpha: 0.42)
                          : scheme.outlineVariant.withValues(alpha: 0.85),
                      width: _hovered ? 1.2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(
                          alpha: _hovered
                              ? (isDark ? 0.45 : 0.12)
                              : (isDark ? 0.28 : 0.05),
                        ),
                        blurRadius: _hovered ? 18 : 10,
                        spreadRadius: _hovered ? 0.5 : 0,
                        offset: Offset(0, _hovered ? 8 : 3),
                      ),
                      if (_hovered)
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MediaPreview(
                          post: widget.post,
                          compact: compact,
                          hovered: _hovered,
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            bodyPadding,
                            compact ? 5 : 6,
                            bodyPadding,
                            bodyPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _UserDateRow(
                                post: widget.post,
                                isDark: isDark,
                                compact: compact,
                              ),
                              SizedBox(height: compact ? 4 : 5),
                              _CategoryStatusRow(
                                post: widget.post,
                                compact: compact,
                              ),
                              SizedBox(height: compact ? 4 : 5),
                              _StatsRow(
                                post: widget.post,
                                isDark: isDark,
                                compact: compact,
                                hovered: _hovered,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Media preview
// ─────────────────────────────────────────────────────────────

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.post,
    required this.compact,
    required this.hovered,
  });

  final ManagedPostEntity post;
  final bool compact;
  final bool hovered;

  String? get _mediaUrl => post.previewThumbnailUrl;
  bool get _isVideo => post.containsVideoMedia;
  bool get _isCarousel => post.type.toUpperCase() == 'CAROUSEL';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaUrl = _mediaUrl;

    return AspectRatio(
      aspectRatio:
          compact ? kPostCardThumbnailAspectCompact : kPostCardThumbnailAspect,
      child: Stack(
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
          // Subtle readability gradient
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
                    scheme.scrim.withValues(alpha: hovered ? 0.28 : 0.18),
                  ],
                  stops: const [0, 0.35, 0.65, 1],
                ),
              ),
            ),
          ),
          if (_isVideo)
            Center(
              child: _GlassPlayBadge(compact: compact),
            ),
          if (_isCarousel)
            Positioned(
              top: compact ? 6 : 7,
              right: compact ? 6 : 7,
              child: const _GlassMediaBadge(
                icon: Icons.collections_rounded,
              ),
            ),
        ],
      ),
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
        border: Border.all(
          color: scheme.onPrimary.withValues(alpha: 0.55),
        ),
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
        border: Border.all(
          color: scheme.onPrimary.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.scrim.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: scheme.onPrimary,
        size: 12,
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.isDark, this.isVideo = false});

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
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
// User + date
// ─────────────────────────────────────────────────────────────

class _UserDateRow extends StatelessWidget {
  const _UserDateRow({
    required this.post,
    required this.isDark,
    this.compact = false,
  });

  final ManagedPostEntity post;

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = postDisplayAuthor(post);
    final dateStr = DateFormat('MMM d, yyyy').format(post.createdAt);
    final nameSize = compact ? 10.5 : 11.5;
    final dateSize = compact ? 9.0 : 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          url: post.userProfileImage,
          name: name,
          isDark: isDark,
          compact: compact,
        ),
        SizedBox(width: compact ? 5 : 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: nameSize,
                      height: 1.2,
                      letterSpacing: -0.1,
                      color: scheme.onSurface,
                    ),
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dateSize,
                  color: scheme.onSurfaceVariant,
                  height: 1.1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    this.compact = false,
  });

  final String? url;
  final String name;

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = compact ? 12.0 : 14.0;

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.22),
        ),
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
                  fontSize: compact ? 10 : 11,
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
  const _CategoryStatusRow({required this.post, this.compact = false});

  final ManagedPostEntity post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: compact ? 3 : 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (post.categoryEntity != null || post.category != null)
          _CategoryBadge(
            category: post.categoryEntity,
            fallbackName: post.category,
          ),
        _StatusBadge(status: post.status),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fg = postStatusColor(status, scheme);
    final label = postStatusLabel(l10n, status);
    final icon = postStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
  const _CategoryBadge({this.category, this.fallbackName});

  final CategoryEntity? category;
  final String? fallbackName;

  // Brand accent palette — intentionally not from ColorScheme so categories
  // remain visually distinct regardless of the active theme.
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            size: 14,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: color.withValues(alpha: 0.15),
            iconColor: color,
            fallbackIcon: Icons.label_outline_rounded,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats
// ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.post,
    required this.isDark,
    this.compact = false,
    this.hovered = false,
  });

  final ManagedPostEntity post;

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
  final bool isDark;
  final bool compact;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        vertical: compact ? 3 : 4,
        horizontal: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: hovered
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : scheme.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: hovered ? 0.8 : 0.55),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.visibility_outlined,
              value: post.viewCount,
              accent: scheme.primary,
              compact: compact,
            ),
          ),
          Expanded(
            child: _StatChip(
              icon: Icons.favorite_border_rounded,
              value: post.likeCount,
              accent: scheme.error,
              compact: compact,
            ),
          ),
          Expanded(
            child: _StatChip(
              icon: Icons.chat_bubble_outline_rounded,
              value: post.commentCount,
              accent: scheme.tertiary,
              compact: compact,
            ),
          ),
          Expanded(
            child: _StatChip(
              icon: Icons.share_outlined,
              value: post.shareCount,
              accent: scheme.secondary,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  final IconData icon;
  final int value;
  final Color accent;
  final bool compact;

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 3 : 4,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11 : 12, color: accent),
            SizedBox(width: compact ? 2 : 3),
            Flexible(
              child: Text(
                _format(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 9.5 : 10.5,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.isDark});

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
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
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = scheme.surfaceContainerLow;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
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
            aspectRatio: kPostCardThumbnailAspect,
            child: _ShimmerBox(isDark: isDark),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: base),
                    const SizedBox(width: 6),
                    _SkeletonLine(width: 80, height: 10, base: base),
                    const Spacer(),
                    _SkeletonLine(width: 52, height: 8, base: base),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _SkeletonLine(width: 56, height: 18, base: base, radius: 8),
                    const SizedBox(width: 6),
                    _SkeletonLine(width: 48, height: 18, base: base, radius: 8),
                  ],
                ),
                const SizedBox(height: 6),
                _SkeletonLine(width: double.infinity, height: 24, base: base, radius: 8),
              ],
            ),
          ),
        ],
      ),
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
