import 'package:flutter/material.dart';

import '../../../post_management/data/utils/managed_post_location_hydration.dart';
import '../../../post_management/domain/entities/managed_post_entity.dart';
import '../utils/post_card_layout.dart';
import '../utils/post_date_format.dart';

/// Pure-black premium palette for post card content panels.
abstract final class PostCardPremiumColors {
  static const black = Color(0xFF000000);
  static const textPrimary = Color(0xFFF5F5F4);
  static const textSecondary = Color(0xA3FFFFFF);
  static const textMuted = Color(0x66FFFFFF);
  static const accentGold = Color(0xFFC9A962);
  static const accentRose = Color(0xFFE8B4B8);
  static const borderSubtle = Color(0x14FFFFFF);
  static const borderSoft = Color(0x24FFFFFF);
  static const surfaceInset = Color(0x0FFFFFFF);
}

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
    this.premiumBlack = false,
  });

  final ManagedPostEntity post;
  final PostCardMetrics metrics;
  final bool hovered;
  final bool premiumBlack;

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

    final viewColor = premiumBlack ? PostCardPremiumColors.textSecondary : scheme.primary;
    final likeColor = premiumBlack ? PostCardPremiumColors.accentRose : scheme.error;
    final commentColor =
        premiumBlack ? PostCardPremiumColors.textSecondary : scheme.tertiary;
    final shareColor =
        premiumBlack ? PostCardPremiumColors.textMuted : scheme.secondary;

    final stats = <Widget>[
      if (metrics.showViewStat)
        _InlineStat(
          icon: Icons.visibility_outlined,
          value: _fmt(post.viewCount),
          color: viewColor,
          size: statSize,
          premiumBlack: premiumBlack,
        ),
      if (metrics.showLikeStat) ...[
        if (metrics.showViewStat) SizedBox(width: metrics.compact ? 6 : 8),
        _InlineStat(
          icon: Icons.favorite_border_rounded,
          value: _fmt(post.likeCount),
          color: likeColor,
          size: statSize,
          premiumBlack: premiumBlack,
        ),
      ],
      if (metrics.showCommentStat) ...[
        SizedBox(width: metrics.compact ? 6 : 8),
        _InlineStat(
          icon: Icons.chat_bubble_outline_rounded,
          value: _fmt(post.commentCount),
          color: commentColor,
          size: statSize,
          premiumBlack: premiumBlack,
        ),
      ],
      if (metrics.showShareStat) ...[
        SizedBox(width: metrics.compact ? 6 : 8),
        _InlineStat(
          icon: Icons.share_outlined,
          value: _fmt(post.shareCount),
          color: shareColor,
          size: statSize,
          premiumBlack: premiumBlack,
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
        letterSpacing: premiumBlack ? 0.15 : 0,
        color: premiumBlack
            ? PostCardPremiumColors.textMuted
            : scheme.onSurfaceVariant,
        height: 1.2,
      ),
    );

    final locationRow = location != null
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: metaSize + 2.5,
                  color: premiumBlack
                      ? PostCardPremiumColors.accentGold
                      : scheme.tertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: metaSize + (premiumBlack ? 0.75 : 0.5),
                      fontWeight: FontWeight.w600,
                      letterSpacing: premiumBlack ? 0.1 : 0,
                      color: premiumBlack
                          ? PostCardPremiumColors.accentGold
                          : scheme.tertiary,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
          )
        : null;

    final dateLocationRow = locationRow == null
        ? dateRow
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateRow,
              SizedBox(height: metrics.compact ? 4 : 5),
              locationRow,
            ],
          );

    final insetPadding = EdgeInsets.symmetric(
      horizontal: metrics.compact ? 8 : 10,
      vertical: metrics.compact ? 8 : 9,
    );

    final insetDecoration = BoxDecoration(
      color: premiumBlack
          ? PostCardPremiumColors.surfaceInset
          : (hovered && metrics.enableHoverEffects
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
              : scheme.surfaceContainerLowest.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(premiumBlack ? 10 : 8),
      border: Border.all(
        color: premiumBlack
            ? (hovered && metrics.enableHoverEffects
                ? PostCardPremiumColors.borderSoft
                : PostCardPremiumColors.borderSubtle)
            : scheme.outlineVariant.withValues(
                alpha: hovered && metrics.enableHoverEffects ? 0.8 : 0.55,
              ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: premiumBlack ? insetPadding : EdgeInsets.symmetric(
        vertical: metrics.compact ? 3 : 4,
        horizontal: metrics.compact ? 4 : 6,
      ),
      decoration: premiumBlack ? insetDecoration : BoxDecoration(
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
                SizedBox(height: metrics.compact ? 8 : 9),
                if (premiumBlack)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: PostCardPremiumColors.borderSubtle,
                  ),
                if (premiumBlack) SizedBox(height: metrics.compact ? 7 : 8),
                Wrap(
                  spacing: metrics.compact ? 4 : 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: stats,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: dateLocationRow),
                const SizedBox(width: 8),
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
    this.premiumBlack = false,
  });

  final IconData icon;
  final String value;
  final Color color;
  final double size;
  final bool premiumBlack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: size + (premiumBlack ? 0.5 : 1),
          color: color.withValues(alpha: premiumBlack ? 0.9 : 0.85),
        ),
        SizedBox(width: premiumBlack ? 3 : 2),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w600,
            letterSpacing: premiumBlack ? 0.2 : 0,
            color: premiumBlack ? PostCardPremiumColors.textSecondary : color,
            height: 1,
            fontFeatures: premiumBlack ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}
