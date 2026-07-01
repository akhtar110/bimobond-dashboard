import 'package:flutter/material.dart';

// Breakpoints and layout helpers for promotions admin screens.
enum PromotionsDeviceType {
  mobileSmall,
  mobileLarge,
  tablet,
  desktop,
}

PromotionsDeviceType getPromotionsDeviceType(double width) {
  if (width < 480) return PromotionsDeviceType.mobileSmall;
  if (width < 700) return PromotionsDeviceType.mobileLarge;
  if (width < 1200) return PromotionsDeviceType.tablet;
  return PromotionsDeviceType.desktop;
}

class PromotionsLayoutMetrics {
  const PromotionsLayoutMetrics(this.deviceType);

  final PromotionsDeviceType deviceType;

  bool get isMobile =>
      deviceType == PromotionsDeviceType.mobileSmall ||
      deviceType == PromotionsDeviceType.mobileLarge;

  bool get useDesktopPagination =>
      deviceType == PromotionsDeviceType.desktop;

  bool get useInfiniteScroll => !useDesktopPagination;

  double get pageHorizontalPadding => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 8,
        PromotionsDeviceType.mobileLarge => 10,
        PromotionsDeviceType.tablet => 14,
        PromotionsDeviceType.desktop => 24,
      };

  double get pageTopPadding => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 8,
        PromotionsDeviceType.mobileLarge => 10,
        PromotionsDeviceType.tablet => 16,
        PromotionsDeviceType.desktop => 24,
      };

  double get pageBottomPadding => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 12,
        PromotionsDeviceType.mobileLarge => 16,
        PromotionsDeviceType.tablet => 24,
        PromotionsDeviceType.desktop => 32,
      };

  double get sectionGap => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 4,
        PromotionsDeviceType.mobileLarge => 6,
        PromotionsDeviceType.tablet => 8,
        PromotionsDeviceType.desktop => 12,
      };

  double get filterGap => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 4,
        PromotionsDeviceType.mobileLarge => 5,
        PromotionsDeviceType.tablet => 6,
        PromotionsDeviceType.desktop => 8,
      };

  double get toolbarFilterGap => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 3,
        PromotionsDeviceType.mobileLarge => 4,
        PromotionsDeviceType.tablet => 5,
        PromotionsDeviceType.desktop => 8,
      };

  double get filterControlHeight => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 36,
        PromotionsDeviceType.mobileLarge => 38,
        PromotionsDeviceType.tablet => 40,
        PromotionsDeviceType.desktop => 40,
      };

  double get cardPadding => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 12,
        PromotionsDeviceType.mobileLarge => 14,
        PromotionsDeviceType.tablet => 16,
        PromotionsDeviceType.desktop => 24,
      };

  double get cardRadius => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 14,
        PromotionsDeviceType.mobileLarge => 16,
        PromotionsDeviceType.tablet => 20,
        PromotionsDeviceType.desktop => 24,
      };

  double get metricCardPadding => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 10,
        PromotionsDeviceType.mobileLarge => 12,
        PromotionsDeviceType.tablet => 14,
        PromotionsDeviceType.desktop => 16,
      };

  double get metricIconSize => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 34,
        PromotionsDeviceType.mobileLarge => 38,
        PromotionsDeviceType.tablet => 42,
        PromotionsDeviceType.desktop => 42,
      };

  double get detailLabelWidth => switch (deviceType) {
        PromotionsDeviceType.mobileSmall => 96,
        PromotionsDeviceType.mobileLarge => 108,
        PromotionsDeviceType.tablet => 120,
        PromotionsDeviceType.desktop => 132,
      };
}

PromotionsLayoutMetrics promotionsMetricsOf(BuildContext context) {
  return PromotionsLayoutMetrics(
    getPromotionsDeviceType(MediaQuery.sizeOf(context).width),
  );
}

/// Side nav below this width; top nav at/above content for more data space.
bool promotionsUseTopNav(double width) => width < 900;

const double promotionsScrollLoadThreshold = 300;

bool promotionsShouldLoadMore(ScrollController controller) {
  if (!controller.hasClients) return false;
  final position = controller.position;
  return position.pixels >=
      position.maxScrollExtent - promotionsScrollLoadThreshold;
}
