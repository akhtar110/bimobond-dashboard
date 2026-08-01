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
        color: PostCardPremiumColors.black,
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
        child: _MediaOverlayCardBody(
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

/// Image fills the whole card; details sit at the bottom over a bottom-up gradient.
class _MediaOverlayCardBody extends StatelessWidget {
  const _MediaOverlayCardBody({
    required this.post,
    required this.metrics,
    required this.isDark,
    required this.hovered,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool isDark;
  final bool hovered;

  String? get _mediaUrl => post.previewThumbnailUrl;
  bool get _isVideo => post.containsVideoMedia;
  bool get _isCarousel => post.type.toUpperCase() == 'CAROUSEL';

  @override
  Widget build(BuildContext context) {
    final mediaUrl = _mediaUrl;
    final compact = metrics.compact;

    return AspectRatio(
      aspectRatio: metrics.thumbnailAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: PostCardPremiumColors.black),
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

          // Gradient rising from the bottom up through the author name
          const Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 1,
              heightFactor: 0.58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xF2000000),
                      Color(0xCC000000),
                      Color(0x80000000),
                      Color(0x33000000),
                      Color(0x00000000),
                    ],
                    stops: [0.0, 0.28, 0.52, 0.78, 1.0],
                  ),
                ),
              ),
            ),
          ),

          if (_isVideo) Center(child: _GlassPlayBadge(compact: compact)),
          if (_isCarousel)
            Positioned(
              top: compact ? 8 : 10,
              right: compact ? 8 : 10,
              child: const _GlassMediaBadge(icon: Icons.collections_rounded),
            ),

          // Details pinned to the bottom over the gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
    return Padding(
      padding: metrics.premiumBodyPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AuthorRow(
            post: post,
            isDark: isDark,
            metrics: metrics,
            premiumBlack: true,
          ),
          SizedBox(height: metrics.sectionGap + 2),
          _CategoryStatusRow(
            post: post,
            metrics: metrics,
            premiumBlack: true,
          ),
          SizedBox(height: metrics.sectionGap + 2),
          PostListMetaRow(
            post: post,
            metrics: metrics,
            hovered: hovered,
            premiumBlack: true,
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
    return ColoredBox(
      color: isDark ? const Color(0xFF141414) : const Color(0xFF1A1A1A),
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_outlined : Icons.image_outlined,
          size: 36,
          color: PostCardPremiumColors.textMuted,
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
    this.premiumBlack = false,
  });

  final ManagedPostEntity post;
  final bool isDark;
  final PostCardMetrics metrics;
  final bool premiumBlack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = postDisplayAuthor(post);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(
          url: post.userProfileImage,
          name: name,
          isDark: isDark,
          radius: metrics.avatarRadius,
          fontSize: metrics.compact ? 10 : 11,
          premiumBlack: premiumBlack,
        ),
        SizedBox(width: metrics.compact ? 8 : 10),
        Expanded(
          child: Text(
            name,
            maxLines: metrics.narrow || metrics.isHorizontal ? 2 : 1,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: metrics.authorFontSize + (premiumBlack ? 0.5 : 0),
              height: 1.25,
              letterSpacing: premiumBlack ? 0.15 : -0.1,
              color: premiumBlack
                  ? PostCardPremiumColors.textPrimary
                  : scheme.onSurface,
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
    this.premiumBlack = false,
  });

  final String? url;
  final String name;
  final bool isDark;
  final double radius;
  final double fontSize;
  final bool premiumBlack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColor = premiumBlack
        ? PostCardPremiumColors.accentGold.withValues(alpha: 0.55)
        : scheme.primary.withValues(alpha: 0.22);

    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: premiumBlack ? 1.2 : 1),
        boxShadow: premiumBlack
            ? [
                BoxShadow(
                  color: PostCardPremiumColors.accentGold.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
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
              backgroundColor: premiumBlack
                  ? const Color(0xFF1A1A1A)
                  : scheme.surfaceContainerHighest,
            )
          : CircleAvatar(
              radius: radius,
              backgroundColor: premiumBlack
                  ? const Color(0xFF1A1A1A)
                  : scheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: premiumBlack
                      ? PostCardPremiumColors.accentGold
                      : scheme.onPrimaryContainer,
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
  const _CategoryStatusRow({
    required this.post,
    required this.metrics,
    this.premiumBlack = false,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool premiumBlack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: metrics.compact ? 6 : 8,
      runSpacing: metrics.compact ? 4 : 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (post.categoryEntity != null || post.category != null)
          _CategoryBadge(
            category: post.categoryEntity,
            fallbackName: post.category,
            fontSize: metrics.badgeFontSize,
            premiumBlack: premiumBlack,
          ),
        _StatusBadge(
          status: post.status,
          fontSize: metrics.badgeFontSize,
          premiumBlack: premiumBlack,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.fontSize,
    this.premiumBlack = false,
  });

  final String status;
  final double fontSize;
  final bool premiumBlack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fg = postStatusColor(status, scheme);
    final label = postStatusLabel(l10n, status);
    final icon = postStatusIcon(status);
    final displayColor =
        premiumBlack ? PostCardPremiumColors.accentGold : fg;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize < 10 ? 7 : 8,
        vertical: premiumBlack ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: premiumBlack
            ? displayColor.withValues(alpha: 0.1)
            : fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(premiumBlack ? 20 : 8),
        border: Border.all(
          color: premiumBlack
              ? displayColor.withValues(alpha: 0.38)
              : fg.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 1, color: displayColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: displayColor,
              letterSpacing: premiumBlack ? 0.25 : 0.1,
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
    this.premiumBlack = false,
  });

  final CategoryEntity? category;
  final String? fallbackName;
  final double fontSize;
  final bool premiumBlack;

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
    final displayColor =
        premiumBlack ? PostCardPremiumColors.textSecondary : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize < 10 ? 7 : 8,
        vertical: premiumBlack ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: premiumBlack
            ? PostCardPremiumColors.surfaceInset
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(premiumBlack ? 20 : 8),
        border: Border.all(
          color: premiumBlack
              ? PostCardPremiumColors.borderSoft
              : color.withValues(alpha: 0.26),
        ),
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
            backgroundColor: premiumBlack
                ? PostCardPremiumColors.borderSubtle
                : color.withValues(alpha: 0.15),
            iconColor: displayColor,
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
                fontWeight: FontWeight.w500,
                letterSpacing: premiumBlack ? 0.15 : 0,
                color: displayColor,
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
      child: AspectRatio(
        aspectRatio: metrics.thumbnailAspect,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ShimmerBox(isDark: isDark),
            const Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 0.58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xF2000000),
                        Color(0xCC000000),
                        Color(0x80000000),
                        Color(0x33000000),
                        Color(0x00000000),
                      ],
                      stops: [0.0, 0.28, 0.52, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: metrics.premiumBodyPadding,
                child: _SkeletonContent(
                  base: const Color(0xFF1A1A1A),
                  metrics: metrics,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonContent extends StatelessWidget {
  const _SkeletonContent({
    required this.base,
    required this.metrics,
  });

  final Color base;
  final PostCardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
