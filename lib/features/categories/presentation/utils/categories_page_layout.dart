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

  bool get isMobile =>
      deviceType == CategoriesDeviceType.mobileSmall ||
      deviceType == CategoriesDeviceType.mobileLarge;

  /// Desktop uses numbered pages; mobile/tablet keep infinite scroll.
  bool get useDesktopPagination => deviceType == CategoriesDeviceType.desktop;

  bool get useInfiniteScroll => !useDesktopPagination;
}

CategoriesLayoutMetrics categoriesMetricsOf(BuildContext context) {
  return CategoriesLayoutMetrics(
    getCategoriesDeviceType(MediaQuery.sizeOf(context).width),
  );
}
