import 'package:flutter/material.dart';

double categoriesPageHorizontalPadding(double width) {
  if (width >= 1600) return 32;
  if (width >= 768) return 24;
  return 16;
}

/// Breakpoints aligned with posts/users for pagination mode.
enum CategoriesDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

CategoriesDeviceType getCategoriesDeviceType(double width) {
  if (width < 480) return CategoriesDeviceType.mobileSmall;
  if (width < 700) return CategoriesDeviceType.mobileLarge;
  // Match dashboard shell: permanent sidebar / desktop chrome around 1000+.
  if (width < 1000) return CategoriesDeviceType.tablet;
  return CategoriesDeviceType.desktop;
}

class CategoriesLayoutMetrics {
  const CategoriesLayoutMetrics(this.deviceType);

  final CategoriesDeviceType deviceType;

  static const double maxContentWidth = 1680;
  static const double toolbarInlineBreakpoint = 640;

  bool get isMobile =>
      deviceType == CategoriesDeviceType.mobileSmall ||
      deviceType == CategoriesDeviceType.mobileLarge;

  bool get isCompact => isMobile;

  /// Desktop uses numbered pages; mobile/tablet keep infinite scroll.
  bool get useDesktopPagination => deviceType == CategoriesDeviceType.desktop;

  bool get useInfiniteScroll => !useDesktopPagination;

  double get filterGap => switch (deviceType) {
        CategoriesDeviceType.mobileSmall => 6,
        CategoriesDeviceType.mobileLarge => 8,
        CategoriesDeviceType.tablet => 8,
        CategoriesDeviceType.desktop => 10,
      };

  double get filterControlHeight => switch (deviceType) {
        CategoriesDeviceType.mobileSmall => 32,
        CategoriesDeviceType.mobileLarge => 34,
        CategoriesDeviceType.tablet => 36,
        CategoriesDeviceType.desktop => 36,
      };

  double get searchMaxWidth => switch (deviceType) {
        CategoriesDeviceType.mobileSmall => 200,
        CategoriesDeviceType.mobileLarge => 220,
        CategoriesDeviceType.tablet => 240,
        CategoriesDeviceType.desktop => 260,
      };

  bool toolbarInlineAt(double width) => width >= toolbarInlineBreakpoint;

  /// Side-by-side root list + subcategory panel at this width and above.
  static const double masterDetailBreakpoint = 640;

  bool useMasterDetailSplit(double width) => width >= masterDetailBreakpoint;

  double masterPanelWidth(double availableWidth) {
    if (availableWidth < 480) {
      return (availableWidth * 0.44).clamp(168.0, 210.0);
    }
    if (availableWidth < 720) {
      return (availableWidth * 0.4).clamp(240.0, 300.0);
    }
    if (availableWidth < 1000) {
      return (availableWidth * 0.36).clamp(280.0, 340.0);
    }
    return (availableWidth * 0.32).clamp(300.0, 380.0);
  }

  int masterDetailMasterFlex(double availableWidth) {
    if (availableWidth < 720) return 42;
    if (availableWidth < 1000) return 38;
    return 34;
  }

  int masterDetailDetailFlex(double availableWidth) =>
      100 - masterDetailMasterFlex(availableWidth);

  double inlineSearchWidthFor(double availableWidth) {
    final actionsWidth = (filterControlHeight * 2) + (filterGap + 2) * 2 + 16;
    final maxSearch = (availableWidth - actionsWidth).clamp(120.0, 420.0);
    if (availableWidth < toolbarInlineBreakpoint) {
      return availableWidth;
    }
    return maxSearch.clamp(searchMaxWidth * 0.85, searchMaxWidth * 1.35);
  }
}

/// Width-aware metrics for an individual list panel (master or detail).
class CategoriesPanelMetrics {
  const CategoriesPanelMetrics(this.width);

  final double width;

  bool get isNarrow => width < 360;
  bool get isCompact => width < 420;
  bool get isMedium => width < 560;

  double get listHorizontalPadding =>
      width < 280 ? 6 : width < 400 ? 8 : width < 720 ? 10 : 12;

  double get listTopPadding => width < 360 ? 8 : 12;
  double get tileSpacing => width < 320 ? 6 : 8;

  bool get rootTileUltraCompact => width < 248;
  bool get rootTileCompact => width < 320;

  double get rootIconSize =>
      rootTileUltraCompact ? 28 : rootTileCompact ? 32 : 36;

  bool get rootShowInlineEdit => !rootTileCompact;
  bool get rootShowCountBadge => !rootTileUltraCompact;
  bool get rootShowStatusBadge => !rootTileUltraCompact;

  bool get useSubcategoryCards => width < 400;
  bool get showSubcategoryTableHeader => !useSubcategoryCards;

  bool get subcategoryShowUpdated => width >= 360;
  bool get subcategoryShowChildren => width >= 460;
  bool get subcategoryShowParent => width >= 560;

  double get subcategoryActionsWidth => width < 320 ? 40 : width < 480 ? 56 : 96;
}

CategoriesLayoutMetrics categoriesMetricsOf(BuildContext context) {
  return CategoriesLayoutMetrics(
    getCategoriesDeviceType(MediaQuery.sizeOf(context).width),
  );
}
