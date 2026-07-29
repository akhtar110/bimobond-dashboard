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
        WalletsDeviceType.desktop => 20,
      };

  double get pageTopPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 6,
        WalletsDeviceType.mobileLarge => 6,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 8,
      };

  double get pageBottomPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 10,
        WalletsDeviceType.mobileLarge => 10,
        WalletsDeviceType.tablet => 12,
        WalletsDeviceType.desktop => 12,
      };

  double get sectionGap => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 6,
        WalletsDeviceType.mobileLarge => 6,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 8,
      };

  double get toolbarFilterGap => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 3,
        WalletsDeviceType.mobileLarge => 4,
        WalletsDeviceType.tablet => 5,
        WalletsDeviceType.desktop => 6,
      };

  double get filterControlHeight => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 36,
        WalletsDeviceType.mobileLarge => 36,
        WalletsDeviceType.tablet => 38,
        WalletsDeviceType.desktop => 40,
      };

  double get filterGap => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 6,
        WalletsDeviceType.mobileLarge => 6,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 8,
      };

  bool get useCompactTable => isMobile;

  double get cardPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 8,
        WalletsDeviceType.mobileLarge => 9,
        WalletsDeviceType.tablet => 10,
        WalletsDeviceType.desktop => 12,
      };

  /// Narrower tiles → more columns → less vertical KPI stack height.
  double get statsMinTileWidth => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 118,
        WalletsDeviceType.mobileLarge => 128,
        WalletsDeviceType.tablet => 140,
        WalletsDeviceType.desktop => 152,
      };

  double get statsGridSpacing => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 6,
        WalletsDeviceType.mobileLarge => 6,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 8,
      };

  double get dashboardCardRadius => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 10,
        WalletsDeviceType.mobileLarge => 11,
        WalletsDeviceType.tablet => 12,
        WalletsDeviceType.desktop => 12,
      };

  double get analyticsCardPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 7,
        WalletsDeviceType.mobileLarge => 8,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 9,
      };

  double get analyticsIconBoxSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 26,
        WalletsDeviceType.mobileLarge => 28,
        WalletsDeviceType.tablet => 28,
        WalletsDeviceType.desktop => 30,
      };

  double get analyticsIconSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 14,
        WalletsDeviceType.mobileLarge => 15,
        WalletsDeviceType.tablet => 15,
        WalletsDeviceType.desktop => 16,
      };

  double get analyticsLabelFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 10,
        WalletsDeviceType.mobileLarge => 10.5,
        WalletsDeviceType.tablet => 11,
        WalletsDeviceType.desktop => 11,
      };

  double get analyticsValueFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 13,
        WalletsDeviceType.mobileLarge => 13.5,
        WalletsDeviceType.tablet => 14.5,
        WalletsDeviceType.desktop => 15,
      };

  double get compactCardPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 7,
        WalletsDeviceType.mobileLarge => 8,
        WalletsDeviceType.tablet => 8,
        WalletsDeviceType.desktop => 9,
      };

  double get compactCardTitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 11.5,
        WalletsDeviceType.mobileLarge => 12,
        WalletsDeviceType.tablet => 12.5,
        WalletsDeviceType.desktop => 13,
      };

  double get compactCardValueFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 12,
        WalletsDeviceType.mobileLarge => 12.5,
        WalletsDeviceType.tablet => 13,
        WalletsDeviceType.desktop => 13.5,
      };

  double get compactCardRadius => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 9,
        WalletsDeviceType.mobileLarge => 10,
        WalletsDeviceType.tablet => 10,
        WalletsDeviceType.desktop => 11,
      };

  double get sectionTitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 13.5,
        WalletsDeviceType.mobileLarge => 14,
        WalletsDeviceType.tablet => 14.5,
        WalletsDeviceType.desktop => 15,
      };

  double get sectionSubtitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 10.5,
        WalletsDeviceType.mobileLarge => 11,
        WalletsDeviceType.tablet => 11.5,
        WalletsDeviceType.desktop => 11.5,
      };

  double get headerTitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 18,
        WalletsDeviceType.mobileLarge => 19,
        WalletsDeviceType.tablet => 20,
        WalletsDeviceType.desktop => 22,
      };
}

WalletsLayoutMetrics walletsMetricsOf(BuildContext context) {
  return WalletsLayoutMetrics(
    getWalletsDeviceType(MediaQuery.sizeOf(context).width),
  );
}

bool walletsUseTopNav(double width) => width < 1100;
