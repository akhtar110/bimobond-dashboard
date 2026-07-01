import 'package:flutter/material.dart';

/// Breakpoints and layout tokens for the users screen.
enum DeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

DeviceType getDeviceType(double width) {
  if (width < 480) return DeviceType.mobileSmall;
  if (width < 700) return DeviceType.mobileLarge;
  if (width < 1200) return DeviceType.tablet;
  return DeviceType.desktop;
}

/// Memoized responsive layout values for [UsersPage] and its children.
class UsersLayoutMetrics {
  const UsersLayoutMetrics(this.deviceType);

  final DeviceType deviceType;

  bool get isMobile =>
      deviceType == DeviceType.mobileSmall ||
      deviceType == DeviceType.mobileLarge;

  bool get useCardList => isMobile;

  bool get useCompactTable => useCardList;

  bool get useInfiniteScroll => deviceType != DeviceType.desktop;

  bool get useDesktopPagination => deviceType == DeviceType.desktop;

  double get cardPadding => switch (deviceType) {
        DeviceType.mobileSmall => 12,
        DeviceType.mobileLarge => 14,
        DeviceType.tablet => 16,
        DeviceType.desktop => 20,
      };

  double get pageHorizontalPadding => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 10,
        DeviceType.tablet => 14,
        DeviceType.desktop => 24,
      };

  double get pageTopPadding => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 10,
        DeviceType.tablet => 12,
        DeviceType.desktop => 12,
      };

  double get pageBottomPadding => switch (deviceType) {
        DeviceType.mobileSmall => 12,
        DeviceType.mobileLarge => 14,
        DeviceType.tablet => 16,
        DeviceType.desktop => 16,
      };

  double get sectionSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 10,
        DeviceType.mobileLarge => 12,
        DeviceType.tablet => 14,
        DeviceType.desktop => 16,
      };

  double get filterSectionPadding => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 10,
        DeviceType.tablet => 11,
        DeviceType.desktop => 12,
      };

  double get searchFilterGap => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 10,
        DeviceType.tablet => 12,
        DeviceType.desktop => 0,
      };

  bool get searchFiltersInRow => deviceType == DeviceType.desktop;

  double get headerIconSize => switch (deviceType) {
        DeviceType.mobileSmall => 20,
        DeviceType.mobileLarge => 22,
        DeviceType.tablet => 24,
        DeviceType.desktop => 26,
      };

  double get headerIconPadding => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 9,
        DeviceType.tablet => 10,
        DeviceType.desktop => 12,
      };

  double get headerTitleGap => switch (deviceType) {
        DeviceType.mobileSmall => 10,
        DeviceType.mobileLarge => 12,
        DeviceType.tablet => 14,
        DeviceType.desktop => 16,
      };

  double get searchFieldHeight => switch (deviceType) {
        DeviceType.mobileSmall => 44,
        DeviceType.mobileLarge => 46,
        DeviceType.tablet => 48,
        DeviceType.desktop => 52,
      };

  double get chipVerticalPadding => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 7,
        DeviceType.tablet => 8,
        DeviceType.desktop => 10,
      };

  double get chipHorizontalPadding => switch (deviceType) {
        DeviceType.mobileSmall => 12,
        DeviceType.mobileLarge => 14,
        DeviceType.tablet => 16,
        DeviceType.desktop => 18,
      };

  double get chipSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 8,
        DeviceType.tablet => 8,
        DeviceType.desktop => 10,
      };

  bool get compactSelectionBar => deviceType != DeviceType.desktop;

  ScrollPhysics get listScrollPhysics => switch (deviceType) {
        DeviceType.mobileSmall || DeviceType.mobileLarge => const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        DeviceType.tablet => const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        DeviceType.desktop => const ClampingScrollPhysics(),
      };
}
