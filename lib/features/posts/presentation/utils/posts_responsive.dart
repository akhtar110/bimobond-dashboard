import 'package:flutter/material.dart';

/// Breakpoints and layout helpers for the posts feed.
enum PostsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

PostsDeviceType getPostsDeviceType(double width) {
  if (width < 480) return PostsDeviceType.mobileSmall;
  if (width < 700) return PostsDeviceType.mobileLarge;
  if (width < 1200) return PostsDeviceType.tablet;
  return PostsDeviceType.desktop;
}

class PostsLayoutMetrics {
  const PostsLayoutMetrics(this.deviceType);

  final PostsDeviceType deviceType;

  bool get isMobile =>
      deviceType == PostsDeviceType.mobileSmall ||
      deviceType == PostsDeviceType.mobileLarge;

  double get pageHorizontalPadding => switch (deviceType) {
        PostsDeviceType.mobileSmall => 8,
        PostsDeviceType.mobileLarge => 10,
        PostsDeviceType.tablet => 14,
        PostsDeviceType.desktop => 24,
      };

  bool get useCompactTable => isMobile;

  double get cardPadding => switch (deviceType) {
        PostsDeviceType.mobileSmall => 12,
        PostsDeviceType.mobileLarge => 14,
        PostsDeviceType.tablet => 16,
        PostsDeviceType.desktop => 20,
      };

  ScrollPhysics get listScrollPhysics =>
      isMobile ? const BouncingScrollPhysics() : const ClampingScrollPhysics();

  double get sectionGap => switch (deviceType) {
        PostsDeviceType.mobileSmall => 4,
        PostsDeviceType.mobileLarge => 5,
        PostsDeviceType.tablet => 6,
        PostsDeviceType.desktop => 10,
      };

  double get filterGap => switch (deviceType) {
        PostsDeviceType.mobileSmall => 3,
        PostsDeviceType.mobileLarge => 4,
        PostsDeviceType.tablet => 5,
        PostsDeviceType.desktop => 8,
      };

  double get filterControlHeight => switch (deviceType) {
        PostsDeviceType.mobileSmall => 38,
        PostsDeviceType.mobileLarge => 40,
        PostsDeviceType.tablet => 42,
        PostsDeviceType.desktop => 44,
      };

  double get headerPadding => switch (deviceType) {
        PostsDeviceType.mobileSmall => 8,
        PostsDeviceType.mobileLarge => 9,
        PostsDeviceType.tablet => 10,
        PostsDeviceType.desktop => 12,
      };

  double get categoryStripHeight => switch (deviceType) {
        PostsDeviceType.mobileSmall => 30,
        PostsDeviceType.mobileLarge => 32,
        PostsDeviceType.tablet => 34,
        PostsDeviceType.desktop => 36,
      };

  double get storyBubbleSize => switch (deviceType) {
        PostsDeviceType.mobileSmall => 56,
        PostsDeviceType.mobileLarge => 64,
        PostsDeviceType.tablet => 72,
        PostsDeviceType.desktop => 84,
      };

  double get storyStripVerticalPadding => switch (deviceType) {
        PostsDeviceType.mobileSmall => 6,
        PostsDeviceType.mobileLarge => 8,
        PostsDeviceType.tablet => 10,
        PostsDeviceType.desktop => 12,
      };
}

/// Thumbnail height scaled to card column width.
double postCardThumbnailHeight(double cardWidth) {
  if (cardWidth < 180) return 112;
  if (cardWidth < 240) return 128;
  if (cardWidth < 320) return 148;
  if (cardWidth < 400) return 162;
  return 176;
}
