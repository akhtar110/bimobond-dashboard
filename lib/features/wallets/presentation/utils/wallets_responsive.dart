import 'package:flutter/material.dart';

enum WalletsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

WalletsDeviceType getWalletsDeviceType(double width) {
  if (width < 480) return WalletsDeviceType.mobileSmall;
  if (width < 700) return WalletsDeviceType.mobileLarge;
  if (width < 1200) return WalletsDeviceType.tablet;
  return WalletsDeviceType.desktop;
}

class WalletsLayoutMetrics {
  const WalletsLayoutMetrics(this.deviceType);

  final WalletsDeviceType deviceType;

  bool get isMobile =>
      deviceType == WalletsDeviceType.mobileSmall ||
      deviceType == WalletsDeviceType.mobileLarge;

  bool get useDesktopPagination => deviceType == WalletsDeviceType.desktop;

  double get pageHorizontalPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 8,
        WalletsDeviceType.mobileLarge => 10,
        WalletsDeviceType.tablet => 14,
        WalletsDeviceType.desktop => 24,
      };

  double get pageTopPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 8,
        WalletsDeviceType.mobileLarge => 10,
        WalletsDeviceType.tablet => 16,
        WalletsDeviceType.desktop => 24,
      };

  double get pageBottomPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 12,
        WalletsDeviceType.mobileLarge => 16,
        WalletsDeviceType.tablet => 24,
        WalletsDeviceType.desktop => 32,
      };

  double get sectionGap => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 4,
        WalletsDeviceType.mobileLarge => 6,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 12,
      };

  double get toolbarFilterGap => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 3,
        WalletsDeviceType.mobileLarge => 4,
        WalletsDeviceType.tablet => 5,
        WalletsDeviceType.desktop => 8,
      };

  double get filterControlHeight => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 36,
        WalletsDeviceType.mobileLarge => 38,
        WalletsDeviceType.tablet => 40,
        WalletsDeviceType.desktop => 40,
      };

  double get filterGap => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 6,
        WalletsDeviceType.mobileLarge => 8,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 10,
      };

  bool get useCompactTable => isMobile;

  double get cardPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 12,
        WalletsDeviceType.mobileLarge => 14,
        WalletsDeviceType.tablet => 16,
        WalletsDeviceType.desktop => 20,
      };
}

WalletsLayoutMetrics walletsMetricsOf(BuildContext context) {
  return WalletsLayoutMetrics(
    getWalletsDeviceType(MediaQuery.sizeOf(context).width),
  );
}

bool walletsUseTopNav(double width) => width < 1100;
