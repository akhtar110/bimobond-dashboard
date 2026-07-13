import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/categories/presentation/widgets/category_icon.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../utils/posts_responsive.dart';
import 'post_list_thumbnail.dart';
import 'posts_table_view.dart';
import '../../../../features/post_management/presentation/utils/post_detail_labels.dart';

/// Fixed thumbnail height — card body grows with content below.
const double kPostCardThumbnailHeight = 176;

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
        final compact = constraints.maxWidth < 220;
        final bodyPadding = compact ? 6.0 : 8.0;
        final descFontSize = compact ? 11.5 : 12.5;

        return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: _hovered
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(
                  alpha: _hovered ? 0.08 : 0.03,
                ),
                blurRadius: _hovered ? 14 : 8,
                offset: Offset(0, _hovered ? 4 : 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _MediaPreview(
                post: widget.post,
                cardWidth: constraints.maxWidth,
              ),
              Padding(
                padding: EdgeInsets.all(bodyPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UserDateRow(post: widget.post, isDark: isDark, compact: compact),
                    if (widget.post.description != null &&
                        widget.post.description!.isNotEmpty) ...[
                      SizedBox(height: compact ? 4 : 6),
                      Text(
                        widget.post.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface,
                          height: 1.35,
                          fontSize: descFontSize,
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 4 : 6),
                    _CategoryStatusRow(post: widget.post, compact: compact),
                    SizedBox(height: compact ? 4 : 6),
                    _StatsRow(post: widget.post, isDark: isDark, compact: compact),
                  ],
                ),
              ),
            ],
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
  const _MediaPreview({required this.post, required this.cardWidth});

  final ManagedPostEntity post;
  final double cardWidth;

  String? get _mediaUrl => post.previewThumbnailUrl;
  bool get _isVideo => post.containsVideoMedia;
  bool get _isCarousel => post.type.toUpperCase() == 'CAROUSEL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaUrl = _mediaUrl;

    return SizedBox(
      height: postCardThumbnailHeight(cardWidth),
      width: double.infinity,
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
          if (_isVideo)
            Center(
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.scrim.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: scheme.onPrimary,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
          if (_isCarousel)
            Positioned(
              top: 6,
              right: 6,
              child: Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.scrim.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.collections_outlined,
                      color: scheme.onPrimary,
                      size: 12,
                    ),
                  );
                },
              ),
            ),
        ],
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
    final nameSize = compact ? 11.0 : 12.0;
    final dateSize = compact ? 9.5 : 10.5;

    return Row(
      children: [
        _Avatar(url: post.userProfileImage, name: name, isDark: isDark, compact: compact),
        SizedBox(width: compact ? 5 : 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: nameSize,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: TextStyle(fontSize: dateSize, color: scheme.onSurfaceVariant),
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
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(url!),
        backgroundColor: scheme.surfaceContainerHighest,
      );
    }
    return CircleAvatar(
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
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
  });

  final ManagedPostEntity post;

  /// Retained for hot-reload compatibility; styling uses [ColorScheme] from context.
  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurfaceVariant;

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.visibility_outlined,
              value: post.viewCount,
              color: color,
            ),
          ),
          Expanded(
            child: _Stat(
              icon: Icons.favorite_border,
              value: post.likeCount,
              color: color,
            ),
          ),
          Expanded(
            child: _Stat(
              icon: Icons.chat_bubble_outline,
              value: post.commentCount,
              color: color,
            ),
          ),
          Expanded(
            child: _Stat(
              icon: Icons.share_outlined,
              value: post.shareCount,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          _format(value),
          style: TextStyle(
            fontSize: 10.5,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kPostCardThumbnailHeight,
            child: _ShimmerBox(isDark: isDark),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
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
                const SizedBox(height: 8),
                _SkeletonLine(width: double.infinity, height: 9, base: base),
                const SizedBox(height: 4),
                _SkeletonLine(width: 120, height: 9, base: base),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SkeletonLine(width: 56, height: 18, base: base, radius: 20),
                    const SizedBox(width: 6),
                    _SkeletonLine(width: 48, height: 18, base: base, radius: 20),
                  ],
                ),
                const SizedBox(height: 8),
                _SkeletonLine(width: double.infinity, height: 20, base: base),
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
