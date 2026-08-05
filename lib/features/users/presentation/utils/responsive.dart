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
        DeviceType.mobileSmall => 4,
        DeviceType.mobileLarge => 4,
        DeviceType.tablet => 4,
        DeviceType.desktop => 4,
      };

  double get pageBottomPadding => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 6,
        DeviceType.tablet => 8,
        DeviceType.desktop => 8,
      };

  double get sectionSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 4,
        DeviceType.mobileLarge => 4,
        DeviceType.tablet => 4,
        DeviceType.desktop => 4,
      };

  double get filterSectionPadding => switch (deviceType) {
        DeviceType.mobileSmall => 0,
        DeviceType.mobileLarge => 0,
        DeviceType.tablet => 0,
        DeviceType.desktop => 0,
      };

  double get searchFilterGap => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 6,
        DeviceType.tablet => 8,
        DeviceType.desktop => 8,
      };

  /// Search + filter chips stay on one horizontal row at all breakpoints.
  bool get searchFiltersInRow => true;

  double get headerIconSize => switch (deviceType) {
        DeviceType.mobileSmall => 18,
        DeviceType.mobileLarge => 18,
        DeviceType.tablet => 20,
        DeviceType.desktop => 20,
      };

  double get headerIconPadding => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 6,
        DeviceType.tablet => 8,
        DeviceType.desktop => 8,
      };

  double get headerTitleGap => switch (deviceType) {
        DeviceType.mobileSmall => 8,
        DeviceType.mobileLarge => 8,
        DeviceType.tablet => 10,
        DeviceType.desktop => 12,
      };

  double get searchFieldHeight => switch (deviceType) {
        DeviceType.mobileSmall => 36,
        DeviceType.mobileLarge => 36,
        DeviceType.tablet => 38,
        DeviceType.desktop => 40,
      };

  double get chipVerticalPadding => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 6,
        DeviceType.tablet => 7,
        DeviceType.desktop => 8,
      };

  double get chipHorizontalPadding => switch (deviceType) {
        DeviceType.mobileSmall => 10,
        DeviceType.mobileLarge => 10,
        DeviceType.tablet => 12,
        DeviceType.desktop => 14,
      };

  double get chipSpacing => switch (deviceType) {
        DeviceType.mobileSmall => 6,
        DeviceType.mobileLarge => 6,
        DeviceType.tablet => 8,
        DeviceType.desktop => 8,
      };

  static const double toolbarInlineBreakpoint = 640;

  double get filterGap => chipSpacing;

  double get filterControlHeight => switch (deviceType) {
        DeviceType.mobileSmall => 32,
        DeviceType.mobileLarge => 34,
        DeviceType.tablet => 36,
        DeviceType.desktop => 36,
      };

  double get searchMaxWidth => switch (deviceType) {
        DeviceType.mobileSmall => 200,
        DeviceType.mobileLarge => 220,
        DeviceType.tablet => 240,
        DeviceType.desktop => 260,
      };

  bool toolbarInlineAt(double width) => width >= toolbarInlineBreakpoint;

  double inlineSearchWidthFor(double availableWidth) {
    if (availableWidth.isNaN || availableWidth.isInfinite || availableWidth <= 0) {
      return searchMaxWidth;
    }
    final actionsWidth = (filterControlHeight * 2) + (filterGap + 2) * 2 + 16;
    final rawMax = availableWidth - actionsWidth;
    if (rawMax.isNaN || rawMax.isInfinite) return searchMaxWidth;
    final maxSearch = rawMax.clamp(120.0, 420.0);
    if (availableWidth < toolbarInlineBreakpoint) {
      return availableWidth;
    }
    return maxSearch.clamp(searchMaxWidth * 0.85, searchMaxWidth * 1.35);
  }

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
