import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0);

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
            color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark
                      ? (_hovered ? 0.28 : 0.12)
                      : (_hovered ? 0.08 : 0.03),
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
              _MediaPreview(post: widget.post),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UserDateRow(post: widget.post, isDark: isDark),
                    if (widget.post.description != null &&
                        widget.post.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.post.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.grey.shade300
                              : const Color(0xFF374151),
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _CategoryStatusRow(post: widget.post),
                    const SizedBox(height: 6),
                    _StatsRow(post: widget.post, isDark: isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Media preview
// ─────────────────────────────────────────────────────────────

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.post});

  final ManagedPostEntity post;

  String? get _mediaUrl => post.displayThumbnailUrl ?? post.videoUrl;
  bool get _isVideo => post.type.toUpperCase() == 'VIDEO';
  bool get _isCarousel => post.type.toUpperCase() == 'CAROUSEL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: kPostCardThumbnailHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_mediaUrl != null && _mediaUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _mediaUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => _ShimmerBox(isDark: isDark),
              errorWidget: (context, url, error) =>
                  _MediaPlaceholder(isDark: isDark),
            )
          else
            _MediaPlaceholder(isDark: isDark),
          if (_isVideo)
            Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          if (_isCarousel)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.collections_outlined,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? const Color(0xFF252B3B) : const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// User + date
// ─────────────────────────────────────────────────────────────

class _UserDateRow extends StatelessWidget {
  const _UserDateRow({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final name = post.userName ?? post.userId;
    final dateStr = DateFormat('MMM d, yyyy').format(post.createdAt);
    final metaColor =
        isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF);

    return Row(
      children: [
        _Avatar(url: post.userProfileImage, name: name, isDark: isDark),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isDark ? Colors.grey.shade200 : const Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: TextStyle(fontSize: 10.5, color: metaColor),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.isDark});

  final String? url;
  final String name;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: CachedNetworkImageProvider(url!),
        backgroundColor:
            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category | Status
// ─────────────────────────────────────────────────────────────

class _CategoryStatusRow extends StatelessWidget {
  const _CategoryStatusRow({required this.post});

  final ManagedPostEntity post;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
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
    final (bg, fg, label) = switch (status.toUpperCase()) {
      'PUBLISHED' => (
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        l10n.t('postStatusPublished'),
      ),
      'BANNED' => (
        const Color(0xFFFFEBEE),
        const Color(0xFFC62828),
        l10n.t('postStatusBanned'),
      ),
      'DRAFT' => (
        const Color(0xFFFFF8E1),
        const Color(0xFFF9A825),
        l10n.t('postStatusDraft'),
      ),
      'HIDDEN' => (
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        l10n.t('postStatusHidden'),
      ),
      'UNDER_REVIEW' => (
        const Color(0xFFE3F2FD),
        const Color(0xFF1565C0),
        l10n.t('postStatusUnderReview'),
      ),
      _ => (
        const Color(0xFFF3F4F6),
        const Color(0xFF6B7280),
        status,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({this.category, this.fallbackName});

  final CategoryEntity? category;
  final String? fallbackName;

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
          Icon(Icons.label_outline_rounded, size: 10, color: color),
          const SizedBox(width: 3),
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
  const _StatsRow({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF);
    final divider = isDark ? Colors.grey.shade800 : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: divider)),
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
          style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w500),
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
    final base =
        widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5);
    final highlight =
        widget.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    final borderColor =
        isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
