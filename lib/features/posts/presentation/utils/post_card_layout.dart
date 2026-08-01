import 'package:flutter/material.dart';

import 'posts_page_layout.dart';
import 'posts_responsive.dart';

/// Vertical grid card vs. horizontal list-style card on mobile.
enum PostCardLayoutMode { vertical, horizontal }

/// Responsive sizing derived from card column width and viewport type.
class PostCardMetrics {
  const PostCardMetrics({
    required this.cardWidth,
    required this.deviceType,
    required this.columns,
  });

  final double cardWidth;
  final PostsDeviceType deviceType;
  final int columns;

  factory PostCardMetrics.fromViewport({
    required double viewportWidth,
    double horizontalPadding = 0,
    double gap = 12,
  }) {
    final deviceType = getPostsDeviceType(viewportWidth);
    final columns = postsGridColumnCount(viewportWidth);
    final available = viewportWidth - (horizontalPadding * 2);
    final cardWidth = columns <= 1
        ? available
        : (available - (gap * (columns - 1))) / columns;
    return PostCardMetrics(
      cardWidth: cardWidth,
      deviceType: deviceType,
      columns: columns,
    );
  }

  bool get isMobile =>
      deviceType == PostsDeviceType.mobileSmall ||
      deviceType == PostsDeviceType.mobileLarge;

  bool get isTablet => deviceType == PostsDeviceType.tablet;

  /// Full-width mobile cards use a horizontal media + content split.
  PostCardLayoutMode get layoutMode {
    if (isMobile && columns == 1 && cardWidth >= 280) {
      return PostCardLayoutMode.horizontal;
    }
    return PostCardLayoutMode.vertical;
  }

  bool get isHorizontal => layoutMode == PostCardLayoutMode.horizontal;

  bool get narrow => cardWidth < 170;
  bool get compact => cardWidth < 210;
  bool get dense => cardWidth < 260;

  /// Stack date/location above engagement stats when space is tight.
  bool get stackMetaRow => cardWidth < 300 || isHorizontal;

  bool get showLocationInMeta => true;
  bool get showShareStat => cardWidth >= 150;
  bool get showCommentStat => cardWidth >= 120;
  bool get showViewStat => true;
  bool get showLikeStat => true;

  bool get enableHoverEffects => !isMobile;

  double get borderRadius =>
      narrow ? 10 : (compact ? 11 : (isMobile ? 12 : 14));

  EdgeInsets get bodyPadding => EdgeInsets.fromLTRB(
        _padH,
        isHorizontal ? _padV : (narrow ? 5 : 6),
        _padH,
        _padV,
      );

  double get _padH => narrow ? 6 : (compact ? 8 : (isMobile ? 10 : 12));
  double get _padV => narrow ? 6 : (compact ? 7 : (isMobile ? 10 : 8));

  double get sectionGap => narrow ? 3 : (compact ? 4 : (isMobile ? 6 : 5));

  double get thumbnailAspect => switch (layoutMode) {
        PostCardLayoutMode.horizontal => 1,
        PostCardLayoutMode.vertical => narrow
            ? 1.55
            : compact
                ? 1.62
                : dense
                    ? 1.68
                    : 1.75,
      };

  double get horizontalThumbSize =>
      (cardWidth * 0.27).clamp(isMobile ? 96.0 : 88.0, 132.0);

  double get authorFontSize =>
      narrow ? 10.5 : (compact ? 11 : (isMobile ? 13 : 12));

  double get avatarRadius =>
      narrow ? 11 : (compact ? 12 : (isMobile && isHorizontal ? 17 : 14));

  double get metaFontSize =>
      narrow ? 8.5 : (compact ? 9 : (isMobile ? 11 : 10));

  double get statFontSize =>
      narrow ? 8.5 : (compact ? 9 : (isMobile ? 10.5 : 10));

  double get badgeFontSize => narrow ? 9 : 10;

  EdgeInsets get premiumBodyPadding => EdgeInsets.fromLTRB(
        narrow ? 10 : (compact ? 12 : 14),
        narrow ? 8 : (compact ? 9 : 10),
        narrow ? 10 : (compact ? 12 : 14),
        narrow ? 11 : (compact ? 12 : 14),
      );

  /// Overlap of the black footer into the media fade zone.
  double get premiumBlendOverlap =>
      narrow ? 16 : (compact ? 18 : (dense ? 20 : 24));

  /// Avatar overlap between media and info section (premium vertical cards).
  double get premiumAvatarOverlap =>
      narrow ? 12 : (compact ? 14 : 16);

  int get thumbnailCacheWidth =>
      (cardWidth * (isHorizontal ? 0.35 : 1.0)).round().clamp(80, 560);
}
