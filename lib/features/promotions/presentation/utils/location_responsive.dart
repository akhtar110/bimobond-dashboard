import 'package:flutter/material.dart';

enum LocationDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

LocationDeviceType getLocationDeviceType(double width) {
  if (width < 480) return LocationDeviceType.mobileSmall;
  if (width < 700) return LocationDeviceType.mobileLarge;
  if (width < 1200) return LocationDeviceType.tablet;
  return LocationDeviceType.desktop;
}

/// Responsive layout tokens for location intelligence screens.
class LocationLayoutMetrics {
  const LocationLayoutMetrics(this.deviceType);

  final LocationDeviceType deviceType;

  bool get isMobile =>
      deviceType == LocationDeviceType.mobileSmall ||
      deviceType == LocationDeviceType.mobileLarge;

  bool get useInfiniteScroll => deviceType != LocationDeviceType.desktop;

  bool get useDesktopPagination => deviceType == LocationDeviceType.desktop;

  bool get useCompactTable => isMobile;

  double get pageHorizontalPadding => switch (deviceType) {
        LocationDeviceType.mobileSmall => 8,
        LocationDeviceType.mobileLarge => 10,
        LocationDeviceType.tablet => 14,
        LocationDeviceType.desktop => 24,
      };

  double get pageTopPadding => switch (deviceType) {
        LocationDeviceType.mobileSmall => 6,
        LocationDeviceType.mobileLarge => 6,
        LocationDeviceType.tablet => 8,
        LocationDeviceType.desktop => 8,
      };

  double get pageBottomPadding => switch (deviceType) {
        LocationDeviceType.mobileSmall => 10,
        LocationDeviceType.mobileLarge => 10,
        LocationDeviceType.tablet => 12,
        LocationDeviceType.desktop => 12,
      };

  double get sectionGap => switch (deviceType) {
        LocationDeviceType.mobileSmall => 6,
        LocationDeviceType.mobileLarge => 6,
        LocationDeviceType.tablet => 8,
        LocationDeviceType.desktop => 8,
      };

  /// Tighter vertical rhythm between header, toolbar, and content.
  double get toolbarSectionGap => switch (deviceType) {
        LocationDeviceType.mobileSmall => 4,
        LocationDeviceType.mobileLarge => 4,
        LocationDeviceType.tablet => 6,
        LocationDeviceType.desktop => 6,
      };

  double get filterGap => switch (deviceType) {
        LocationDeviceType.mobileSmall => 4,
        LocationDeviceType.mobileLarge => 5,
        LocationDeviceType.tablet => 6,
        LocationDeviceType.desktop => 8,
      };

  /// Even tighter gaps inside the filter toolbar row/column.
  double get toolbarFilterGap => switch (deviceType) {
        LocationDeviceType.mobileSmall => 4,
        LocationDeviceType.mobileLarge => 4,
        LocationDeviceType.tablet => 6,
        LocationDeviceType.desktop => 8,
      };

  double get toolbarControlHeight => switch (deviceType) {
        LocationDeviceType.mobileSmall => 36,
        LocationDeviceType.mobileLarge => 36,
        LocationDeviceType.tablet => 38,
        LocationDeviceType.desktop => 40,
      };

  /// Dense controls used by the admin user-locations top bar.
  double get compactToolbarControlHeight => switch (deviceType) {
        LocationDeviceType.mobileSmall => 36,
        LocationDeviceType.mobileLarge => 36,
        LocationDeviceType.tablet => 38,
        LocationDeviceType.desktop => 40,
      };

  double get cardPadding => switch (deviceType) {
        LocationDeviceType.mobileSmall => 8,
        LocationDeviceType.mobileLarge => 10,
        LocationDeviceType.tablet => 12,
        LocationDeviceType.desktop => 16,
      };

  double get mapHeightFraction => switch (deviceType) {
        LocationDeviceType.mobileSmall => 0.26,
        LocationDeviceType.mobileLarge => 0.28,
        LocationDeviceType.tablet => 0.30,
        LocationDeviceType.desktop => 0.0,
      };

  double get mapMinHeight => switch (deviceType) {
        LocationDeviceType.mobileSmall => 160,
        LocationDeviceType.mobileLarge => 180,
        LocationDeviceType.tablet => 200,
        LocationDeviceType.desktop => 0,
      };

  double get mapMaxHeight => switch (deviceType) {
        LocationDeviceType.mobileSmall => 260,
        LocationDeviceType.mobileLarge => 280,
        LocationDeviceType.tablet => 320,
        LocationDeviceType.desktop => 0,
      };

  bool get stackMapBelowTable => deviceType != LocationDeviceType.desktop;

  double get tableMapGap => switch (deviceType) {
        LocationDeviceType.mobileSmall => 8,
        LocationDeviceType.mobileLarge => 10,
        LocationDeviceType.tablet => 12,
        LocationDeviceType.desktop => 16,
      };

  ScrollPhysics get listScrollPhysics => switch (deviceType) {
        LocationDeviceType.mobileSmall ||
        LocationDeviceType.mobileLarge =>
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        LocationDeviceType.tablet => const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        LocationDeviceType.desktop => const ClampingScrollPhysics(),
      };
}
