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

  bool get isDesktop => deviceType == PostsDeviceType.desktop;

  /// Wide cards on large monitors — slightly roomier typography/avatar.
  bool get isWideCard => cardWidth >= 340;

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
  bool get showReportStat => cardWidth >= 120;

  bool get enableHoverEffects => !isMobile;

  double get borderRadius =>
      narrow ? 10 : (compact ? 11 : (isMobile ? 12 : 14));

  EdgeInsets get bodyPadding => EdgeInsets.fromLTRB(
        _padH,
        isHorizontal ? _padV : (narrow ? 4 : 5),
        _padH,
        _padV,
      );

  double get _padH => narrow ? 6 : (compact ? 8 : (isMobile ? 10 : 12));
  double get _padV => narrow ? 5 : (compact ? 6 : (isMobile ? 8 : 7));

  double get sectionGap => narrow ? 2 : (compact ? 2 : (isMobile ? 4 : 3));

  /// Gap between author, badges, and meta sections in the overlay panel.
  double get contentSectionGap => sectionGap;

  /// Full-card aspect (width / height). Higher = shorter card.
  double get thumbnailAspect => switch (layoutMode) {
        PostCardLayoutMode.horizontal => isMobile ? 1.58 : 1.48,
        PostCardLayoutMode.vertical => narrow
            ? 0.96
            : compact
                ? 0.92
                : dense
                    ? 0.88
                    : isWideCard
                        ? 0.84
                        : 0.86,
      };

  double get horizontalThumbSize =>
      (cardWidth * 0.27).clamp(isMobile ? 96.0 : 88.0, 132.0);

  double get authorFontSize => narrow
      ? 10
      : (compact ? 10.5 : (isMobile ? 12.5 : (isWideCard ? 12 : 11.5)));

  double get authorLineHeight => 1.18;

  double get avatarRadius => narrow
      ? 10
      : (compact
          ? 11
          : (isMobile && isHorizontal
              ? 16
              : (isWideCard ? 14 : (isTablet ? 11 : 12))));

  double get avatarFontSize => narrow ? 9 : (compact ? 9.5 : 10.5);

  double get avatarRingPadding => 1.2;

  double get authorAvatarGap => narrow ? 6 : (compact ? 7 : 8);

  double get metaFontSize =>
      narrow ? 8 : (compact ? 8.5 : (isMobile ? 10.5 : (isWideCard ? 10 : 9.5)));

  double get statFontSize =>
      narrow ? 8 : (compact ? 8.5 : (isMobile ? 10 : (isWideCard ? 10 : 9.5)));

  double get badgeFontSize => narrow ? 8.5 : (compact ? 9 : 9.5);

  double get badgeWrapSpacing => narrow ? 4 : (compact ? 5 : 6);

  double get badgeWrapRunSpacing => narrow ? 3 : 4;

  EdgeInsets get badgePadding => EdgeInsets.symmetric(
        horizontal: narrow ? 6 : (compact ? 7 : 8),
        vertical: narrow ? 2.5 : 3,
      );

  double get badgeIconGap => 3;

  double get badgeBorderRadius => narrow ? 16 : (compact ? 18 : 20);

  double get categoryIconSize => badgeFontSize + 3;

  double get statusIconSize => badgeFontSize + 0.5;

  /// Bottom gradient height as a fraction of card height.
  double get overlayGradientHeightFactor =>
      narrow ? 0.50 : (compact ? 0.52 : 0.54);

  double get mediaBadgeInset => narrow ? 6 : (compact ? 7 : 8);

  double get playBadgeSize => narrow ? 30 : (compact ? 32 : 34);

  double get playBadgeIconSize => playBadgeSize * 0.58;

  EdgeInsets get glassMediaBadgePadding => EdgeInsets.symmetric(
        horizontal: narrow ? 5 : 6,
        vertical: narrow ? 2 : 2.5,
      );

  double get glassMediaBadgeIconSize => narrow ? 11 : 12;

  double get glassMediaBadgeRadius => narrow ? 7 : 8;

  /// Padding for the bottom details band.
  EdgeInsets get premiumBodyPadding => EdgeInsets.fromLTRB(
        narrow ? 8 : (compact ? 10 : (isWideCard ? 12 : 11)),
        narrow ? 5 : (compact ? 5 : 6),
        narrow ? 8 : (compact ? 10 : (isWideCard ? 12 : 11)),
        narrow ? 8 : (compact ? 9 : (isWideCard ? 11 : 10)),
      );

  EdgeInsets get metaInsetPadding => EdgeInsets.symmetric(
        horizontal: narrow ? 6 : (compact ? 7 : 8),
        vertical: narrow ? 5 : (compact ? 6 : 7),
      );

  double get metaDateLocationGap => narrow ? 2 : 3;

  double get metaStackGap => narrow ? 5 : 6;

  double get metaDividerGap => narrow ? 4 : 5;

  double get metaStatSpacing => narrow ? 4 : (compact ? 5 : 6);

  double get metaStatRunSpacing => 3;

  double get metaRowInlineGap => narrow ? 6 : 7;

  double get locationRowVerticalPadding => 1;

  double get locationIconSizeOffset => narrow ? 2 : 2.5;

  double get locationFontSizeOffset => narrow ? 0.5 : 0.75;

  double get metaInlineStatIconGap => 2;

  /// Non-premium meta container padding.
  EdgeInsets get metaContainerPadding => EdgeInsets.symmetric(
        vertical: narrow ? 2 : 3,
        horizontal: narrow ? 3 : (compact ? 4 : 5),
      );

  int get thumbnailCacheWidth =>
      (cardWidth * 1.0).round().clamp(80, 560);
}
