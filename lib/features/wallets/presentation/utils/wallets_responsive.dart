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
        WalletsDeviceType.mobileSmall => 8,
        WalletsDeviceType.mobileLarge => 10,
        WalletsDeviceType.tablet => 12,
        WalletsDeviceType.desktop => 14,
      };

  double get statsMinTileWidth => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 132,
        WalletsDeviceType.mobileLarge => 148,
        WalletsDeviceType.tablet => 168,
        WalletsDeviceType.desktop => 184,
      };

  double get statsGridSpacing => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 6,
        WalletsDeviceType.mobileLarge => 8,
        WalletsDeviceType.tablet => 10,
        WalletsDeviceType.desktop => 12,
      };

  double get dashboardCardRadius => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 12,
        WalletsDeviceType.mobileLarge => 12,
        WalletsDeviceType.tablet => 14,
        WalletsDeviceType.desktop => 14,
      };

  double get analyticsCardPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 8,
        WalletsDeviceType.mobileLarge => 9,
        WalletsDeviceType.tablet => 10,
        WalletsDeviceType.desktop => 12,
      };

  double get analyticsIconBoxSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 28,
        WalletsDeviceType.mobileLarge => 30,
        WalletsDeviceType.tablet => 32,
        WalletsDeviceType.desktop => 34,
      };

  double get analyticsIconSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 15,
        WalletsDeviceType.mobileLarge => 16,
        WalletsDeviceType.tablet => 17,
        WalletsDeviceType.desktop => 18,
      };

  double get analyticsLabelFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 10.5,
        WalletsDeviceType.mobileLarge => 11,
        WalletsDeviceType.tablet => 11.5,
        WalletsDeviceType.desktop => 12,
      };

  double get analyticsValueFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 13.5,
        WalletsDeviceType.mobileLarge => 14.5,
        WalletsDeviceType.tablet => 15.5,
        WalletsDeviceType.desktop => 16.5,
      };

  double get compactCardPadding => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 8,
        WalletsDeviceType.mobileLarge => 9,
        WalletsDeviceType.tablet => 10,
        WalletsDeviceType.desktop => 11,
      };

  double get compactCardTitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 12,
        WalletsDeviceType.mobileLarge => 12.5,
        WalletsDeviceType.tablet => 13,
        WalletsDeviceType.desktop => 13.5,
      };

  double get compactCardValueFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 12.5,
        WalletsDeviceType.mobileLarge => 13,
        WalletsDeviceType.tablet => 13.5,
        WalletsDeviceType.desktop => 14,
      };

  double get compactCardRadius => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 10,
        WalletsDeviceType.mobileLarge => 11,
        WalletsDeviceType.tablet => 12,
        WalletsDeviceType.desktop => 12,
      };

  double get sectionTitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 14,
        WalletsDeviceType.mobileLarge => 14.5,
        WalletsDeviceType.tablet => 15,
        WalletsDeviceType.desktop => 16,
      };

  double get sectionSubtitleFontSize => switch (deviceType) {
        WalletsDeviceType.mobileSmall => 11,
        WalletsDeviceType.mobileLarge => 11.5,
        WalletsDeviceType.tablet => 12,
        WalletsDeviceType.desktop => 12,
      };
}

WalletsLayoutMetrics walletsMetricsOf(BuildContext context) {
  return WalletsLayoutMetrics(
    getWalletsDeviceType(MediaQuery.sizeOf(context).width),
  );
}

bool walletsUseTopNav(double width) => width < 1100;
