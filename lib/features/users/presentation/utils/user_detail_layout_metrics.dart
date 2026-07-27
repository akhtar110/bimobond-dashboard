import 'package:flutter/widgets.dart';

import 'responsive.dart';

/// Responsive layout tokens for [UserDetailScreen] and related widgets.
class UserDetailLayoutMetrics {
  const UserDetailLayoutMetrics(this.deviceType);

  final DeviceType deviceType;

  bool get isMobile =>
      deviceType == DeviceType.mobileSmall ||
      deviceType == DeviceType.mobileLarge;

  bool get isTablet => deviceType == DeviceType.tablet;

  bool get isDesktop => deviceType == DeviceType.desktop;

  int get actionsGridColumns => switch (deviceType) {
        DeviceType.mobileSmall => 2,
        DeviceType.mobileLarge => 2,
        DeviceType.tablet => 3,
        DeviceType.desktop => 4,
      };

  double get pagePadding => switch (deviceType) {
        DeviceType.mobileSmall => 10,
        DeviceType.mobileLarge => 12,
        DeviceType.tablet => 14,
        DeviceType.desktop => 16,
      };

  double get sectionPadding => switch (deviceType) {
        DeviceType.mobileSmall => 12,
        DeviceType.mobileLarge => 14,
        DeviceType.tablet => 16,
        DeviceType.desktop => 16,
      };

  double get sectionSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 8,
        DeviceType.tablet => 10,
        DeviceType.desktop => 10,
      };

  double get gridSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 2,
        DeviceType.mobileLarge => 2,
        DeviceType.tablet => 3,
        DeviceType.desktop => 3,
      };

  /// Gap between followers / following / posts / balance cards only.
  /// Keep tight so cards cluster; do not stretch them across the row.
  double get statsGap => switch (deviceType) {
        DeviceType.mobileSmall => 4,
        DeviceType.mobileLarge => 4,
        DeviceType.tablet => 6,
        DeviceType.desktop => 6,
      };

  EdgeInsets get statsCardPadding => switch (deviceType) {
        DeviceType.mobileSmall =>
          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        DeviceType.mobileLarge =>
          const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        DeviceType.tablet =>
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        DeviceType.desktop =>
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      };

  double get headerRadius => switch (deviceType) {
        DeviceType.mobileSmall => 16,
        DeviceType.mobileLarge => 18,
        DeviceType.tablet => 20,
        DeviceType.desktop => 20,
      };

  double get avatarRadius => switch (deviceType) {
        DeviceType.mobileSmall => 28,
        DeviceType.mobileLarge => 32,
        DeviceType.tablet => 40,
        DeviceType.desktop => 44,
      };

  double get avatarIconSize => avatarRadius;

  double get verifiedBadgeSize => switch (deviceType) {
        DeviceType.mobileSmall => 10,
        DeviceType.mobileLarge => 11,
        DeviceType.tablet => 12,
        DeviceType.desktop => 13,
      };

  bool get headerStacked => isMobile;

  double get statsIconSize => switch (deviceType) {
        DeviceType.mobileSmall => 18,
        DeviceType.mobileLarge => 20,
        DeviceType.tablet => 22,
        DeviceType.desktop => 22,
      };

  double get statsIconPadding => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 7,
        DeviceType.tablet => 7,
        DeviceType.desktop => 8,
      };

  /// Stats use a 2-column grid below this width; wider screens wrap in a row.
  bool get statsUseGrid =>
      deviceType == DeviceType.mobileSmall ||
      deviceType == DeviceType.mobileLarge;

  double get activityTabHeight => switch (deviceType) {
        DeviceType.mobileSmall => 620,
        DeviceType.mobileLarge => 700,
        DeviceType.tablet => 800,
        DeviceType.desktop => 860,
      };

  /// Prefer filling remaining viewport so posts get more room after a compact
  /// header, while keeping a sensible floor/ceiling.
  double activityContentHeight(double viewportHeight) {
    final reservedChrome = switch (deviceType) {
      DeviceType.mobileSmall => 220.0,
      DeviceType.mobileLarge => 230.0,
      DeviceType.tablet => 200.0,
      DeviceType.desktop => 180.0,
    };
    final available = viewportHeight - reservedChrome;
    final floor = activityTabHeight * 0.9;
    final ceiling = switch (deviceType) {
      DeviceType.mobileSmall => 820.0,
      DeviceType.mobileLarge => 900.0,
      DeviceType.tablet => 1000.0,
      DeviceType.desktop => 1100.0,
    };
    return available.clamp(floor, ceiling);
  }

  double get actionCardMinHeight => switch (deviceType) {
        DeviceType.mobileSmall => 88,
        DeviceType.mobileLarge => 92,
        DeviceType.tablet => 96,
        DeviceType.desktop => 100,
      };

  double get actionIconSize => switch (deviceType) {
        DeviceType.mobileSmall => 20,
        DeviceType.mobileLarge => 22,
        DeviceType.tablet => 22,
        DeviceType.desktop => 24,
      };

  double get actionIconPadding => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 9,
        DeviceType.tablet => 10,
        DeviceType.desktop => 10,
      };
}

UserDetailLayoutMetrics userDetailLayoutMetrics(double width) {
  return UserDetailLayoutMetrics(getDeviceType(width));
}
